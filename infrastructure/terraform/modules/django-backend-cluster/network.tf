# VPC 

resource "aws_vpc" "django-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Environment = "dev"
  }
}

# SUBNETS

resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.django-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.django-vpc.cidr_block, 8, 1)
  availability_zone = "sa-east-1a"
}

resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.django-vpc.id
  cidr_block        = cidrsubnet(aws_vpc.django-vpc.cidr_block, 8, 2)
  availability_zone = "sa-east-1b"
}

# INTERNET GATEWAY 

resource "aws_internet_gateway" "ig-1" {
  vpc_id = aws_vpc.django-vpc.id

  tags = {
    Environment = "dev"
  }
}

# ROUTE TABLES


# SECURITY GROUPS

resource "aws_security_group" "alb-django-website" {
  name        = "alb-djangowebsite-sg"
  description = "ALB Security Group"


  tags = {
    Environment = "dev"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-http" {
  security_group_id = aws_security_group.alb-django-website.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "TCP"
}

resource "aws_security_group" "ecs-django-instances-sg" {
  name        = "ecs-django-instances-sg"
  description = "ECS Django Instances Security Group"

  tags = {
    Environment = "dev"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow-alb-traffic" {
  security_group_id            = aws_security_group.ecs-django-instances-sg.id
  referenced_security_group_id = aws_vpc_security_group_ingress_rule.allow-http.id
  from_port                    = 32768
  to_port                      = 65535
  ip_protocol                  = "TCP"
}

# APPLICATION LOAD BALANCER

resource "aws_lb" "django-lb" {
  name               = "dev-django-website-lb"
  load_balancer_type = "application"
  internal           = false
  ip_address_type    = "ipv4"

  security_groups = [aws_security_group.alb-django-website]
  subnets         = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]
}

resource "aws_lb_target_group" "django-backend-tg" {
  name        = "dev-djangowebsite-lb-tg"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.django-vpc.id

  health_check {
    path              = "/"
    enabled           = true
    healthy_threshold = 3

  }
}

resource "aws_lb_listener" "django-backend-listener" {
  load_balancer_arn = aws_lb.django-lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.django-backend-tg.arn
  }
}
