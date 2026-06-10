# M3 Labs: GPU 共享与切分

## Lab 3C: KWOK 模拟（本地 kind，推荐先做）

```bash
kubectl config use-context kind-gpu-learning
kubectl apply -f labs/M3/kwok-sharing-scenarios.yaml
sleep 5
kubectl get pods -o wide
kubectl get nodes -o custom-columns='NAME:.metadata.name,GPU:.status.allocatable.nvidia\.com/gpu,MIG:.status.allocatable.nvidia\.com/mig-1g\.5gb,TS:.metadata.labels.gpu-sharing'
./labs/M1/debug-commands.sh gpu-whole gpu-timeslice-1 gpu-timeslice-2 gpu-mig-slice
```

### 预期结果

| Pod | 调度到 | 请求资源 | 说明 |
|-----|--------|----------|------|
| gpu-whole | fake-gpu-node-* | `gpu: 1` | 整卡调度 |
| gpu-timeslice-1 | fake-gpu-node-timeslice | `gpu: 1` | 虚拟 16 卡中的 1 个 |
| gpu-timeslice-2 | fake-gpu-node-timeslice | `gpu: 1` | 同节点再占 1 虚拟卡 |
| gpu-mig-slice | fake-gpu-node-mig | `mig-1g.5gb: 1` | MIG slice 调度 |

### 观察要点

- Time-Slicing 节点上 2 个 Pod 都调度成功 → scheduler 只看数量
- MIG 节点 `nvidia.com/gpu: 0`，只有 `mig-1g.5gb` → 整卡 Pod 无法调度到此节点
- 请求 `gpu: 1` 的 Pod 无法调度到 MIG 节点（资源名不匹配）

## Lab 3A: Time-Slicing 配置（需真实 GPU 节点）

```bash
kubectl apply -f labs/M3/time-slicing-config.yaml
kubectl rollout restart ds/nvidia-device-plugin-daemonset -n kube-system
# 对比前后 allocatable GPU 数量
```

## Lab 3B: MIG 观察（需 A100+ 节点）

```bash
./labs/M3/inspect-mig.sh <gpu-node>
```
