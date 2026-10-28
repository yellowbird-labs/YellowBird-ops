
# ==============================================================================
# AWS Systems Manager (SSM) Parameter Store - Encrypted Secrets
# ==============================================================================

resource "aws_ssm_parameter" "database_url" {
  name        = "/${var.project_name}/${var.environment}/database-url"
  description = "Neon Serverless PostgreSQL connection string"
  type        = "SecureString"
  value       = var.database_url != "" ? var.database_url : "managed_externally"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name = "${var.project_name}-database-url"
  }
}

import {
  to = aws_ssm_parameter.database_url
  id = "/yellowbird/production/database-url"
}

resource "aws_ssm_parameter" "redis_password" {
  name        = "/${var.project_name}/${var.environment}/redis-password"
  description = "Upstash Redis authentication password"
  type        = "SecureString"
  value       = var.redis_password != "" ? var.redis_password : "managed_externally"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name = "${var.project_name}-redis-password"
  }
}

import {
  to = aws_ssm_parameter.redis_password
  id = "/yellowbird/production/redis-password"
}

resource "aws_ssm_parameter" "jwt_secret" {
  name        = "/${var.project_name}/${var.environment}/jwt-secret"
  description = "HMAC secret key for signing API JWT tokens"
  type        = "SecureString"
  value       = var.jwt_secret != "" ? var.jwt_secret : "managed_externally"

  lifecycle {
    ignore_changes = [value]
  }

  tags = {
    Name = "${var.project_name}-jwt-secret"
  }
}

import {
  to = aws_ssm_parameter.jwt_secret
  id = "/yellowbird/production/jwt-secret"
}