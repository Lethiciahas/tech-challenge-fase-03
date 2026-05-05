#!/bin/bash

QUEUE_URL="https://sqs.us-east-1.amazonaws.com/964177143569/feature-flag-dev-evaluation-events"
REGION="us-east-1"
COUNT=${1:-10}

echo "Enviando $COUNT mensagens para SQS..."

FLAGS=("feature-dark-mode" "feature-new-checkout" "feature-beta-dashboard" "feature-ai-search" "feature-notifications")

for i in $(seq 1 $COUNT); do
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)
  FLAG=${FLAGS[$((RANDOM % ${#FLAGS[@]}))]}
  RESULT=$([ $((RANDOM % 2)) -eq 0 ] && echo true || echo false)

  MSG="{\"event_type\":\"flag_evaluation\",\"flag_name\":\"$FLAG\",\"user_id\":\"user-$((RANDOM % 1000))\",\"result\":$RESULT,\"timestamp\":\"$TIMESTAMP\"}"

  MSGID=$(aws sqs send-message \
    --queue-url "$QUEUE_URL" \
    --message-body "$MSG" \
    --region "$REGION" \
    --output text --query 'MessageId' 2>/dev/null)

  if [ $? -eq 0 ]; then
    echo "  [$i/$COUNT] flag=$FLAG result=$RESULT"
  else
    echo "  Erro na mensagem $i/$COUNT"
  fi
done

echo ""
ATTRS=$(aws sqs get-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
  --region "$REGION" \
  --output json 2>/dev/null)

echo "$ATTRS" | jq -r '.Attributes | "  Mensagens na fila: \(.ApproximateNumberOfMessages)\n  Em processamento: \(.ApproximateNumberOfMessagesNotVisible)"'
