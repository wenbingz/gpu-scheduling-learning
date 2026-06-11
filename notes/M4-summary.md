# M4 学习总结

## 日期

2026-06-09

## Scheduling Framework 理解

- **Filter**：排除不满足条件的节点（`NodeResourcesFit` 检查 GPU 数量）
- **Score**：给通过 Filter 的节点打分，选最优
- **Reserve/PreBind/Bind**：绑定节点，Device Plugin Allocate

标准 scheduler 对 GPU 只在 Filter 阶段检查 `nvidia.com/gpu` 数量，不看型号/拓扑/显存。

## 三层扩展手段

| 层级 | 手段 | 改 scheduler？ |
|------|------|---------------|
| Layer 1 | nodeSelector / podAffinity / topologySpread | ❌ 原生 |
| Layer 2 | 自定义 Score Plugin（Bin Pack / 拓扑） | ✅ |
| Layer 3 | Volcano / Kueue | 替换/扩展 |

## Lab 观察记录

### podAffinity 同节点 (train-worker-0/1)

- `train-worker-0` 先调度到 `fake-gpu-node-nvlink-0`
- `train-worker-1` 通过 podAffinity 跟随到**同一节点**
- 各 2 卡，节点 allocated gpu 4/8
- 注意：双向 required podAffinity 会导致死锁，应让 worker-0 先调度、worker-1 跟随

### topologySpread 分散 (inference-0/1/2)

- 3 个 inference Pod 分散到 3 个不同节点
- 由原生 `PodTopologySpread` 插件实现（Filter + Score）
- KWOK 节点需手动打 `kubernetes.io/hostname` label

### Score Plugin 骨架

- **binpack**：剩余 GPU 越少 score 越高 → 减少碎片
- **spread**：剩余 GPU 越多 score 越高 → 推理分散
- **topology**：多卡 Pod 偏好有 NVLink domain label 的节点

## 三个思考题答案

**Q1: 8 个 1 卡 Pod 调度后，8 卡 Job Pending？**

标准 scheduler 逐 Pod 独立调度，不做全局规划。7 个 1 卡占满后，剩余不够 8 卡 Job。需 Bin Packing 或 Gang Scheduling（M5）。

**Q2: nodeSelector vs Score Plugin？**

nodeSelector 是硬约束（Filter，不满足直接排除）；Score Plugin 是软偏好（多个节点都满足时选分高的）。

**Q3: Volcano vs 自定义 Plugin？**

Gang/Queue/Preemption → Volcano（M5）；只需拓扑/Bin Pack → 自定义 Score 或 Volcano gpu-topology。

## 遗留问题（带入 M5）

- 8 卡 Job 必须 8 Pod 同时调度 → Gang Scheduling
- 队列配额、优先级抢占 → Volcano / Kueue
