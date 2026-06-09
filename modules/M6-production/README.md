# M6: 生产级专题（预览）

## 专题清单（按需选做）

### 6.1 GPU 拓扑感知
- NVLink / NVSwitch domain 检测
- NFD + GFD label 体系
- 多卡训练 Pod 的 anti-affinity 设计

### 6.2 碎片整理
- 8 卡节点跑了 7 个 1 卡 Pod → 8 卡 Job 无法调度
- Bin Packing vs Spread 策略
- Descheduler 重调度

### 6.3 潮汐 / Spot 调度
- 参考你司 `GPUTidePolicy` CRD 设计
- 出借/回收状态机：`lend-evicting → lending → reclaim-evicting`
- 与 Cluster Autoscaler 联动

### 6.4 可观测性
- DCGM Exporter → Prometheus → Grafana
- GPU 利用率 vs 分配率（gtspot 报表思路）
- 调度失败根因分类

### 6.5 DRA 与未来
- ResourceClaim / ResourceClass
- NVIDIA DRA driver 进展

---

M5 完成后解锁，可按生产痛点选专题深潜。
