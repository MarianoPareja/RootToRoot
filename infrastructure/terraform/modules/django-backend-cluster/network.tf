##### VPC #####

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "VPC_${var.environment}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = {
    Name = "InternetGateway_${var.environment}"
  }
}

##### SUBNETS #####

data "aws_availability_zones" "availables" {}

resource "aws_subnet" "public" {
  count             = var.az_count
  vpc_id            = aws_vpc.default.id
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index + var.az_count)
  availability_zone = data.aws_availability_zones.availables.names[count.index]

  tags = {
    Name = "PublicSubnet_${count.index}_${var.environment}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }

  tags = {
    Name = "PublicRouteTable_${var.environment}"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_main_route_table_association" "public_main" {
  vpc_id         = aws_vpc.default.id
  route_table_id = aws_route_table.public.id
}


resource "aws_eip" "nat_gateway" {
  count  = var.az_count
  domain = "vpc"

  tags = {
    Name = "EIP_${count.index}_${var.environment}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = var.az_count
  subnet_id     = aws_subnet.public[count.index].id
  allocation_id = aws_eip.nat_gateway[count.index].id

  tags = {
    Name = "NatGateway_${count.index}_${var.environment}"
  }
}

resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.default.id
  cidr_block        = cidrsubnet(aws_vpc.default.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.availables.names[count.index]

  tags = {
    Name = "PrivateSubnet_${count.index}_${var.environment}"
  }
}

resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    Name = "PrivateRouteTable_${count.index}_${var.environment}"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


##### SECURITY GROUPS #####


resource "aws_security_group" "alb" {
  name        = "ALB_SecurityGroup_${var.environment}"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name = "$ALB_SecurityGroup_${var.environment}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "default_allow_http" {
  description       = "Allow HTTP ingress traffic from internet"
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "default_egress_traffic" {
  description       = "Allow all egress traffic"
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}


resource "aws_security_group" "bastion_host" {
  name        = "SecurityGroup_BastionHost_${var.environment}"
  description = "Bastion host Security Group"
  vpc_id      = aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "bation_allow_ssh" {
  description       = "Allow SSH"
  security_group_id = aws_security_group.bastion_host.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"

}

resource "aws_vpc_security_group_egress_rule" "bastion_egress_traffic" {
  description       = "Allow all egress traffic"
  security_group_id = aws_security_group.bastion_host.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}


resource "aws_security_group" "ec2" {
  name        = "EC2_Instance_SecurityGroup_${var.environment}"
  description = "Security group for EC2 instances in ECS cluster"
  vpc_id      = aws_vpc.default.id

  tags = {
    Name = "EC2_Instance_SecurityGroup_${var.environment}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_http" {
  description                  = "Allow ingress traffic from ALB on HTTP on ephemeral ports"
  security_group_id            = aws_security_group.ec2.id
  from_port                    = 1024
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh_bation_host" {
  description                  = "Allow SSH ingress traffic from bastion host"
  security_group_id            = aws_security_group.ec2.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion_host.id
}

resource "aws_vpc_security_group_egress_rule" "ec2_egress_traffic" {
  description       = "Allow all egress traffic"
  security_group_id = aws_security_group.ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}


##### APPLICATION LOAD BALANCER #####


resource "aws_alb" "alb" {
  name            = "ALB-${var.environment}"
  security_groups = [aws_security_group.alb.id]
  subnets         = aws_subnet.public.*.id
}

# resource "aws_alb_listener" "alb_default_listener_http" {
#   load_balancer_arn = aws_alb.alb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_alb_target_group.service_target_group.arn
#   }
# }

resource "aws_alb_listener" "ecs_alb_https_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" # CHECK THIS LATER
  certificate_arn   = "UPDATE"
  depends_on        = [aws_alb_target_group.service_target_group]

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.service_target_group.arn
  }
}

resource "aws_lb_listener_rule" "http_listener_rule" {
  listener_arn = aws_alb_listener.alb_default_listener_http.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.service_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_alb_target_group" "service_target_group" {
  name                 = "TargetGroup-${var.environment}"
  port                 = "8000" #Port on which target recieves traffic
  protocol             = "HTTP"
  vpc_id               = aws_vpc.default.id
  deregistration_delay = 120

  health_check {
    healthy_threshold   = "2"
    unhealthy_threshold = "2"
    interval            = "60"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "30"
  }

  depends_on = [aws_alb.alb]
}
