#!/bin/bash
set -e

apt-get update
apt-get upgrade -y

apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    jq \
    unzip \
    git

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu
rm get-docker.sh

curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 644" sh -

sleep 30

mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

kubectl create namespace ${project_name}-${environment} || true
kubectl create namespace argocd || true

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8080, "nodePort": 30090}]}}'

mkdir -p /home/ubuntu/k8s-manifests
chown -R ubuntu:ubuntu /home/ubuntu/k8s-manifests

cat > /home/ubuntu/setup-app.sh << 'SETUP_SCRIPT'
#!/bin/bash
set -e

export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export PROJECT_NAME="${project_name}"
export ENVIRONMENT="${environment}"

AUTH_SECRET=$(aws secretsmanager get-secret-value --secret-id $PROJECT_NAME-$ENVIRONMENT-auth-db-credentials --query SecretString --output text --region $AWS_REGION)
FLAG_SECRET=$(aws secretsmanager get-secret-value --secret-id $PROJECT_NAME-$ENVIRONMENT-flag-db-credentials --query SecretString --output text --region $AWS_REGION)
TARGETING_SECRET=$(aws secretsmanager get-secret-value --secret-id $PROJECT_NAME-$ENVIRONMENT-targeting-db-credentials --query SecretString --output text --region $AWS_REGION)

AUTH_ENDPOINT=$(echo $AUTH_SECRET | jq -r '.endpoint' | cut -d: -f1)
AUTH_USER=$(echo $AUTH_SECRET | jq -r '.username')
AUTH_PASS=$(echo $AUTH_SECRET | jq -r '.password')
AUTH_DB=$(echo $AUTH_SECRET | jq -r '.database')

FLAG_ENDPOINT=$(echo $FLAG_SECRET | jq -r '.endpoint' | cut -d: -f1)
FLAG_USER=$(echo $FLAG_SECRET | jq -r '.username')
FLAG_PASS=$(echo $FLAG_SECRET | jq -r '.password')
FLAG_DB=$(echo $FLAG_SECRET | jq -r '.database')

TARGETING_ENDPOINT=$(echo $TARGETING_SECRET | jq -r '.endpoint' | cut -d: -f1)
TARGETING_USER=$(echo $TARGETING_SECRET | jq -r '.username')
TARGETING_PASS=$(echo $TARGETING_SECRET | jq -r '.password')
TARGETING_DB=$(echo $TARGETING_SECRET | jq -r '.database')

REDIS_ENDPOINT=$(aws elasticache describe-cache-clusters \
  --cache-cluster-id $PROJECT_NAME-$ENVIRONMENT-redis \
  --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' \
  --output text \
  --region $AWS_REGION)

SQS_URL=$(aws sqs get-queue-url \
  --queue-name $PROJECT_NAME-$ENVIRONMENT-evaluation-events \
  --query QueueUrl \
  --output text \
  --region $AWS_REGION)

DYNAMODB_TABLE="$PROJECT_NAME-$ENVIRONMENT-analytics-events"

AUTH_DATABASE_URL="postgresql://$AUTH_USER:$AUTH_PASS@$AUTH_ENDPOINT:5432/$AUTH_DB"
FLAG_DATABASE_URL="postgresql://$FLAG_USER:$FLAG_PASS@$FLAG_ENDPOINT:5432/$FLAG_DB"
TARGETING_DATABASE_URL="postgresql://$TARGETING_USER:$TARGETING_PASS@$TARGETING_ENDPOINT:5432/$TARGETING_DB"
REDIS_URL="redis://$REDIS_ENDPOINT:6379"

kubectl create secret generic app-secrets \
  --from-literal=AUTH_DATABASE_URL="$AUTH_DATABASE_URL" \
  --from-literal=FLAG_DATABASE_URL="$FLAG_DATABASE_URL" \
  --from-literal=TARGETING_DATABASE_URL="$TARGETING_DATABASE_URL" \
  --from-literal=REDIS_URL="$REDIS_URL" \
  --from-literal=AWS_SQS_URL="$SQS_URL" \
  --from-literal=AWS_DYNAMODB_TABLE="$DYNAMODB_TABLE" \
  --from-literal=AWS_REGION="$AWS_REGION" \
  --from-literal=MASTER_KEY="admin-secreto-123" \
  --from-literal=SERVICE_API_KEY="tm_key_placeholder" \
  --namespace $PROJECT_NAME-$ENVIRONMENT \
  --dry-run=client -o yaml | kubectl apply -f -
SETUP_SCRIPT

chmod +x /home/ubuntu/setup-app.sh
chown ubuntu:ubuntu /home/ubuntu/setup-app.sh

cat > /home/ubuntu/deploy-app.sh << 'DEPLOY_SCRIPT'
#!/bin/bash
set -e

export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export PROJECT_NAME="${project_name}"
export ENVIRONMENT="${environment}"
export NAMESPACE="$PROJECT_NAME-$ENVIRONMENT"

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

kubectl apply -f /home/ubuntu/k8s-manifests/ -n $NAMESPACE
kubectl wait --for=condition=available --timeout=300s deployment --all -n $NAMESPACE

kubectl get svc -n $NAMESPACE
kubectl get pods -n $NAMESPACE
DEPLOY_SCRIPT

chmod +x /home/ubuntu/deploy-app.sh
chown ubuntu:ubuntu /home/ubuntu/deploy-app.sh

cat > /home/ubuntu/check-status.sh << 'STATUS_SCRIPT'
#!/bin/bash
export PROJECT_NAME="${project_name}"
export ENVIRONMENT="${environment}"
export NAMESPACE="$PROJECT_NAME-$ENVIRONMENT"

kubectl get nodes
kubectl get pods -n $NAMESPACE -o wide
kubectl get svc -n $NAMESPACE
kubectl get deployments -n $NAMESPACE
STATUS_SCRIPT

chmod +x /home/ubuntu/check-status.sh
chown ubuntu:ubuntu /home/ubuntu/check-status.sh

touch /home/ubuntu/setup-complete.txt
echo "Setup completed at $(date)" > /home/ubuntu/setup-complete.txt
