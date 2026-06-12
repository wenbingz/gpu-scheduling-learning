# GPU 调度速查表

> M1-M6 知识浓缩

## 调度全链路

```
Pod 创建 → scheduler Filter/Score → Bind Node
  → kubelet → Device Plugin Allocate → env/CDI
  → nvidia-container-runtime → 容器内 GPU 可用
```

## 关键组件

| 组件 | 职责 |
|------|------|
| kube-scheduler | 选节点（GPU 数量） |
| Device Plugin | 发现 GPU、Allocate 注入 |
| nvidia-container-runtime | 容器设备注入 |
| GFD | 节点 GPU label |
| Volcano/Kueue | Gang + 队列 |
| GPUTide | 潮汐出借/回收 |

## 资源名

| 资源 | 含义 |
|------|------|
| `nvidia.com/gpu` | 整卡 |
| `nvidia.com/mig-1g.5gb` | MIG slice |
| `nvidia.com/gpumem` | HAMi 显存 |

## 共享方案选型

| 场景 | 方案 |
|------|------|
| 大模型训练 | 整卡 |
| 推理混部 (A100+) | MIG |
| 轻量推理 | Time-Slicing |
| 灵活显存切分 | HAMi/vGPU |

## 调度约束选型

| 需求 | 手段 |
|------|------|
| 选 GPU 型号 | nodeSelector |
| 多 Pod 同节点 | podAffinity |
| 推理分散 | topologySpreadConstraints |
| 8 卡同时调度 | Volcano PodGroup |
| 队列配额 | Kueue ClusterQueue |
| 减碎片 | Bin Packing Score Plugin |

## 排查 Pending

```bash
kubectl describe pod <name> | grep -A5 Events
# Insufficient nvidia.com/gpu  → 资源不足/碎片
# didn't match node selector   → 型号/label
# didn't match pod affinity    → 亲和约束
# didn't match topology spread → 分散约束
```

## 巡检

```bash
./labs/M6/gpu-cluster-health-check.sh
./labs/M2/inspect-device-plugin.sh
./labs/M2/inspect-gpu-labels.sh
```
