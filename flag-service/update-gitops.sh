#!/bin/bash
set -e

GITHUB_TOKEN=$(aws ssm get-parameter --name /feature-flag/github-token --with-decryption --query Parameter.Value --output text)
git clone https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git /tmp/gitops-repo
cd /tmp/gitops-repo

NEW_IMAGE="${ECR_REPO}:${IMAGE_TAG}"
sed -i "s|image:.*flag-service:.*|        image: ${NEW_IMAGE}|" gitops/base/flag-service.yaml

git config user.email codebuild@ci.local
git config user.name CodeBuild
git add -A
git diff --cached --quiet || git commit -m "ci flag-service ${IMAGE_TAG}"
git push origin main || true
