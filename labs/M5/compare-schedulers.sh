#!/usr/bin/env bash
# Lab 5C: 对比标准 scheduler vs Volcano vs Kueue
set -euo pipefail

echo "=== 标准 kube-scheduler ==="
kubectl get pods -n kube-system -l component=kube-scheduler -o wide 2>/dev/null \
  || kubectl get pods -A | grep scheduler | head -3

echo ""
echo "=== Volcano ==="
if kubectl get ns volcano-system &>/dev/null; then
  kubectl get pods -n volcano-system
  kubectl get queue,podgroup 2>/dev/null || true
else
  echo "  未安装 Volcano"
  echo "  安装: kubectl apply -f https://raw.githubusercontent.com/volcano-sh/volcano/master/installer/volcano-development.yaml"
fi

echo ""
echo "=== Kueue ==="
if kubectl get crd clusterqueues.kueue.x-k8s.io &>/dev/null; then
  kubectl get clusterqueue,localqueue -A 2>/dev/null || true
else
  echo "  未安装 Kueue"
  echo "  安装: kubectl apply --server-side -f https://github.com/kubernetes-sigs/kueue/releases/download/v0.10.0/manifests.yaml"
fi

echo ""
echo "=== 对比 ==="
printf "%-20s %-15s %-15s\n" "能力" "Volcano" "Kueue"
printf "%-20s %-15s %-15s\n" "Gang Scheduling" "✅ PodGroup" "✅ Workload"
printf "%-20s %-15s %-15s\n" "队列配额" "✅ Queue" "✅ ClusterQueue"
printf "%-20s %-15s %-15s\n" "替换 scheduler" "✅" "❌ 增量"
printf "%-20s %-15s %-15s\n" "MPIJob/PyTorchJob" "✅ 原生" "⚠️ 需 JobSet"
