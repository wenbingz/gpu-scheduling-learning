#!/usr/bin/env bash
# Lab 3B: 检查节点 MIG 配置与资源上报
set -euo pipefail

NODE="${1:-}"

echo "=== 1. MIG-capable 节点 ==="
kubectl get nodes -l nvidia.com/mig.capable=true \
  -o custom-columns='NAME:.metadata.name,MIG:.metadata.labels.nvidia\.com/mig\.strategy,GPU:.status.allocatable.nvidia\.com/gpu' 2>/dev/null \
  || echo "(无 MIG capable 节点)"

echo ""
echo "=== 2. MIG 资源类型 ==="
kubectl get nodes -o json 2>/dev/null \
  | python3 -c "
import json, sys
types = set()
for n in json.load(sys.stdin)['items']:
    for k, v in n.get('status',{}).get('allocatable',{}).items():
        if 'mig' in k:
            types.add(f'{k}={v}')
for t in sorted(types): print(f'  {t}')
if not types: print('  (无 MIG 资源)')
"

echo ""
echo "=== 3. mig-manager Pod ==="
kubectl get pods -A 2>/dev/null | grep -i mig-manager || echo "(未部署 mig-manager)"

if [[ -n "$NODE" ]]; then
  echo ""
  echo "=== 4. 节点 $NODE MIG 详情 ==="
  kubectl describe node "$NODE" 2>/dev/null | grep -iE 'mig|nvidia.com' || true
fi

echo ""
echo "=== 5. MIG ConfigMap ==="
kubectl get cm -A 2>/dev/null | grep -i mig || echo "(无 MIG ConfigMap)"
