# Lab 6C: GPUTide 状态机推演

> 基于 `kubeflow-api/pkg/apis/bytedance/v1alpha1/gputide.go`

## 两种 Policy 类型

### tideByNode — 整机出借

```
1. PreFilterLabelSelector 筛选候选节点 (GPUTideCandidate=true)
2. NodeScoringStrategy 打分（ByPodCount: Pod 少的优先出借）
3. selected-to-lend → lend-evicting（驱逐节点上所有 Pod）
4. lend-evict-finished → lending（打 LendingLabels + taint）
5. 到回收时间 → selected-to-reclaim → reclaim-evicting
6. reclaim-evict-finished → 恢复训练节点
```

### tideByPod — 按 Pod 驱逐

```
1. PodFilterLabels 匹配要驱逐的 Pod
2. PodMaxEvictionInflight 控制并发驱逐数
3. PodEvictTimeoutSeconds + PodEvictTimeoutStrategy 处理超时
```

## 状态与 Label 对照

| Phase | Label 值 | 含义 |
|-------|----------|------|
| 选中出借 | `selected-to-lend` | 节点被标记，准备驱逐 |
| 出借驱逐中 | `lend-evicting` | 正在驱逐训练 Pod |
| 出借驱逐完成 | `lend-evict-finished` | Pod 已清，等待打 label |
| 出借中 | `lending` | 节点已借出，训练 Pod 不再调度 |
| 选中回收 | `selected-to-reclaim` | 准备回收 |
| 回收驱逐中 | `reclaim-evicting` | 驱逐 Spot 负载 |
| 回收完成 | `reclaim-evict-finished` | 恢复为训练节点 |

## 与调度器的关系

```
GPUTide Controller:
  ├── 驱逐 Pod（kubectl delete / eviction API）
  ├── 修改 Node label/taint
  └── 不改 scheduler 代码

kube-scheduler:
  ├── 看到 lending 节点的 taint → 新 Pod 不调度
  └── 看到回收完成 → 恢复调度

Megatron 队列:
  └── 物理 GPU 配额在出借期可缩减（gtspot 报表可见 supply 变化）
```

## 思考题

1. 出借过程中新提交的训练 Job 会怎样？（lending taint → Pending 或调度到其他节点）
2. `forceDelete` vs `justWaiting` 驱逐策略各适合什么场景？
3. GPUTide 和 Cluster Autoscaler 如何配合？（出借节点可被 CA 缩容）
