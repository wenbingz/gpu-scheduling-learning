# M5 Labs: 批调度 & Gang Scheduling

## Lab 5A: Gang 问题复现（推荐，kind 即可）

```bash
kubectl config use-context kind-gpu-learning
kubectl apply -f labs/M5/gang-problem-demo.yaml
sleep 8
./labs/M5/observe-gang-problem.sh
```

**预期**:
- 7 个 inference-blocker Pod Running（占 7 卡）
- 8 个 train-gang-worker 中只有 1 个 Running，7 个 Pending
- 证明标准 scheduler **部分调度**，训练会 hang

## Lab 5B: Volcano（需安装）

```bash
kubectl apply -f https://raw.githubusercontent.com/volcano-sh/volcano/master/installer/volcano-development.yaml
kubectl apply -f labs/M5/volcano-gang-job.yaml
kubectl get podgroup,queue,vcjob
```

## Lab 5C: 对比

```bash
./labs/M5/compare-schedulers.sh
```
