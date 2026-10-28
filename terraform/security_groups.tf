
# ==============================================================================
# Application Load Balancer Security Group (Public Ingress)
# ==============================================================================

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Public ingress security group for YellowBird ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from anywhere (Redirects to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

import {
  to = aws_security_group.alb
  id = "sg-005ad286d9ff029c9"
}

# ==============================================================================
# ECS Tasks Security Group (Zero-Trust Ingress)
# ==============================================================================

resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "security group for yellowbird ecs fargate containers "
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow inbound API traffic exclusively from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound to internet (Neon DB, Upstash Redis, S3)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}

import {
  to = aws_security_group.ecs
  id = "sg-037ce66af7944457a"
}