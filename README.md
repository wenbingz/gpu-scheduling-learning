# GPU 调度深度学习计划

> 面向资深 K8s 专家 · 6 周 · 理论 + 实验 + 源码  
> 仓库：<https://github.com/wenbingz/gpu-scheduling-learning>

## 你的起点

- ✅ K8s 调度器、Device Plugin、Extended Resource 基础概念
- ✅ CUDA 执行模型（已有 `cuda-learning` 笔记）
- 🔲 GPU 在 K8s 中的完整调度链路
- 🔲 GPU 共享/切分策略的工程取舍
- 🔲 批调度、拓扑感知、潮汐/Spot 调度

## 学习路径总览

| 阶段 | 主题 | 时长 | 产出 |
|------|------|------|------|
| **M1** | GPU 调度全链路 | 3-4 天 | 能画出 Pod→GPU 完整路径 |
| **M2** | Device Plugin & Operator | 4-5 天 | 本地跑通 NVIDIA Device Plugin |
| **M3** | GPU 共享与切分 | 5-7 天 | MIG / Time-Slicing / vGPU 对比表 |
| **M4** | 调度器扩展 | 5-7 天 | 写一个 Filter/Score Plugin |
| **M5** | 批调度 & 队列 | 5-7 天 | Volcano/Kueue Gang Scheduling 实验 |
| **M6** | 生产级专题 | 持续 | 拓扑、碎片、潮汐、可观测性 |

## 目录结构

```
gpu-scheduling-learning/
├── README.md                 # 本文件
├── modules/
│   ├── M1-scheduling-path/ # 调度全链路
│   ├── M2-device-plugin/
│   ├── M3-gpu-sharing/
│   ├── M4-scheduler-plugins/
│   ├── M5-batch-scheduling/
│   └── M6-production/
├── labs/                     # 可复现实验
└── notes/                    # 你的学习笔记
```

## 当前进度

见 [PROGRESS.md](./PROGRESS.md)

- [x] M1: GPU 调度全链路
- [x] M2: Device Plugin & Operator
- [ ] M2: Device Plugin & Operator
- [ ] M3: GPU 共享与切分
- [ ] M4: 调度器扩展
- [ ] M5: 批调度 & 队列
- [ ] M6: 生产级专题

## 实验环境选项

| 环境 | 适用模块 | 说明 |
|------|----------|------|
| **公司 GPU 集群** | M1-M6 全部 | 最真实，优先 |
| **本地 kind + GPU** | M2-M4 | 需要 NVIDIA Container Toolkit |
| **CPU 模拟** | M1, M4 部分 | 无 GPU 也能理解调度逻辑 |

## 如何使用本仓库

1. 按 `modules/Mx-*/README.md` 顺序学习
2. 每完成一模块，在 `notes/` 写 1 页总结
3. 实验记录在对应 `labs/` 子目录
4. 回复 AI 助手 **"完成 M1"** 或 **"继续 M2"** 进入下一模块
