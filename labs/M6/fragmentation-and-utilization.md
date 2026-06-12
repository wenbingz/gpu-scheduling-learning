# Lab 6B: 碎片与利用率分析

## 碎片问题

### 场景

```
节点 A (8 GPU): [1][1][1][1][1][1][1][ ]  → 7/8 allocated
节点 B (8 GPU): [ ][ ][ ][ ][ ][ ][ ][ ]  → 0/8 allocated

8 卡 Job 请求 gpu:8:
  节点 A: Insufficient (只剩 1)
  节点 B: 可以！但 scheduler 可能已把 1 卡 Pod 分散到多节点
```

### 诊断命令

```bash
# 每个 GPU 节点的分配情况
kubectl describe nodes | grep -E 'Name:|nvidia.com/gpu' | paste - -

# 找「有卡但不够大 Job」的节点
kubectl get nodes -o json | python3 -c "
import json, sys
for n in json.load(sys.stdin)['items']:
    a = n.get('status',{}).get('allocatable',{}).get('nvidia.com/gpu')
    if not a: continue
    # 需要配合 describe 看 allocated，此处仅列 allocatable
    print(n['metadata']['name'], 'allocatable=', a)
"
```

### 治理手段

1. **Bin Packing Score Plugin**（M4）— 优先填满
2. **Kueue 限流**（M5）— 限制小 Job 并发
3. **Descheduler** — 驱逐可迁移的小 Pod
4. **节点预留** — `dedicated=training:NoSchedule` taint

---

## 利用率 vs 分配率

| 指标 | 含义 | 数据来源 |
|------|------|----------|
| **分配率** | GPU 被 Pod 占用的比例 | K8s Node allocatable/allocated |
| **利用率** | GPU 实际算力使用比例 | DCGM `GPU_UTIL` |

### 差距示例

```
分配率: 95%  (集群 1000 卡，950 卡有 Pod)
利用率: 35%  (950 卡中平均只用 35% 算力)
→ 浪费: 950 × 65% ≈ 617 卡当量的算力空闲
```

### gtspot 报表思路

```
supply_24h  → 物理队列配额（Megatron 层）
usage_24h   → 实际使用
利用率 = usage / supply

低利用率队列 → 潮汐出借候选（GPUTide）
```

### DCGM 关键指标

| 指标 | 含义 |
|------|------|
| `DCGM_FI_DEV_GPU_UTIL` | GPU 算力利用率 |
| `DCGM_FI_DEV_MEM_COPY_UTIL` | 显存带宽利用率 |
| `DCGM_FI_DEV_FB_USED` | 显存使用量 |
| `DCGM_FI_DEV_XID_ERRORS` | GPU 硬件错误 |
