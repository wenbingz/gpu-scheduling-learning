#!/usr/bin/env bash
# Lab 5A: 观察 Gang Scheduling 问题
set -euo pipefail

echo "=== 1. Gang Demo 节点 GPU 状态 ==="
kubectl get node fake-gpu-node-gang-demo -o custom-columns=\
'NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu' 2>/dev/null \
  || echo "(节点不存在，先 apply gang-problem-demo.yaml)"

echo ""
echo "=== 2. 推理 Pod（占卡）==="
kubectl get pods -l app=inference-blocker -o wide 2>/dev/null || true

echo ""
echo "=== 3. 训练 Gang Worker 状态 ==="
kubectl get pods -l job=llm-train-gang -o custom-columns=\
'NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName' 2>/dev/null || true

RUNNING=$(kubectl get pods -l job=llm-train-gang --field-selector=status.phase=Running -o name 2>/dev/null | wc -l | tr -d ' ')
PENDING=$(kubectl get pods -l job=llm-train-gang --field-selector=status.phase=Pending -o name 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "=== 4. Gang 调度结果 ==="
echo "  Running: $RUNNING / 8"
echo "  Pending: $PENDING / 8"

if [[ "$RUNNING" -gt 0 && "$RUNNING" -lt 8 ]]; then
  echo ""
  echo "  ⚠️  部分调度！标准 scheduler 无法保证 Gang。"
  echo "  → 训练 Job 会 hang（AllReduce 等不齐 $RUNNING 个 worker）"
  echo "  → 需要 Volcano PodGroup (minMember=8) 实现 All-or-Nothing"
fi

echo ""
echo "=== 5. 节点 allocated ==="
kubectl describe node fake-gpu-node-gang-demo 2>/dev/null | grep -A5 'Allocated resources' || true
