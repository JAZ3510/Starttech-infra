output "cluster_name" {
  value = aws_eks_cluster.starttech-cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.starttech-cluster.endpoint
}

output "cluster_security_group_id" {
  description = "EKS-managed cluster security group, attached to managed node group instances"
  value       = aws_eks_cluster.starttech-cluster.vpc_config[0].cluster_security_group_id
}

output "lb_controller_role_arn" {
  value = aws_iam_role.lbc.arn
}
