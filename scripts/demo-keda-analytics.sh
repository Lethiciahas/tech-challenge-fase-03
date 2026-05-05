#!/bin/bash

QUEUE_URL="https://sqs.us-east-1.amazonaws.com/964177143569/feature-flag-dev-evaluation-events"
REGION="us-east-1"
COUNT=${1:-50}

echo "Estado ANTES:"
kubectl get scaledobject -n feature-flag-dev
kubectl get hpa -n feature-flag-dev -l scaledobject.keda.sh/name=analytics-service-scaler
kubectl get pods -n feature-flag-dev -l app=analytics-service
echo ""

echo "Enviando $COUNT mensagens para SQS..."
FLAGS=("feature-dark-mode" "feature-new-checkout" "feature-beta-dashboard" "feature-ai-search" "feature-notifications")

for i in $(seq 1 $COUNT); do
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)
  FLAG=${FLAGS[$((RANDOM % ${#FLAGS[@]}))]}
  RESULT=$([ $((RANDOM % 2)) -eq 0 ] && echo true || echo false)
  MSG="{\"event_type\":\"flag_evaluation\",\"flag_name\":\"$FLAG\",\"user_id\":\"user-$((RANDOM % 1000))\",\"result\":$RESULT,\"timestamp\":\"$TIMESTAMP\"}"

  aws sqs send-message --queue-url "$QUEUE_URL" --message-body "$MSG" --region "$REGION" --output text --query 'MessageId' > /dev/null 2>&1
  echo -ne "  Enviadas: $i/$COUNT\r"
done
echo "$COUNT mensagens enviadas!"
echo ""

echo "Monitorando KEDA a cada 15s..."
echo ""

for i in $(seq 1 8); do
    sleep 15
    QUEUE_MSGS=$(aws sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names ApproximateNumberOfMessages --region "$REGION" --query 'Attributes.ApproximateNumberOfMessages' --output text 2>/dev/null)
    echo "[$(date +%H:%M:%S)] Checkpoint $i/8"
    echo "  Mensagens na fila: $QUEUE_MSGS"
    kubectl get pods -n feature-flag-dev -l app=analytics-service --no-headers | wc -l | xargs echo "  Replicas analytics:"
    kubectl get hpa -n feature-flag-dev -l scaledobject.keda.sh/name=analytics-service-scaler --no-headers 2>/dev/null
    echo ""
done

DYNAMO_COUNT=$(aws dynamodb scan --table-name feature-flag-dev-analytics-events --region "$REGION" --select COUNT --query 'Count' --output text 2>/dev/null)
echo "Total de registros no DynamoDB: $DYNAMO_COUNT"
echo ""

echo "Estado DEPOIS:"
kubectl get scaledobject -n feature-flag-dev
kubectl get pods -n feature-flag-dev -l app=analytics-service
