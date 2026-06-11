# M4 Labs: 调度器扩展

## Lab 4A: podAffinity 同节点（推荐先做）

```bash
kubectl config use-context kind-gpu-learning
kubectl apply -f labs/M4/kwok-topology-nodes.yaml
kubectl apply -f labs/M4/multi-gpu-pod-affinity.yaml
sleep 5
kubectl get pods -o wide -l job=llm-train
./labs/M1/debug-commands.sh train-worker-0 train-worker-1
```

**预期**: `train-worker-0` 和 `train-worker-1` 调度到**同一节点**（podAffinity + 各 2 卡 = 共 4 卡）。

## Lab 4B: topologySpread 分散

```bash
kubectl apply -f labs/M4/inference-spread.yaml
kubectl get pods -o wide -l app=inference
```

**预期**: `inference-0/1/2` 尽量分散到不同节点（maxSkew=1）。

## Lab 4C: 读 scheduler 源码

```bash
./labs/M4/read-scheduler-plugins.sh
```

## Lab 4D: Score Plugin 骨架

```bash
cat labs/M4/gpu-topology-score-plugin-skeleton.go
```

重点理解 `binpack` 策略如何减少 GPU 碎片。
