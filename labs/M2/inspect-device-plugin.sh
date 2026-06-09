#!/usr/bin/env bash
# M2 Lab: 巡检 NVIDIA Device Plugin 部署状态
set -euo pipefail

NS="${NS:-kube-system}"

echo "=== 1. Device Plugin DaemonSet ==="
kubectl get daemonset -A -l app=nvidia-device-plugin-daemonset 2>/dev/null \
  || kubectl get daemonset -A 2>/dev/null | grep -i device-plugin || echo "(未找到 device-plugin DaemonSet)"

echo ""
echo "=== 2. Device Plugin Pods ==="
kubectl get pods -A -o wide 2>/dev/null | grep -iE 'device-plugin|nvidia-device-plugin' || echo "(未找到)"

DP_POD=$(kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' 2>/dev/null \
  | grep -i device-plugin | grep -i nvidia | head -1 || true)

if [[ -n "$DP_POD" ]]; then
  DP_NS="${DP_POD%%/*}"
  DP_NAME="${DP_POD##*/}"
  echo ""
  echo "=== 3. Device Plugin 配置 (Pod: $DP_POD) ==="
  kubectl get pod -n "$DP_NS" "$DP_NAME" -o jsonpath='{.spec.containers[0].args}' 2>/dev/null | tr ',' '\n' || true

  echo ""
  echo "=== 4. Device Plugin 最近日志 ==="
  kubectl logs -n "$DP_NS" "$DP_NAME" --tail=30 2>/dev/null || true

  echo ""
  echo "=== 5. 检查 socket (需 privileged) ==="
  kubectl exec -n "$DP_NS" "$DP_NAME" -- ls -la /var/lib/kubelet/device-plugins/ 2>/dev/null \
    || echo "(无法 exec，跳过 socket 检查)"
fi

echo ""
echo "=== 6. 所有节点 GPU allocatable ==="
kubectl get nodes -o custom-columns=\
'NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu,CAP:.status.capacity.nvidia\.com/gpu,READY:.status.conditions[?(@.type=="Ready")].status'

echo ""
echo "=== 7. MIG 资源 (如有) ==="
kubectl get nodes -o json 2>/dev/null \
  | grep -o 'nvidia.com/mig[^"]*' | sort -u || echo "(无 MIG 资源)"
