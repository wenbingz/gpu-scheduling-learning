# M2: Device Plugin & GPU Operator（预览）

> M1 完成后解锁。本模块深入 Device Plugin 源码与 NVIDIA GPU Operator 部署。

## 学习目标

- 读懂 NVIDIA k8s-device-plugin 的 ListAndWatch / Allocate 实现
- 理解 GPU Operator 组件矩阵（driver, dp, gfd, mig-manager...）
- 本地 kind 集群部署 Device Plugin（有 GPU 时）

## 核心组件

```
GPU Operator
├── driver DaemonSet          # GPU 驱动（bare metal 通常预装）
├── device-plugin DaemonSet   # 上报 nvidia.com/gpu
├── gpu-feature-discovery     # 节点 label: 型号/MIG/拓扑
├── mig-manager               # MIG 分区管理
├── dcgm-exporter             # 监控
└── validator                 # 部署验证
```

## M2 Lab 预览

1. `helm install gpu-operator` 最小部署
2. 读 Device Plugin 日志，观察 ListAndWatch 推送
3. 修改 `--device-list-strategy` 对比 env vs volume-mounts vs cdi

---

回复 **"完成 M1"** 开始 M2 详细内容。
