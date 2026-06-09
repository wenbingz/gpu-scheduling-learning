# M3: GPU 共享与切分（预览）

## 策略对比（M3 核心表格）

| 方案 | 隔离性 | 调度粒度 | K8s 资源名 | 适用场景 |
|------|--------|----------|------------|----------|
| 整卡 | 强 | 1 GPU | `nvidia.com/gpu` | 大模型训练 |
| MIG | 硬件级 | 1g.5gb 等 | `nvidia.com/mig-1g.5gb` | 推理混部 |
| Time-Slicing | 弱 | 虚拟多份 | 同名 resource | 轻量推理 |
| MPS | 中 | 共享上下文 | 需 sidecar | CUDA 小 kernel |
| HAMi/vGPU | 软 | 显存%/算力% | `nvidia.com/gpumem` | 国内云常见 |

## M3 关键问题

- 为什么 Time-Slicing **不能** 解决显存隔离？
- MIG 变更为什么需要 drain 节点？
- 混部时 scheduler 如何防止 GPU 显存 OOM？

---

M2 完成后解锁。
