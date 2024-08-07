## EC2 Launch Template 

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  owners = ["amazon"]
}

# AWS Launch Template

resource "aws_launch_template" "ecs_launch_template" {
  name                   = "EC2_LaunchTemplate_${var.environment}"
  image_id               = data.aws_ami.amazon_linux_2.image_id
  instance_type          = var.instance_type
  key_name               = "gunicorn-webserver"
  user_data              = filebase64("${path.module}/ecs.sh")
  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_role_profile.arn
  }

}

##### Elastic Container Service #####

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ECSCluster_${var.environment}"

  lifecycle {
    create_before_destroy = false
  }

  tags = {
    Name = "ECSCluster_${var.environment}"
  }
}

resource "aws_ecs_service" "service" {
  name            = "ECS_Service_${var.environment}"
  iam_role        = aws_iam_role.ecs_service_role.arn
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.django-website-task-definition.arn

  load_balancer {
    target_group_arn = aws_alb_target_group.service_target_group.arn
    container_name   = "gunicorn"
    container_port   = 8000
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_ecs_task_definition" "django-website-task-definition" {
  family             = "ECS_TaskDefinition_${var.environment}"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_iam_role.arn
  network_mode       = "bridge"

  container_definitions = jsonencode([
    {
      "name"       = "gunicorn",
      "image"      = "${var.ecr_url}:guinicorn-latest",
      "cpu"        = 256,
      "memory"     = 512,
      "essentials" = true,
      "portMappings" = [
        {
          containerPort = 8000,
          # No hostPort to allow dynamic port mapping
          protocol = "tcp"
        }
      ]
    },
    # {
    #   "name"       = "nginx",
    #   "image"      = "${var.ecr_url}/${var.ecr_name}:nginx-latest",
    #   "cpu"        = 100,
    #   "memory"     = 256,
    #   "essentials" = true,
    #   "portMappings" = [
    #     {
    #       containerPort = 80,
    #       # No hostPort to allow dynamic port mapping
    #       protocol = "tcp"
    #     }
    #   ]
    #   "depends_on" = "gunicorn",
    #   "links" = [
    #     "gunicorn"
    #   ]
    # },
  ])


}

resource "aws_ecs_cluster_capacity_providers" "cas" {
  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.cas.name]
}

resource "aws_ecs_capacity_provider" "cas" {
  name = "CapacityProviderECS_${var.environment}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_autoscaling_group.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 2
    }
  }
}

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  name                  = "ASG_${var.environment}"
  min_size              = 1
  max_size              = 1
  vpc_zone_identifier   = aws_subnet.private.*.id
  health_check_type     = "EC2"
  protect_from_scale_in = true


  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  lifecycle {
    create_before_destroy = false
  }
}

## Task Level target tracking

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "CPUTargetTrackingScaling_${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 90

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "ecs_memory_policy" {
  name               = "MemoryTargetTrackingScaling_${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 90

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}


##### BASTION HOST #####

resource "aws_instance" "bastion_host" {
  ami                         = data.aws_ami.amazon_linux_2.image_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  key_name                    = "gunicorn-webserver"
  vpc_security_group_ids      = [aws_security_group.bastion_host.id]

  tags = {
    Name = "EC2_BastionHost_${var.environment}"
  }
}
