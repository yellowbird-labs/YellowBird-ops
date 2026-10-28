# ==============================================================================
# YellowBird Infrastructure Outputs
# ==============================================================================

output "alb_dns_name" {
  description = "The public DNS hostname of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "api_endpoint" {
  description = "The public HTTPS API URL"
  value       = "https://api.amaanworks.me"
}

output "vpc_id" {
  description = "The ID of the YellowBird Virtual Private Cloud"
  value       = aws_vpc.main.id
}

output "ecs_cluster_name" {
  description = "The name of the ECS Fargate cluster"
  value       = aws_ecs_cluster.main.name
}

output "media_bucket_name" {
  description = "The S3 bucket storing media uploads and HLS video chunks"
  value       = aws_s3_bucket.media.bucket
}

output "github_actions_role_arn" {
  description = "The ARN of the IAM Role assumed by GitHub Actions via OIDC"
  value       = aws_iam_role.github_actions.arn
}