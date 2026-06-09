# M5: 批调度 & 队列（预览）

## 为什么需要 Volcano / Kueue

标准 kube-scheduler 的局限：

| 需求 | 标准 Scheduler | Volcano / Kueue |
|------|----------------|-----------------|
| Gang Scheduling (All-or-Nothing) | ❌ | ✅ |
| Queue / Priority 配额 | 仅 PriorityClass | ✅ 完整队列 |
| Preemption 策略 | 基础 | 可定制 |
| Job 级调度 | ❌ | ✅ PodGroup |

## 核心 CRD

```yaml
# Volcano PodGroup — 4 卡训练任务必须同时调度
apiVersion: scheduling.volcano.sh/v1beta1
kind: PodGroup
metadata:
  name: llm-train-7b
spec:
  minMember: 4        # 至少 4 个 Pod 同时 Running
  queue: gpu-training
```

## 与 Megatron / 内部队列的关系

- **Kueue/Volcano**: K8s 层队列与 Gang 语义
- **Megatron 物理队列**: 集群级 CPU/Memory/GPU 配额（更上层）
- **GPUTide**: 潮汐出借/回收（你司 kubeflow-api 中的 CRD）

---

M4 完成后解锁。
