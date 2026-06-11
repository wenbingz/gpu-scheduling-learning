// Lab 4D: GPU Topology Score Plugin 骨架（教学用，非可运行插件）
//
// 展示如何实现一个 Scheduler Framework Score 插件
// 真实部署需编译为 kube-scheduler 插件或使用 SchedulerPlugins 项目
//
// 参考: https://github.com/kubernetes-sigs/scheduler-plugins

package gputopology

import (
	"context"

	v1 "k8s.io/api/core/v1"
	"k8s.io/klog/v2"
	"k8s.io/kubernetes/pkg/scheduler/framework"
)

const Name = "GPUTopologyScore"

// GPUTopologyScore 实现 framework.ScorePlugin
type GPUTopologyScore struct {
	handle framework.Handle
	// strategy: "binpack" | "spread" | "topology"
	strategy string
}

var _ framework.ScorePlugin = &GPUTopologyScore{}

func New(_ context.Context, _ interface{}, handle framework.Handle) (framework.Plugin, error) {
	return &GPUTopologyScore{handle: handle, strategy: "binpack"}, nil
}

func (pl *GPUTopologyScore) Name() string { return Name }

// Score 给每个节点打分
func (pl *GPUTopologyScore) Score(ctx context.Context, state *framework.CycleState,
	pod *v1.Pod, nodeName string) (int64, *framework.Status) {

	gpuReq := gpuRequest(pod)
	if gpuReq == 0 {
		return 0, nil
	}

	nodeInfo, err := pl.handle.SnapshotSharedLister().NodeInfos().Get(nodeName)
	if err != nil {
		return 0, framework.AsStatus(err)
	}

	node := nodeInfo.Node()
	free := freeGPU(node)

	switch pl.strategy {
	case "binpack":
		// 剩余 GPU 越少分越高 → 优先填满节点，减少碎片
		// 8 卡节点剩 2 卡 → score=6; 剩 8 卡 → score=0
		klog.V(4).InfoS("binpack score", "node", nodeName, "free", free, "score", 8-free)
		return int64(8 - free), nil

	case "spread":
		// 剩余 GPU 越多分越高 → 推理服务分散
		return int64(free), nil

	case "topology":
		// 多卡 Pod 偏好有 NVLink domain label 且剩余足够的节点
		if gpuReq > 1 && node.Labels["nvlink.com/domain"] != "" && free >= gpuReq {
			return 100, nil
		}
	}

	return 0, nil
}

func (pl *GPUTopologyScore) ScoreExtensions() framework.ScoreExtensions {
	return nil
}

// --- helpers ---

func gpuRequest(pod *v1.Pod) int64 {
	var total int64
	for _, c := range pod.Spec.Containers {
		if q, ok := c.Resources.Limits["nvidia.com/gpu"]; ok {
			total += q.Value()
		}
	}
	return total
}

func freeGPU(node *v1.Node) int64 {
	allocatable := node.Status.Allocatable["nvidia.com/gpu"]
	// 真实实现需从 NodeInfo 读已分配量
	_ = allocatable
	return 8 // simplified
}

// Score 结果如何影响调度:
//
// 假设 3 个节点都通过 Filter (GPU 够):
//   node-A: free=2 → binpack score=6  ← 选中
//   node-B: free=8 → binpack score=0
//   node-C: free=5 → binpack score=3
//
// scheduler 选 score 最高的 node-A → 2 卡 Pod 调度到只剩 2 卡的节点
// → 大 Job 到来时 node-B/node-C 仍有整节点空闲
