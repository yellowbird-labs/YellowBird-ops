# ==============================================================================
# Variables Definition
# ==============================================================================

variable "aws_region" {
  description = "The AWS region where YellowBird infrastructure is deployed"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name (e.g. production, staging)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "The project name prefix used for resource naming"
  type        = string
  default     = "yellowbird"
}

# ------------------------------------------------------------------------------
# Networking
# ------------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "The CIDR block for the YellowBird VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of Availability Zones to deploy subnets into"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the two public subnets (Multi-AZ ALB requirement)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

# ------------------------------------------------------------------------------
# Storage & Ingress
# ------------------------------------------------------------------------------

variable "media_bucket_name" {
  description = "Name of the S3 bucket used for video uploads and transcoded chunks"
  type        = string
  default     = "yellowbird-media-amaan"
}

variable "acm_certificate_domain" {
  description = "The domain name of the existing AWS ACM wildcard certificate"
  type        = string
  default     = "*.amaanworks.me"
}

# ------------------------------------------------------------------------------
# Application Secrets (Encrypted & Masked)
# ------------------------------------------------------------------------------

variable "database_url" {
  description = "Neon Serverless PostgreSQL connection string"
  type        = string
  sensitive   = true
  default     = ""
}

variable "redis_addr" {
  description = "Upstash Redis TLS endpoint address"
  type        = string
  default     = "chief-aardvark-159591.upstash.io:6379"
}

variable "redis_password" {
  description = "Upstash Redis password for authentication"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jwt_secret" {
  description = "HMAC Secret key used for signing and validating JWT tokens"
  type        = string
  sensitive   = true
  default     = ""
}
