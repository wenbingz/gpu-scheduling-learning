# M1 学习总结

## 日期

2026-06-09

## 实验环境

- 集群: kind `gpu-learning` (K8s v1.36.1)
- GPU 模拟: KWOK fake nodes (无真实 Device Plugin)
- 节点:
  - `fake-gpu-node-0`: A100-SXM4-80GB, 8 GPU
  - `fake-gpu-node-1`: T4, 4 GPU

## 调度链路（用自己的话）

1. **API Server 接收 Pod** → 写入 etcd，Pod 进入 Pending，触发 scheduler 工作队列
2. **kube-scheduler Filter** → `NodeResourcesFit` 检查每个节点 `allocatable.nvidia.com/gpu` 是否 ≥ Pod requests；同时检查 nodeSelector、taint/toleration
3. **kube-scheduler Score + Bind** → 对通过 Filter 的节点打分，写入 `pod.spec.nodeName`
4. **（真实集群）kubelet → Device Plugin.Allocate()** → 注入 GPU 设备；KWOK 环境由 stage-fast 直接将 Pod 置为 Running
5. **（真实集群）容器内可见 `NVIDIA_VISIBLE_DEVICES`** → KWOK 环境无此步骤

## Lab 观察记录

### Pod Events 关键信息

| Pod | 请求 GPU | 调度结果 | 关键 Event |
|-----|----------|----------|------------|
| `gpu-test` | 1 | fake-gpu-node-1 (T4) | `Successfully assigned` |
| `gpu-test-a100` | 2 + A100 selector | fake-gpu-node-0 (A100) | `Successfully assigned` |
| `gpu-test-oom-schedule` | 16 | 未调度 | `Insufficient nvidia.com/gpu` + `Preemption is not helpful` |

### 节点 GPU 分配后状态

- `fake-gpu-node-1`: allocatable 4 → allocated 1/4（gpu-test）
- `fake-gpu-node-0`: allocatable 8 → allocated 2/8（gpu-test-a100）

### Device Plugin 位置

KWOK 环境无 Device Plugin Pod（预期）。真实集群应在 `kube-system` 查找 `nvidia-device-plugin-daemonset`。

### NVIDIA_VISIBLE_DEVICES 值

KWOK 环境跳过（无真实 GPU 注入）。这是 L0 环境与真实集群的核心差异点。

## 三个思考题答案

**Q1: 为什么 GPU 用 Extended Resource 而不是 DRA？**

Extended Resource 是早期方案，生态成熟（NVIDIA Device Plugin 广泛部署），整数粒度简单。
DRA (1.26+) 支持更细粒度分配，但 NVIDIA 生产环境仍以 Device Plugin 为主，DRA 在逐步演进。

**Q2: 两个 1 卡 Pod 如何保证在同一 NVLink domain？**

标准 scheduler 不能保证。需要 NFD+GFD 打拓扑 label + 自定义 Scheduler Plugin，
或 Volcano GPU topology policy，或用 pod affinity 约束到同一节点/拓扑域。

**Q3: Allocate 失败时 Pod 会怎样？**

kubelet SyncLoop 重试 Allocate；持续失败则 Pod 卡在 ContainerCreating，
Events 可见 device plugin 错误。与本次「调度阶段 Insufficient」不同——那是 scheduler 阶段就拒绝了。

## 遗留问题（带入 M2）

- Device Plugin 的 ListAndWatch / Allocate 具体实现
- Allocate 之后 CDI vs env 注入方式差异
- 真实集群上验证 `NVIDIA_VISIBLE_DEVICES` 和 nvidia-smi
