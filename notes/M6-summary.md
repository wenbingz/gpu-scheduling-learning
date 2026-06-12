# M6 学习总结

## 日期

2026-06-11

## 专题学习记录

### 6.1 拓扑感知

- NFD + GFD 提供节点 label（型号、卡数、显存）
- 多卡训练: podAffinity 保证同节点；NVLink domain 需自定义 Score Plugin
- nodeSelector 选 GPU 型号是硬约束（Filter 阶段）

### 6.2 碎片整理

- 根因: 标准 scheduler 逐 Pod 调度，7×1 卡占满 → 8 卡 Job Pending
- 治理: Bin Packing Score (M4) + Volcano Gang (M5) + Descheduler + Kueue 限流
- 不是没 GPU，是「凑不齐 N 张在同一节点」

### 6.3 GPUTide 潮汐

- tideByNode: 整机出借/回收，打 label + taint
- tideByPod: 按 Pod label 精细驱逐
- 状态机: selected-to-lend → lend-evicting → lending → reclaim-evicting → 恢复
- scheduler 不感知 GPUTide，只看 Node 当前 taint/allocatable
- 与 Megatron 物理队列联动: 出借期 supply 下降，gtspot 可见

### 6.4 可观测性

- **分配率** (K8s allocated/allocatable) ≠ **利用率** (DCGM GPU_UTIL)
- 低利用率 → 潮汐出借候选
- Pending 根因: Insufficient / nodeSelector / affinity / spread / Gang

### 6.5 DRA

- Extended Resource + Device Plugin 是当前主流
- DRA + ResourceClaim 是演进方向，调度阶段可感知设备属性

## 毕业自测

- [x] Pod 到 GPU 进程的完整路径 (M1+M2)
- [x] GPU 共享五种方案及选型 (M3)
- [x] podAffinity vs Volcano Gang 区别 (M4+M5)
- [x] 分配率 vs 利用率 (M6)
- [x] GPUTide 出借/回收状态机 (M6)

## 生产实践计划

- BOE 集群定期跑 `gpu-cluster-health-check.sh` 巡检
- 大 Job 提交前检查队列 Gang 配置（Volcano PodGroup）
- 关注 gtspot 低利用率队列，理解 GPUTide 出借逻辑
- 推理混部场景评估 MIG vs Time-Slicing 取舍

## 六模块知识图谱

```
M1 调度链路:  scheduler Filter → Bind → kubelet
M2 设备分配:  Device Plugin ListAndWatch/Allocate → CDI/env
M3 共享切分:  整卡/MIG/Time-Slicing/HAMi/MPS
M4 调度扩展:  affinity/spread/Score Plugin/Bin Pack
M5 批调度:    Volcano Gang + Kueue 队列
M6 生产专题:  GPUTide/碎片/可观测性/DRA
```

**🎓 GPU 调度 6 周学习计划 — 全部完成**
