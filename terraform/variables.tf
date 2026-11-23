variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name used for tagging"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones (at least 2)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (ALB, NAT gateways)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (EKS nodes, ElastiCache)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "starttech-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version (1.34 or newer)"
  type        = string
  default     = "1.34"
}

variable "node_instance_type" {
  description = "Instance type for the managed node group"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "eks_admin_principal_arns" {
  description = "Extra IAM principals (e.g. the user/role the application pipeline uses) granted cluster-admin"
  type        = list(string)
  default     = []
}

variable "alb_dns_name" {
  description = <<-EOT
    DNS name of the ALB created by the AWS Load Balancer Controller from k8s/ingress.yaml.
    Two-pass deploy: apply once with the placeholder, deploy the backend, read the ALB hostname
    (kubectl get ingress backend-api), set this value and apply again.
  EOT
  type        = string
  default     = "placeholder-alb.example.com"
}
