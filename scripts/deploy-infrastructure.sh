#!/usr/bin/env bash
# Local / manual infrastructure deployment helper.
# Usage: ./scripts/deploy-infrastructure.sh <state-bucket> [region]
set -euo pipefail

STATE_BUCKET="${1:?Usage: $0 <terraform-state-bucket> [region]}"
REGION="${2:-us-east-1}"
CLUSTER_NAME="starttech-cluster"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo ">> Ensuring Terraform state bucket exists: ${STATE_BUCKET}"
if ! aws s3api head-bucket --bucket "${STATE_BUCKET}" 2>/dev/null; then
  if [ "${REGION}" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "${STATE_BUCKET}" --region "${REGION}"
  else
    aws s3api create-bucket --bucket "${STATE_BUCKET}" --region "${REGION}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi
  aws s3api put-bucket-versioning --bucket "${STATE_BUCKET}" \
    --versioning-configuration Status=Enabled
fi

cd "${ROOT_DIR}/terraform"

echo ">> terraform fmt / init / validate"
terraform fmt -recursive
terraform init \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="key=starttech/terraform.tfstate" \
  -backend-config="region=${REGION}"
terraform validate

echo ">> terraform apply"
terraform apply -auto-approve -var="aws_region=${REGION}" ${TF_EXTRA_ARGS:-}

echo ">> Configuring kubectl"
aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}"

echo ">> Installing AWS Load Balancer Controller"
LBC_ROLE_ARN="$(terraform output -raw lb_controller_role_arn)"
VPC_ID="$(terraform output -raw vpc_id)"

helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName="${CLUSTER_NAME}" \
  --set region="${REGION}" \
  --set vpcId="${VPC_ID}" \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="${LBC_ROLE_ARN}"

kubectl -n kube-system rollout status deployment/aws-load-balancer-controller --timeout=180s

cat <<MSG

Done. Next steps:
  1. Deploy the backend (starttech-application) so the Ingress creates the ALB.
  2. kubectl get ingress backend-api -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  3. Set that hostname as the GitHub repo variable ALB_DNS_NAME (or alb_dns_name in tfvars) and re-run this script.
MSG
