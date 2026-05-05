#!/bin/bash

echo "NODE:"
kubectl top nodes
echo ""

echo "PODS:"
kubectl get pods -n feature-flag-dev -o wide
echo ""

echo "CONSUMO DOS PODS:"
kubectl top pods -n feature-flag-dev
echo ""

echo "HPAs:"
kubectl get hpa -n feature-flag-dev
echo ""

echo "KEDA ScaledObjects:"
kubectl get scaledobject -n feature-flag-dev
echo ""

echo "SERVICES:"
kubectl get svc -n feature-flag-dev
echo ""

echo "HEALTH CHECKS:"
for port in 30001 30002 30003 30004 30005; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/health --connect-timeout 2)
    SERVICE=""
    case $port in
        30001) SERVICE="auth-service      " ;;
        30002) SERVICE="flag-service      " ;;
        30003) SERVICE="targeting-service " ;;
        30004) SERVICE="evaluation-service" ;;
        30005) SERVICE="analytics-service " ;;
    esac
    echo "  $SERVICE :$port -> $STATUS"
done
echo ""

QUEUE_URL="https://sqs.us-east-1.amazonaws.com/964177143569/feature-flag-dev-evaluation-events"
QUEUE_MSGS=$(aws sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible --region us-east-1 --query 'Attributes' --output json 2>/dev/null)
echo "SQS QUEUE:"
echo "$QUEUE_MSGS" | jq -r '"  Na fila: \(.ApproximateNumberOfMessages)\n  Em processamento: \(.ApproximateNumberOfMessagesNotVisible)"' 2>/dev/null
echo ""

DYNAMO_COUNT=$(aws dynamodb scan --table-name feature-flag-dev-analytics-events --region us-east-1 --select COUNT --query 'Count' --output text 2>/dev/null)
echo "DYNAMODB:"
echo "  Registros: $DYNAMO_COUNT"
