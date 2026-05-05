#!/bin/bash

echo "Estado ANTES da carga:"
kubectl get hpa evaluation-service-hpa -n feature-flag-dev
kubectl get pods -n feature-flag-dev -l app=evaluation-service
echo ""

echo "Iniciando teste de carga (200 req/s por 120s)..."
hey -z 120s -c 50 -q 4 http://localhost:30004/health > /tmp/hey-results.txt 2>&1 &
HEY_PID=$!

echo "Monitorando HPA a cada 10s..."
echo ""

for i in $(seq 1 12); do
    sleep 10
    echo "[$(date +%H:%M:%S)] Checkpoint $i/12"
    kubectl top pods -n feature-flag-dev -l app=evaluation-service 2>/dev/null
    kubectl get hpa evaluation-service-hpa -n feature-flag-dev --no-headers
    kubectl get pods -n feature-flag-dev -l app=evaluation-service --no-headers | wc -l | xargs echo "Replicas:"
    echo ""
done

wait $HEY_PID 2>/dev/null

echo "Resultado do teste de carga:"
grep -E "Requests/sec|Total:|Status code" /tmp/hey-results.txt
echo ""

echo "Estado DEPOIS da carga:"
kubectl get hpa evaluation-service-hpa -n feature-flag-dev
kubectl get pods -n feature-flag-dev -l app=evaluation-service
