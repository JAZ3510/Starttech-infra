output "vpc_id" {
  value = module.networking.vpc_id
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "lb_controller_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller"
  value       = module.eks.lb_controller_role_arn
}

output "ecr_repository_url" {
  value = module.storage.ecr_repository_url
}

output "frontend_bucket_name" {
  value = module.storage.frontend_bucket_id
}

output "cloudfront_distribution_id" {
  value = module.cdn.distribution_id
}

output "cloudfront_domain_name" {
  value = module.cdn.distribution_domain_name
}

output "redis_endpoint" {
  description = "Use as REDIS_HOST for the backend"
  value       = module.database.redis_endpoint
}

output "grader_access_key_id" {
  value     = aws_iam_access_key.grader.id
  sensitive = true
}

output "grader_secret_access_key" {
  value     = aws_iam_access_key.grader.secret
  sensitive = true
}

output "grader_console_password" {
  value     = aws_iam_user_login_profile.grader.password
  sensitive = true
}
