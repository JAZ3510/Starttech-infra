# starttech-infra

Terraform for the StartTech platform on AWS: VPC, Amazon EKS, S3 + ECR, one CloudFront distribution
(S3 frontend + ALB API behind the same HTTPS domain) and ElastiCache Redis.

## Layout

```
terraform/
  main.tf  variables.tf  outputs.tf  terraform.tfvars.example
  modules/networking  VPC 10.0.0.0/16, 2 public + 2 private subnets, IGW, NAT, LB tags
  modules/eks         starttech-cluster, starttech-node-group (2x t3.medium), IAM, OIDC, LBC role
  modules/storage     starttech-frontend-bucket-<account> (private), ECR starttech-backend-api
  modules/cdn         CloudFront: S3-Frontend (OAC) + ALB-Backend, /api/* uncached, SPA 403/404 -> /index.html 200
  modules/database    starttech-redis (cache.t3.micro, private subnets, only reachable from EKS nodes)
scripts/deploy-infrastructure.sh
.github/workflows/infrastructure-deploy.yml
```

## Deploying

1. Create an S3 bucket for Terraform state (the script does this for you).
2. `cp terraform/terraform.tfvars.example terraform/terraform.tfvars` and edit.
3. `./scripts/deploy-infrastructure.sh <state-bucket> us-east-1`
4. Deploy the backend from `starttech-application`; the Ingress creates the ALB.
5. Put the ALB hostname in `alb_dns_name` (repo variable `ALB_DNS_NAME`) and apply again so the
   `ALB-Backend` origin points at the real load balancer.

## GitHub Actions

Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `TF_STATE_BUCKET`.
Variables (optional): `ALB_DNS_NAME`, `EKS_ADMIN_PRINCIPAL_ARNS` (JSON list, e.g. `["arn:aws:iam::123:user/ci"]`).

The workflow runs on pushes to `main` that touch `terraform/`: `fmt -check`, `init`, `validate`, `apply -auto-approve`.

## Grader user

`start-tech-grader` is created in `main.tf` with the read-only policy from the brief.
Retrieve credentials after apply:

```
terraform output -raw grader_access_key_id
terraform output -raw grader_secret_access_key
terraform output -raw grader_console_password
```

Do not commit these values; paste them only into the submission document.
