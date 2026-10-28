# ==============================================================================
# CloudWatch Log Groups
# ==============================================================================

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${var.project_name}-api"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-api-logs"
  }
}

import {
  to = aws_cloudwatch_log_group.api
  id = "/ecs/yellowbird-api"
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.project_name}-worker"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-worker-logs"
  }
}

import {
  to = aws_cloudwatch_log_group.worker
  id = "/ecs/yellowbird-worker"
}

# ==============================================================================
# ECS Fargate Cluster
# ==============================================================================

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

import {
  to = aws_ecs_cluster.main
  id = "yellowbird-cluster"
}

# ==============================================================================
# 1. API Task Definition & Service (Public Facing)
# ==============================================================================

resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project_name}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-api-container"
      image     = "056126811138.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-api:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      environment = [
        { name = "PORT", value = "8080" },
        { name = "APP_ENV", value = var.environment },
        { name = "STORAGE_PROVIDER", value = "s3" },
        { name = "S3_BUCKET", value = var.media_bucket_name },
        { name = "S3_REGION", value = var.aws_region },
        { name = "REDIS_ADDR", value = var.redis_addr },
        { name = "REDIS_DB", value = "0" }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_ssm_parameter.database_url.arn
        },
        {
          name      = "REDIS_PASSWORD"
          valueFrom = aws_ssm_parameter.redis_password.arn
        },
        {
          name      = "JWT_SECRET"
          valueFrom = aws_ssm_parameter.jwt_secret.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.api.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "${var.project_name}-api-container"
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [aws_lb_listener.https]
}

import {
  to = aws_ecs_service.api
  id = "yellowbird-cluster/yellowbird-api-service"
}

# ==============================================================================
# 2. Worker Task Definition & Service (Background Processor)
# ==============================================================================

resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.project_name}-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.ecs_exec_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-worker-container"
      image     = "056126811138.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-worker:latest"
      essential = true

      environment = [
        { name = "APP_ENV", value = var.environment },
        { name = "STORAGE_PROVIDER", value = "s3" },
        { name = "S3_BUCKET", value = var.media_bucket_name },
        { name = "S3_REGION", value = var.aws_region },
        { name = "WORKER_CONCURRENCY", value = "4" },
        { name = "REDIS_ADDR", value = var.redis_addr },
        { name = "REDIS_DB", value = "0" }
      ]

      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = aws_ssm_parameter.database_url.arn
        },
        {
          name      = "REDIS_PASSWORD"
          valueFrom = aws_ssm_parameter.redis_password.arn
        },
        {
          name      = "JWT_SECRET"
          valueFrom = aws_ssm_parameter.jwt_secret.arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "worker" {
  name            = "${var.project_name}-worker-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

import {
  to = aws_ecs_service.worker
  id = "yellowbird-cluster/yellowbird-worker-service"
}