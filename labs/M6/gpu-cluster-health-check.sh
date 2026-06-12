#!/usr/bin/env bash
# Lab 6A: GPU 集群健康巡检
set -euo pipefail

echo "========================================"
echo "  GPU 集群健康巡检"
echo "========================================"

echo ""
echo "=== 1. GPU 节点概览 ==="
kubectl get nodes -o custom-columns=\
'NAME:.metadata.name,GPU-ALLOC:.status.allocatable.nvidia\.com/gpu,GPU-CAP:.status.capacity.nvidia\.com/gpu,READY:.status.conditions[?(@.type=="Ready")].status' \
  2>/dev/null | grep -v '<none>' || echo "(无 GPU 节点)"

echo ""
echo "=== 2. GPU 节点 Label（型号/MIG）==="
kubectl get nodes -o json 2>/dev/null | python3 -c "
import json, sys
for n in json.load(sys.stdin)['items']:
    gpu = n.get('status',{}).get('allocatable',{}).get('nvidia.com/gpu')
    if not gpu:
        mig = {k:v for k,v in n.get('status',{}).get('allocatable',{}).items() if 'mig' in k}
        if not mig: continue
        gpu = str(mig)
    product = n['metadata'].get('labels',{}).get('nvidia.com/gpu.product','?')
    tide = n['metadata'].get('labels',{}).get('kubeflow.io/gpu-tide-phase','-')
    print(f\"  {n['metadata']['name']:40s} gpu={gpu:>4s}  {product:30s}  tide={tide}\")
" 2>/dev/null || echo "(跳过)"

echo ""
echo "=== 3. Pending GPU Pod ==="
PENDING=$(kubectl get pods -A --field-selector=status.phase=Pending -o json 2>/dev/null \
  | python3 -c "
import json, sys
pods = json.load(sys.stdin)['items']
gpu_pending = []
for p in pods:
    for c in p['spec'].get('containers',[]):
        if 'nvidia.com/gpu' in c.get('resources',{}).get('limits',{}):
            gpu_pending.append(f\"  {p['metadata']['namespace']}/{p['metadata']['name']}\")
            break
        for k in c.get('resources',{}).get('limits',{}):
            if 'nvidia.com' in k and 'gpu' in k or 'mig' in k:
                gpu_pending.append(f\"  {p['metadata']['namespace']}/{p['metadata']['name']}\")
                break
print('\n'.join(gpu_pending) if gpu_pending else '  (无)')
" 2>/dev/null)
echo "$PENDING"

echo ""
echo "=== 4. Device Plugin 状态 ==="
kubectl get pods -A 2>/dev/null | grep -iE 'device-plugin|gpu-feature|dcgm' | head -10 || echo "(未找到)"

echo ""
echo "=== 5. GPUTide 相关 ==="
kubectl get gputidepolicy -A 2>/dev/null || echo "  (无 GPUTidePolicy CRD 或未部署)"
kubectl get nodes -l 'kubeflow.io/gpu-tide-phase' -o custom-columns=\
'NAME:.metadata.name,PHASE:.metadata.labels.kubeflow\.io/gpu-tide-phase' 2>/dev/null || true

echo ""
echo "=== 6. 调度失败 Events 采样（最近 Pending Pod）==="
FIRST_PENDING=$(kubectl get pods -A --field-selector=status.phase=Pending -o jsonpath='{.items[0].metadata.namespace}/{.items[0].metadata.name}' 2>/dev/null || true)
if [[ -n "$FIRST_PENDING" && "$FIRST_PENDING" != "/" ]]; then
  NS="${FIRST_PENDING%%/*}"
  POD="${FIRST_PENDING##*/}"
  kubectl describe pod -n "$NS" "$POD" 2>/dev/null | sed -n '/Events:/,$p' | tail -5
else
  echo "  (无 Pending Pod)"
fi

echo ""
echo "========================================"
echo "  巡检完成"
echo "========================================"
