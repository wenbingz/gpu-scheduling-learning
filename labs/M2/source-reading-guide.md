# Lab 2B: NVIDIA k8s-device-plugin 源码跟读指南

## 准备

```bash
git clone --depth=1 https://github.com/NVIDIA/k8s-device-plugin.git /tmp/k8s-device-plugin
cd /tmp/k8s-device-plugin
```

## 跟读路线（约 45 分钟）

### Stop 1: 入口 (5 min)

文件: `cmd/nvidia-device-plugin/main.go`

- 配置从哪来? (ConfigMap / flags / 默认值)
- 如何决定启用哪些 resource (整卡 vs MIG)

### Stop 2: 插件注册 (10 min)

文件: `internal/plugin/server.go`

函数: `NewNvidiaDevicePlugin()`, `Start()`

- socket 路径: `/var/lib/kubelet/device-plugins/nvidia.com/gpu.sock`
- 如何调用 `pluginapi.Register()`

### Stop 3: ListAndWatch (15 min)

文件: `internal/plugin/server.go` → `ListAndWatch()`

回答:
1. `apiDevices()` 如何从 NVML 获取 GPU 列表?
2. 什么触发重新推送? (健康检查 goroutine)
3. MIG strategy 如何改变上报的 Device 列表?

### Stop 4: Allocate (15 min)

文件: `internal/plugin/server.go` → `Allocate()`

回答:
1. 如何校验 `req.DevicesIDs`?
2. `deviceListStrategy` 三个分支分别生成什么 response?
3. CDI 路径调用了哪些函数? (`internal/cdi/`)

## 自检

- [ ] 能画出 ListAndWatch 和 Allocate 的调用时序
- [ ] 能解释 `NVIDIA_VISIBLE_DEVICES` 在哪一行代码设置
- [ ] 能说出 MIG single vs mixed 对 Device 列表的影响
