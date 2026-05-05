#!/bin/bash

TABLE="feature-flag-dev-analytics-events"
REGION="us-east-1"

COUNT=$(aws dynamodb scan --table-name "$TABLE" --region "$REGION" --select COUNT --query 'Count' --output text 2>/dev/null)
echo "Total de registros: $COUNT"
echo ""

echo "Ultimos 10 registros:"
aws dynamodb scan \
  --table-name "$TABLE" \
  --region "$REGION" \
  --max-items 10 \
  --query 'Items[*].{event_id:event_id.S, flag:flag_name.S, user:user_id.S, result:result.BOOL}' \
  --output table 2>/dev/null

echo ""
echo "Contagem por flag:"
aws dynamodb scan \
  --table-name "$TABLE" \
  --region "$REGION" \
  --query 'Items[*].flag_name.S' \
  --output text 2>/dev/null | tr '\t' '\n' | sort | uniq -c | sort -rn
