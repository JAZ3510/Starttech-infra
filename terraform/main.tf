terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state keeps the GitHub Actions pipeline idempotent.
  # terraform init -backend-config="bucket=..." -backend-config="key=starttech/terraform.tfstate" -backend-config="region=..."
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "starttech"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "networking" {
  source = "./modules/networking"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name         = var.cluster_name
  cluster_version      = var.cluster_version
  private_subnet_ids   = module.networking.private_subnet_ids
  public_subnet_ids    = module.networking.public_subnet_ids
  node_instance_type   = var.node_instance_type
  node_desired_size    = var.node_desired_size
  node_min_size        = var.node_min_size
  node_max_size        = var.node_max_size
  admin_principal_arns = var.eks_admin_principal_arns
}

module "storage" {
  source = "./modules/storage"

  frontend_bucket_prefix = "starttech-frontend-bucket"
  ecr_repository_name    = "starttech-backend-api"
}

module "cdn" {
  source = "./modules/cdn"

  s3_bucket_id                   = module.storage.frontend_bucket_id
  s3_bucket_arn                  = module.storage.frontend_bucket_arn
  s3_bucket_regional_domain_name = module.storage.frontend_bucket_regional_domain_name
  alb_dns_name                   = var.alb_dns_name
}

module "database" {
  source = "./modules/database"

  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  eks_node_sg_id     = module.eks.cluster_security_group_id
  redis_cluster_id   = "starttech-redis"
  redis_node_type    = "cache.t3.micro"
}

# ---------------------------------------------------------------------------
# Grader IAM user (read-only, least privilege) required by the assessment
# ---------------------------------------------------------------------------
resource "aws_iam_user" "grader" {
  name = "start-tech-grader"
}

resource "aws_iam_user_policy" "grader" {
  name = "start-tech-grader-readonly"
  user = aws_iam_user.grader.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GraderReadOnlyS3"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketPublicAccessBlock",
          "s3:ListBucket"
        ]
        Resource = "*"
      },
      {
        Sid    = "GraderReadOnlyCloudFront"
        Effect = "Allow"
        Action = [
          "cloudfront:ListDistributions",
          "cloudfront:GetDistributionConfig"
        ]
        Resource = "*"
      },
      {
        Sid    = "GraderReadOnlyEKS"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      {
        Sid      = "GraderReadOnlyElastiCache"
        Effect   = "Allow"
        Action   = ["elasticache:DescribeCacheClusters"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "grader" {
  user = aws_iam_user.grader.name
}

resource "aws_iam_user_login_profile" "grader" {
  user                    = aws_iam_user.grader.name
  password_reset_required = false
}
