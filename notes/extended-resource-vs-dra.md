# Extended Resource vs DRA 时序对比

> 同一张 GPU Pod，两种机制下的完整路径

## 并排时序

```mermaid
sequenceDiagram
    participant User
    participant API as apiserver
    participant Sched as scheduler
    participant Kubelet
    participant DP as Device Plugin / DRA Driver
    participant RT as containerd

    rect rgb(230, 245, 255)
        Note over User,RT: Extended Resource（现在主流）
        User->>API: Pod limits: nvidia.com/gpu: 1
        API->>Sched: 入队调度
        Sched->>Sched: Filter: allocatable GPU >= 1?
        Note right of Sched: 只看数量，不看型号/拓扑
        Sched->>API: Bind nodeName
        API->>Kubelet: 下发 PodSpec
        Kubelet->>DP: Allocate(deviceIDs)
        DP->>Kubelet: env / CDI
        Kubelet->>RT: 创建容器 + 注入
    end

    rect rgb(255, 245, 230)
        Note over User,RT: DRA（K8s 1.26+，演进中）
        User->>API: ResourceClaim + Pod
        API->>Sched: 入队（Claim 未分配）
        Sched->>DP: 预留设备（CEL 选 A100/NVLink 等）
        DP->>Sched: 返回可用设备 + 节点
        Sched->>Sched: Filter/Score 含设备约束
        Sched->>API: Bind + 更新 Claim 状态
        API->>Kubelet: 下发 Pod + 已分配 Claim
        Kubelet->>RT: CDI 注入（调度前已确定设备）
    end
```

## 关键差异

| 阶段 | Extended Resource | DRA |
|------|-------------------|-----|
| Pod 声明 | `limits: nvidia.com/gpu: 1` | `ResourceClaim` + `resources.claims` |
| 设备发现 | DP → kubelet → Node status | DRA Driver → ResourceSlice |
| 调度输入 | 节点 GPU **数量** | 设备**属性**（型号、拓扑、CEL） |
| 具体哪张卡 | **调度后** Allocate 决定 | **调度中** Driver 预留 |
| 注入 | DP Allocate → env/CDI | 原生 CDI |

## 生产选型（2026）

- **现在**：Extended Resource + NVIDIA Device Plugin（M1/M2 所学）
- **新集群/强拓扑**：关注 NVIDIA k8s-dra-driver 进展
- **M3 共享**：MIG/Time-Slicing 仍在 Extended Resource 框架下扩展资源名
