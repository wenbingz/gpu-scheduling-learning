# M5 学习总结

## 日期

2026-06-11

## Gang Scheduling 理解

标准 kube-scheduler **逐 Pod 独立调度**，无法保证 Job 内多个 Pod 同时 Running。

```
8 卡节点 + 7 个推理 Pod 各占 1 卡
→ 8 卡训练 Job 提交
→ 只能调度 1/8 个 worker
→ AllReduce hang（等不齐 8 个）
```

**Gang Scheduling（All-or-Nothing）**：要么 minMember 个 Pod 全部调度，要么全部 Pending。

podAffinity 不能保证「同时」——第 1 个 Pod 调度后，其余可能因资源不足 Pending。

## Volcano vs Kueue 对比

| | Volcano | Kueue |
|--|---------|-------|
| 定位 | 批调度 scheduler 替代 | 准入队列，仍用 kube-scheduler |
| Gang | PodGroup `minMember` | Workload (JobSet/Job) |
| 队列 | Queue CRD | ClusterQueue + LocalQueue |
| 生态 | MPIJob/PyTorchJob/VCJob | JobSet, Ray, 原生 Job |
| 复杂度 | 替换 scheduler | 增量安装 |

选型：
- 深度批调度 + MPIJob 生态 → Volcano
- 多租户配额 + 保留 kube-scheduler → Kueue

## Lab 观察记录

### Gang 问题复现 (Lab 5A)

- 节点 `fake-gpu-node-gang-demo`: allocatable gpu=8
- 7 个 `inference-blocker` Running → 占 7 卡
- 8 个 `train-gang-worker`: **1 Running, 7 Pending**（部分调度）
- 结论: 标准 scheduler 无法 Gang；训练 Job 会 hang

### Volcano PodGroup 关键配置

```yaml
spec:
  minMember: 8
  queue: gpu-training
  minResources:
    nvidia.com/gpu: 8
```

Pod 需 annotation: `scheduling.k8s.io/group-name: <podgroup-name>`
Job 需: `schedulerName: volcano`

## 三个思考题答案

**Q1: 为什么 Gang 不能靠 podAffinity？**

podAffinity 保证「在一起」，不保证「同时」。资源不足时部分 Pod Pending，仍是部分调度。

**Q2: Volcano vs Kueue？**

Volcano 替换 scheduler，适合训练/HPC；Kueue 做准入队列，适合多租户配额管理。可共存。

**Q3: Megatron vs Volcano Queue？**

Megatron 管物理资源池总量（集群级 CPU/Mem/GPU）；Volcano Queue 管 K8s 内 Job 排队和 Gang。Job 需同时满足两层约束。

## 与 Megatron 队列的关系

```
Megatron 物理队列  →  集群 GPU 上限（扩缩容 federationyodel）
Volcano/Kueue      →  K8s Job 排队、Gang、优先级
kube-scheduler     →  单 Pod 选节点
Device Plugin      →  分配具体 GPU
```

## 遗留问题（带入 M6）

- GPUTide 潮汐出借/回收如何与队列联动
- GPU 碎片整理与 Descheduler
- DCGM 可观测性与调度决策
