#!/usr/bin/env bash
# M1 Lab 调试命令集 — 在有 GPU 的集群上运行

set -euo pipefail

POD="${1:-gpu-test}"
NS="${2:-default}"

echo "=== 1. Pod 状态 ==="
kubectl get pod "$POD" -n "$NS" -o wide

echo ""
echo "=== 2. 调度 Events ==="
kubectl describe pod "$POD" -n "$NS" | sed -n '/Events:/,$p'

echo ""
echo "=== 3. 节点 GPU 资源 ==="
NODE=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.nodeName}')
if [[ -n "$NODE" ]]; then
  kubectl describe node "$NODE" | grep -E 'nvidia\.com|Allocatable|Capacity' -A2
fi

echo ""
echo "=== 4. Device Plugin Pods ==="
kubectl get pods -A -l app=nvidia-device-plugin-daemonset 2>/dev/null \
  || kubectl get pods -A | grep -i device-plugin | grep -i nvidia || true

echo ""
echo "=== 5. 容器内 GPU 环境变量 ==="
kubectl exec "$POD" -n "$NS" -- env 2>/dev/null | grep -i nvidia || echo "(Pod 未 Running，跳过)"

echo ""
echo "=== 6. 集群 GPU 节点概览 ==="
kubectl get nodes -o custom-columns=\
'NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu,TAINTS:.spec.taints[*].key'
