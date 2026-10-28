# ==============================================================================
# GitHub Actions OpenID Connect (OIDC) Identity Provider
# ==============================================================================

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["ab9d0263244dd0326eb67015705a667e79cfe998"]

  tags = {
    Name = "github-actions-oidc"
  }
}

import {
  to = aws_iam_openid_connect_provider.github
  id = "arn:aws:iam::056126811138:oidc-provider/token.actions.githubusercontent.com"
}

# ==============================================================================
# 1. ECS Task Execution Role (ECR Pull & SSM Secret Resolution)
# ==============================================================================

resource "aws_iam_role" "ecs_exec_role" {
  name = "${var.project_name}-ecs-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-exec-role"
  }
}

import {
  to = aws_iam_role.ecs_exec_role
  id = "yellowbird-ecs-exec-role"
}

# Attach standard AWS managed execution policy
resource "aws_iam_role_policy_attachment" "ecs_exec_standard" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Inline policy to allow reading secrets from SSM Parameter Store
resource "aws_iam_role_policy" "ecs_exec_ssm" {
  name = "${var.project_name}-ssm-secrets-policy"
  role = aws_iam_role.ecs_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:056126811138:parameter/${var.project_name}/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==============================================================================
# 2. ECS Task Role (Runtime S3 Access for Go Application)
# ==============================================================================

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

import {
  to = aws_iam_role.ecs_task_role
  id = "yellowbird-ecs-task-role"
}

# Attach S3 Access Policy
resource "aws_iam_role_policy_attachment" "ecs_task_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# ==============================================================================
# 3. GitHub Actions CI/CD Role (Passwordless OIDC Authentication)
# ==============================================================================

resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:dexisback/YellowBird:*",
              "repo:dexisback/yellowbird:*",
              "repo:dexisback@*/YellowBird@*:*",
              "repo:dexisback@*/yellowbird@*:*",
              "repo:dexisback@176792193/YellowBird@1305566499:*"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-github-actions-role"
  }
}

import {
  to = aws_iam_role.github_actions
  id = "yellowbird-github-actions-role"
}

# Allow pushing Docker images to Amazon ECR
resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Allow registering task definitions and updating ECS services
resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "${var.project_name}-ecs-deploy-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSManagement"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowIAMPassRoleToECS"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::056126811138:role/${var.project_name}-ecs-*"
      }
    ]
  })
}