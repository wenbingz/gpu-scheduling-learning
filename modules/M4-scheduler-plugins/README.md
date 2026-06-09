# M4: 调度器扩展（预览）

## 你将实现

一个最小 **GPU Topology Score Plugin**：

```go
// 伪代码
func Score(ctx, state, pod, node) int64 {
    if podNeedsMultiGPU(pod) {
        // 偏好 NVLink 全连接 domain 内的节点
        return scoreByNVLinkTopology(node, pod.Spec.Resources)
    }
    return 0
}
```

## 涉及 K8s 机制

- Scheduling Framework (Filter / Score / Reserve / PreBind)
- Scheduler Extender（遗留，了解即可）
- DRA (Dynamic Resource Allocation) 1.26+

## Lab

- 用 `kube-scheduler-simulator` 或 kind 二次调度验证

---

M3 完成后解锁。
