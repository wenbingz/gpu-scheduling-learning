# M3 学习总结

## 日期

2026-06-09

## 五种方案对比（用自己的话）

| 方案 | 核心机制 | 隔离 |
|------|----------|------|
| 整卡 | 1 Pod 占 1 个 `nvidia.com/gpu` | 强 |
| Time-Slicing | DP 把 1 物理卡虚报成 N 份同名 resource | 无 |
| MIG | 硬件切成 slice，上报 `nvidia.com/mig-*` | 硬件级 |
| MPS | scheduler 仍整卡，CUDA runtime 共享 | 中 |
| HAMi/vGPU | 第三方 DP 上报显存/算力 fraction | 软 |

## Lab 观察记录

### 整卡 (gpu-whole)

- 节点: fake-gpu-node-1 (T4, allocatable gpu=4)
- allocated: gpu 2/4（gpu-whole + gpu-test）
- 结论: 标准整卡调度，1 请求占 1 个 gpu 计数

### Time-Slicing (gpu-timeslice-1/2)

- 节点: fake-gpu-node-timeslice (allocatable **gpu=16**，模拟 4 物理×4 replicas)
- 两个 Pod 同节点，各请求 gpu:1，均 Running
- allocated: gpu 2/16
- 结论: scheduler 只看数量，不知道 16 是虚报的；多 Pod 可调度到「同一张物理卡」

### MIG (gpu-mig-slice)

- 节点: fake-gpu-node-mig (A100)
  - `nvidia.com/gpu: 0` — 整卡不报
  - `nvidia.com/mig-1g.5gb: 7`
- allocated: mig 1/7, gpu 0/0
- 结论: 请求 `mig-1g.5gb:1` 的 Pod 只能上 MIG 节点；请求 `gpu:1` 的 Pod 无法上此节点

## 三个思考题答案

**Q1: Time-Slicing 为什么不能解决显存隔离？**

只在 DP 层复制虚拟 Device ID，Allocate 时多 Pod 仍指向同一物理卡；无 NVML/CUDA 层显存限制。

**Q2: MIG 变更为什么需要 drain？**

MIG 是硬件级重构，需杀掉 GPU 进程、重配实例、DP 重新 ListAndWatch；运行中 Pod 会丢卡。

**Q3: scheduler 如何防止 GPU 显存 OOM？**

标准 scheduler 不能。靠 MIG 硬限制、HAMi 软限制，或监控告警。

## 生产选型（你的场景会怎么选）

- 训练: 整卡
- 推理混部 (A100+): MIG
- 轻量推理、可接受风险: Time-Slicing
- 灵活显存切分: HAMi/vGPU

## 遗留问题（带入 M4）

- 多卡训练如何保证 NVLink 拓扑？→ Scheduler Plugin
- 8 卡节点 7 个 1 卡 Pod 导致 8 卡 Job 无法调度？→ 碎片与 Bin Packing
