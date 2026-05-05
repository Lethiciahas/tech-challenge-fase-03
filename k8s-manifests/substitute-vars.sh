#!/bin/bash
set -e

export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

for file in /home/ubuntu/k8s-manifests/*.yaml; do
    sed -i "s/\${AWS_REGION}/$AWS_REGION/g" "$file"
    sed -i "s/\${AWS_ACCOUNT_ID}/$AWS_ACCOUNT_ID/g" "$file"
done
