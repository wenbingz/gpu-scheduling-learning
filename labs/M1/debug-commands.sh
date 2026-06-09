#!/usr/bin/env bash
# M1 Lab 调试命令集 — 在有 GPU 的集群上运行
# 用法:
#   ./debug-commands.sh pod-a pod-b pod-c
#   ./debug-commands.sh -n training gpu-test-0 gpu-test-1
#   ./debug-commands.sh --namespace default gpu-test

set -euo pipefail

NS="default"
PODS=()

usage() {
  cat <<'EOF'
用法: debug-commands.sh [选项] <pod-name> [pod-name ...]

选项:
  -n, --namespace <ns>   命名空间 (默认: default)
  -h, --help             显示帮助

示例:
  ./debug-commands.sh gpu-test
  ./debug-commands.sh gpu-test-0 gpu-test-1 gpu-test-2
  ./debug-commands.sh -n kubeflow worker-0 worker-1
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace)
      [[ $# -ge 2 ]] || { echo "错误: $1 需要参数" >&2; exit 1; }
      NS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      PODS+=("$@")
      break
      ;;
    -*)
      echo "错误: 未知选项 $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      PODS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#PODS[@]} -eq 0 ]]; then
  PODS=(gpu-test)
fi

debug_pod() {
  local pod="$1"

  echo "################################################################"
  echo "# Pod: $pod (namespace: $NS)"
  echo "################################################################"

  echo ""
  echo "=== 1. Pod 状态 ==="
  kubectl get pod "$pod" -n "$NS" -o wide

  echo ""
  echo "=== 2. 调度 Events ==="
  kubectl describe pod "$pod" -n "$NS" | sed -n '/Events:/,$p'

  echo ""
  echo "=== 3. 节点 GPU 资源 ==="
  local node
  node=$(kubectl get pod "$pod" -n "$NS" -o jsonpath='{.spec.nodeName}' 2>/dev/null || true)
  if [[ -n "$node" ]]; then
    kubectl describe node "$node" | grep -E 'nvidia\.com|Allocatable|Capacity' -A2
  else
    echo "(Pod 未调度到节点，跳过)"
  fi

  echo ""
  echo "=== 4. 容器内 GPU 环境变量 ==="
  if kubectl exec "$pod" -n "$NS" -- env 2>/dev/null | grep -i nvidia; then
    :
  else
    echo "(Pod 未 Running 或无 NVIDIA 环境变量，跳过)"
  fi
}

echo "=== 集群 GPU 节点概览 ==="
kubectl get nodes -o custom-columns=\
'NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu,TAINTS:.spec.taints[*].key'

echo ""
echo "=== Device Plugin Pods ==="
kubectl get pods -A -l app=nvidia-device-plugin-daemonset 2>/dev/null \
  || kubectl get pods -A | grep -i device-plugin | grep -i nvidia || true

for pod in "${PODS[@]}"; do
  echo ""
  debug_pod "$pod"
done

echo ""
echo "=== 完成: 共检查 ${#PODS[@]} 个 Pod ==="
