# L0: kind + KWOK 本地 GPU 调度实验环境

> 成本 ¥0 · 无需真实 GPU · 覆盖 M1 调度逻辑

## 前置条件

- kind 集群: `kind-gpu-learning`
- kubectl context: `kind-gpu-learning`

## 一键搭建

```bash
./labs/L0-kind-kwok/setup.sh
```

## 手动步骤

```bash
kubectl config use-context kind-gpu-learning

# 安装 KWOK
kubectl apply -f https://github.com/kubernetes-sigs/kwok/releases/download/v0.6.1/kwok.yaml
kubectl apply -f https://github.com/kubernetes-sigs/kwok/releases/download/v0.6.1/stage-fast.yaml

# 创建假 GPU 节点 (2 台: A100×8 + T4×4)
kubectl apply -f labs/L0-kind-kwok/fake-gpu-nodes.yaml
```

## 实验

```bash
# 正常调度 (1 GPU)
kubectl apply -f labs/L0-kind-kwok/gpu-pod-kwok.yaml

# 资源不足 (16 GPU > 单节点 max 8)
kubectl apply -f labs/L0-kind-kwok/gpu-pod-pending.yaml

# nodeSelector 选 A100 节点
kubectl apply -f labs/L0-kind-kwok/gpu-pod-node-selector.yaml

# 批量排查
./labs/M1/debug-commands.sh gpu-test gpu-test-a100 gpu-test-oom-schedule
```

## 预期结果

| Pod | 预期 Node | 预期状态 |
|-----|-----------|----------|
| gpu-test | fake-gpu-node-* | Running |
| gpu-test-a100 | fake-gpu-node-0 (A100) | Running |
| gpu-test-oom-schedule | — | Pending, Insufficient nvidia.com/gpu |

## 限制

- ❌ 无真实 Device Plugin / nvidia-smi
- ❌ 无 MIG / Time-Slicing
- ✅ 可学习 scheduler Filter/Score、nodeSelector、资源不足排查

## 清理

```bash
kubectl delete -f labs/L0-kind-kwok/ --ignore-not-found
kind delete cluster --name gpu-learning
colima stop   # 若使用 Colima
```
