#!/bin/bash

set -e
set -o pipefail

echo "🔄 Ollama 升级脚本 for FnOS, 修复版 v2.1.2"

# 1. 查找 Ollama 安装路径
echo "🔍 查找 Ollama 安装路径..."
VOL_PREFIXES=(/vol1 /vol2 /vol3 /vol4 /vol5 /vol6 /vol7 /vol8 /vol9)
AI_INSTALLER=""

for vol in "${VOL_PREFIXES[@]}"; do
    if [ -d "$vol/@appcenter/ai_installer/ollama" ]; then
        AI_INSTALLER="$vol/@appcenter/ai_installer"
        echo "✅ 找到安装路径：$AI_INSTALLER"
        break
    fi
done

if [ -z "$AI_INSTALLER" ]; then
    echo "❌ 未找到 Ollama 安装路径"
    exit 1
fi

cd "$AI_INSTALLER"

# 2. 获取当前版本
echo "📦 正在检测当前 Ollama 客户端版本..."

if [ -x "./ollama/bin/ollama" ]; then
    VERSION_RAW=$(./ollama/bin/ollama --version 2>&1)
    CLIENT_VER=$(echo "$VERSION_RAW" | grep -i "client version" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    echo "📦 当前已安装版本：v$CLIENT_VER（客户端）"
else
    echo "❌ 未找到 ollama 可执行文件"
fi

# 3. 获取最新版本号
echo "🌐 获取 Ollama 最新版本号..."

LATEST_TAG=$(curl -s https://github.com/ollama/ollama/releases \
    | grep -oP '/ollama/ollama/releases/tag/\K[^"]+' \
    | head -n 1)

if [ -z "$LATEST_TAG" ]; then
    echo "❌ 无法从 GitHub 获取版本号"
    exit 1
fi

echo "📦 最新版本号：$LATEST_TAG"

# 生成下载 URL（修复点）
URL="https://github.com/ollama/ollama/releases/download/$LATEST_TAG/ollama-linux-amd64.tgz"
FILENAME="ollama-linux-amd64.tgz"

echo "🔗 下载地址：$URL"

# 4. 如果已有旧文件检查是否损坏
if [ -f "$FILENAME" ]; then
    echo "🔍 检测到本地已有 $FILENAME，验证完整性..."
    if gzip -t "$FILENAME" 2>/dev/null; then
        echo "✅ 本地压缩包完整，跳过下载"
    else
        echo "❌ 本地文件损坏，重新下载"
        rm -f "$FILENAME"
    fi
fi

# 5. 下载文件（修复缺失 URL 的错误）
if [ ! -f "$FILENAME" ]; then
    echo "⬇️ 正在下载版本 $LATEST_TAG ..."
    if command -v aria2c >/dev/null 2>&1; then
        echo "🚀 使用 aria2c 多线程下载..."
        aria2c -x 16 -s 16 -k 1M -o "$FILENAME" "$URL"
    else
        echo "⬇️ 使用 curl 单线程下载..."
        curl -L -o "$FILENAME" "$URL"
    fi
fi

# 6. 备份旧版本
BACKUP_NAME="ollama_bk_$(date +%Y%m%d_%H%M%S)"
mv ollama "$BACKUP_NAME"
echo "📦 已备份原版 Ollama 为：$BACKUP_NAME"

# 7. 解压部署新版本
echo "📦 解压到 ollama/ ..."
mkdir -p ollama
tar -xzf "$FILENAME" -C ollama

# 8. 完成
if [ -x "./ollama/bin/ollama" ]; then
    VERSION_RAW=$(./ollama/bin/ollama --version 2>&1)
    CLIENT_VER=$(echo "$VERSION_RAW" | grep -i "client version" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    echo "✅ 新 Ollama 版本为：v$CLIENT_VER（客户端）"
fi

echo "🎉 升级完成！"
