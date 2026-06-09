#!/usr/bin/env bash
# M2 Lab: 检查 GPU Feature Discovery 产生的节点 labels
set -euo pipefail

NODE="${1:-}"

filter='nvidia\.com'

if [[ -n "$NODE" ]]; then
  echo "=== GPU Labels: $NODE ==="
  kubectl get node "$NODE" -o json \
    | python3 -c "
import json, sys
n = json.load(sys.stdin)
labels = {k:v for k,v in n['metadata'].get('labels',{}).items() if 'nvidia' in k or 'gpu' in k.lower()}
for k in sorted(labels): print(f'  {k}={labels[k]}')
alloc = {k:v for k,v in n.get('status',{}).get('allocatable',{}).items() if 'nvidia' in k or 'gpu' in k.lower()}
print('  --- allocatable ---')
for k in sorted(alloc): print(f'  {k}={alloc[k]}')
"
else
  echo "=== 所有节点的 nvidia.com labels ==="
  kubectl get nodes -o json \
    | python3 -c "
import json, sys
for n in json.load(sys.stdin)['items']:
    name = n['metadata']['name']
    labels = {k:v for k,v in n['metadata'].get('labels',{}).items() if 'nvidia' in k}
    gpu = n.get('status',{}).get('allocatable',{}).get('nvidia.com/gpu','-')
    if labels or gpu != '-':
        print(f'{name}  gpu={gpu}')
        for k in sorted(labels): print(f'  {k}={labels[k]}')
        print()
"
fi

echo "=== GFD / NFD Pods ==="
kubectl get pods -A 2>/dev/null | grep -iE 'gpu-feature-discovery|node-feature-discovery' || echo "(未找到 GFD/NFD)"
