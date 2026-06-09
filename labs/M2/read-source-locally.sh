#!/usr/bin/env bash
# Lab 2B: 克隆并打开 k8s-device-plugin 关键文件
set -euo pipefail

DEST="${1:-/tmp/k8s-device-plugin}"

if [[ ! -d "$DEST/.git" ]]; then
  echo "=== 克隆 NVIDIA k8s-device-plugin ==="
  git clone --depth=1 https://github.com/NVIDIA/k8s-device-plugin.git "$DEST"
fi

echo ""
echo "=== 关键文件路径 ==="
for f in \
  cmd/nvidia-device-plugin/main.go \
  internal/plugin/server.go \
  internal/cdi/api.go \
  api/config/v1/config.go; do
  if [[ -f "$DEST/$f" ]]; then
    lines=$(wc -l < "$DEST/$f")
    echo "  $DEST/$f  ($lines lines)"
  fi
done

echo ""
echo "=== 快速定位: ListAndWatch ==="
grep -n 'func.*ListAndWatch' "$DEST/internal/plugin/server.go" 2>/dev/null || true

echo ""
echo "=== 快速定位: Allocate ==="
grep -n 'func.*Allocate' "$DEST/internal/plugin/server.go" 2>/dev/null || true

echo ""
echo "=== 快速定位: NVIDIA_VISIBLE_DEVICES ==="
grep -rn 'NVIDIA_VISIBLE_DEVICES' "$DEST/internal/" 2>/dev/null | head -5 || true

echo ""
echo "跟读指南: labs/M2/source-reading-guide.md"
