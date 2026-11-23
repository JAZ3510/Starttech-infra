resource "aws_elasticache_subnet_group" "redis" {
  name       = "starttech-redis-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "redis" {
  name        = "starttech-redis-sg"
  description = "Allow Redis only from EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from EKS workers"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_node_sg_id]
  }

  tags = {
    Name = "starttech-redis-sg"
  }
}

resource "aws_elasticache_cluster" "starttech-redis" {
  cluster_id           = var.redis_cluster_id
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  port                 = 6379
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]
}
