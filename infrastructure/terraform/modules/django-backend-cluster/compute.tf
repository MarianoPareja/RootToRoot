# VARIABLES 
variable "ec2_security_group_id" {
  type = string
}

variable "ecs_subnets" {
  type = list(string)
}

variable "ecs_sg_subnets" {
  type = list(string)
}


# EC2 LAUNCH TEMPLATE

resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-template"
  image_id      = "ami-062c116e449466e7f"
  instance_type = "t2.micro"

  key_name               = ""
  vpc_security_group_ids = [ec2_security_group.id]
  iam_instance_profile {
    name = "ecsInstanceRole"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 10
      volume_type = "gp2"
    }
  }

  user_data = filebase64("${path.module}/ecs.sh")
}

# EC2 AUTOSCALING GROUP

resource "aws_autoscaling_group" "ecs_ag" {
  vpc_zone_identifier = var.ecs_sg_subnets
  desired_capacity    = 1
  min_size            = 1
  max_size            = 2

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$latest"
  }
}

# ECS CLUSTER

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "django-ecs-cluster"
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "ec2_capacity_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_ag.arn

    managed_scaling {
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 80
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs_cluster_provider" {
  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
  }

}

# ECS TASK DEFINITION

resource "aws_ecs_task_definition" "django-website-task-definition" {
  family             = "ecs-django-task"
  network_mode       = "awsvpc"
  execution_role_arn = "arn:aws:iam::532199187081:role/ecsTaskExecutionRole" # CHECK LATER

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsondecode([
    {
      "name"       = "django-website-backend",
      "image"      = "",
      "cpu"        = 256,
      "memory"     = 512,
      "essentials" = true,
      "portMapping" = [
        {
          containerPort = 0
          hostPort      = 8000
          protocol      = "TCP"
        }
      ]
    }
  ])

}

# ECS SERVICE

resource "aws_ecs_service" "ecs_django_service" {
  name            = "ecs-django-service"
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.django-website-task-definition.arn
  desired_count   = 2

  network_configuration {
    subnets         = var.ecs_subnets
    security_groups = var.ecs_sg_subnets
  }

  force_new_deployment = true
  placement_constraints {
    type = "distinctInstance"
  }

  triggers = {
    redeployment = timestamp()
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "dockergs"
    container_port   = 80
  }

  depends_on = [aws_autoscaling_group.ecs_ag]


}



