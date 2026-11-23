variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "eks_node_sg_id" {
  description = "Security group of the EKS worker nodes (only source allowed to reach Redis)"
  type        = string
}

variable "redis_cluster_id" {
  type    = string
  default = "starttech-redis"
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}
