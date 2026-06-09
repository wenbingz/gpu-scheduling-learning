#!/usr/bin/env bash
# 一键搭建 L0 本地 GPU 调度实验环境 (kind + KWOK)
set -euo pipefail

KWOK_VERSION="${KWOK_VERSION:-v0.6.1}"
CLUSTER_NAME="${CLUSTER_NAME:-gpu-learning}"

echo "=== 1. 检查 kind 集群 ==="
kubectl config use-context "kind-${CLUSTER_NAME}"
kubectl get nodes

echo ""
echo "=== 2. 安装 KWOK ${KWOK_VERSION} ==="
kubectl apply -f "https://github.com/kubernetes-sigs/kwok/releases/download/${KWOK_VERSION}/kwok.yaml"
kubectl apply -f "https://github.com/kubernetes-sigs/kwok/releases/download/${KWOK_VERSION}/stage-fast.yaml"
kubectl rollout status deployment/kwok-controller -n kube-system --timeout=120s

echo ""
echo "=== 3. 创建假 GPU 节点 ==="
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "${SCRIPT_DIR}/fake-gpu-nodes.yaml"

echo ""
echo "=== 4. 验证 ==="
kubectl get nodes -o custom-columns=\
'NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu,PRODUCT:.metadata.labels.nvidia\.com/gpu\.product,TAINTS:.spec.taints[*].key'

echo ""
echo "=== 完成! 下一步 ==="
echo "  kubectl apply -f ${SCRIPT_DIR}/gpu-pod-kwok.yaml"
echo "  kubectl apply -f ${SCRIPT_DIR}/gpu-pod-pending.yaml"
echo "  ${SCRIPT_DIR}/../M1/debug-commands.sh gpu-test gpu-test-oom-schedule"
