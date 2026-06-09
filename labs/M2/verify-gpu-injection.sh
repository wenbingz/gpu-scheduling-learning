#!/usr/bin/env bash
# M2 Lab: 验证 GPU 注入到容器 (需真实 GPU 集群)
set -euo pipefail

POD="${1:-gpu-test}"
NS="${2:-default}"

echo "=== 1. Pod 状态 ==="
kubectl get pod "$POD" -n "$NS" -o wide

echo ""
echo "=== 2. NVIDIA 环境变量 ==="
kubectl exec "$POD" -n "$NS" -- env 2>/dev/null | grep -iE 'NVIDIA|CUDA' | sort || echo "(无法 exec)"

echo ""
echo "=== 3. 设备文件 ==="
kubectl exec "$POD" -n "$NS" -- ls -la /dev/nvidia* 2>/dev/null || echo "(无 /dev/nvidia* 或无法 exec)"

echo ""
echo "=== 4. nvidia-smi (镜像需包含) ==="
kubectl exec "$POD" -n "$NS" -- nvidia-smi -L 2>/dev/null \
  || echo "(镜像无 nvidia-smi，换 nvcr.io/nvidia/cuda:12-base 测试)"

echo ""
echo "=== 5. 节点侧 nvidia-smi (对比) ==="
NODE=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.nodeName}')
echo "Pod 运行在: $NODE"
echo "(需在节点上执行 nvidia-smi 对比进程)"
