#!/usr/bin/env bash
# Package and deploy the Network Firewall POC (firewall-master.yaml + nested stacks).
# Usage: ./scripts/deploy.sh <stack-name> <artifact-bucket> <params-file.json> [role-arn]
set -euo pipefail

STACK="${1:?stack name, e.g. anfw-poc-firewall}"
BUCKET="${2:?S3 bucket (same region) for packaged templates}"
PARAMS="${3:?parameter file, e.g. cloudformation/params/poc-existing-vpc.json}"
ROLE_ARN="${4:-}"
REGION="${AWS_REGION:-ap-south-1}"
CFN_DIR="$(cd "$(dirname "$0")/../cloudformation" && pwd)"
OUT="$(mktemp -d)/packaged.yaml"

if grep -q REPLACE_ "$PARAMS"; then
  echo "ERROR: $PARAMS still contains REPLACE_ placeholders" >&2; exit 1
fi

echo "==> Linting"
command -v cfn-lint >/dev/null && cfn-lint "$CFN_DIR"/0*.yaml || echo "(cfn-lint not installed, skipping)"

echo "==> Packaging nested templates to s3://$BUCKET"
aws cloudformation package --region "$REGION" \
  --template-file "$CFN_DIR/firewall-master.yaml" \
  --s3-bucket "$BUCKET" --s3-prefix anfw-poc \
  --output-template-file "$OUT"

echo "==> Validating"
aws cloudformation validate-template --region "$REGION" --template-body "file://$OUT" >/dev/null

echo "==> Creating change set for review"
CS="review-$(date +%Y%m%d%H%M%S)"
TYPE=CREATE
aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" >/dev/null 2>&1 && TYPE=UPDATE
ROLE_ARGS=()
[ -n "$ROLE_ARN" ] && ROLE_ARGS=(--role-arn "$ROLE_ARN")
aws cloudformation create-change-set --region "$REGION" --stack-name "$STACK" \
  --change-set-name "$CS" --change-set-type "$TYPE" \
  --template-body "file://$OUT" --parameters "file://$PARAMS" \
  "${ROLE_ARGS[@]}"
aws cloudformation wait change-set-create-complete --region "$REGION" --stack-name "$STACK" --change-set-name "$CS"
aws cloudformation describe-change-set --region "$REGION" --stack-name "$STACK" --change-set-name "$CS" \
  --query 'Changes[].ResourceChange.[Action,LogicalResourceId,ResourceType,Replacement]' --output table

read -r -p "Execute this change set? [y/N] " ANS
[ "$ANS" = "y" ] || { echo "Not executed. Delete with: aws cloudformation delete-change-set --stack-name $STACK --change-set-name $CS"; exit 0; }
aws cloudformation execute-change-set --region "$REGION" --stack-name "$STACK" --change-set-name "$CS"
WAIT=stack-create-complete; [ "$TYPE" = UPDATE ] && WAIT=stack-update-complete
aws cloudformation wait "$WAIT" --region "$REGION" --stack-name "$STACK"
aws cloudformation describe-stacks --region "$REGION" --stack-name "$STACK" --query 'Stacks[0].Outputs' --output table
