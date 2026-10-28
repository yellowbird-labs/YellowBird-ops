
# ==============================================================================
# Dynamic Lookup for Wildcard ACM Certificate (*.amaanworks.me)
# ==============================================================================

data "aws_acm_certificate" "wildcard" {
  domain      = var.acm_certificate_domain
  statuses    = ["ISSUED"]
  most_recent = true
}

# ==============================================================================
# Application Load Balancer (Public Ingress)
# ==============================================================================

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

import {
  to = aws_lb.main
  id = "arn:aws:elasticloadbalancing:us-east-1:056126811138:loadbalancer/app/yellowbird-alb/6cb5f95421dcd696"
}

# ==============================================================================
# Target Group for Go API (Port 8080, Type: IP for Fargate)
# ==============================================================================

resource "aws_lb_target_group" "api" {
  name        = "${var.project_name}-api-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-api-tg"
  }
}

import {
  to = aws_lb_target_group.api
  id = "arn:aws:elasticloadbalancing:us-east-1:056126811138:targetgroup/yellowbird-api-tg/d9a273709a3e891c"
}

# ==============================================================================
# HTTP Listener (Port 80 -> 301 Permanent Redirect to HTTPS)
# ==============================================================================

resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

import {
  to = aws_lb_listener.http_redirect
  id = "arn:aws:elasticloadbalancing:us-east-1:056126811138:listener/app/yellowbird-alb/6cb5f95421dcd696/beca373252a4232c"
}

# ==============================================================================
# HTTPS Listener (Port 443 -> Terminate TLS & Forward to API Target Group)
# ==============================================================================

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
  certificate_arn   = data.aws_acm_certificate.wildcard.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

import {
  to = aws_lb_listener.https
  id = "arn:aws:elasticloadbalancing:us-east-1:056126811138:listener/app/yellowbird-alb/6cb5f95421dcd696/bff33d8695fb4887"
}