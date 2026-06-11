#!/usr/bin/env bash
# Lab 4C: 定位 K8s scheduler 中 GPU 相关插件源码
set -euo pipefail

K8S_SRC="${K8S_SRC:-/tmp/kubernetes}"

if [[ ! -d "$K8S_SRC/.git" ]]; then
  echo "=== 克隆 K8s scheduler 源码 (depth=1) ==="
  git clone --depth=1 https://github.com/kubernetes/kubernetes.git "$K8S_SRC"
fi

SCHED="$K8S_SRC/pkg/scheduler"

echo ""
echo "=== 1. NodeResourcesFit (GPU Filter) ==="
grep -n "nvidia\|extended\|Insufficient" "$SCHED/framework/plugins/noderesources/fit.go" 2>/dev/null | head -10 \
  || grep -rn "Insufficient" "$SCHED/framework/plugins/noderesources/" | head -5

echo ""
echo "=== 2. 默认启用插件列表 ==="
grep -n "RegisterMultiPoint\|factoryRegistry\|noderesources" \
  "$SCHED/framework/runtime/registry.go" 2>/dev/null | head -15 \
  || ls "$SCHED/framework/plugins/"

echo ""
echo "=== 3. scheduler-plugins 社区项目 ==="
echo "  https://github.com/kubernetes-sigs/scheduler-plugins"
echo "  含 Coscheduling, NodeResourcesFitPlus, NetworkAware 等"

echo ""
echo "=== 4. Volcano GPU topology ==="
echo "  https://github.com/volcano-sh/volcano/tree/master/pkg/scheduler/plugins"

echo ""
echo "=== 跟读建议 ==="
echo "  1. $SCHED/framework/plugins/noderesources/fit.go     — Filter 逻辑"
echo "  2. $SCHED/framework/plugins/noderesources/resource_allocation.go"
echo "  3. labs/M4/gpu-topology-score-plugin-skeleton.go     — Score 骨架"
