#!/bin/bash

set -e
set -o pipefail

echo "🔄 Ollama 升级脚本 for FnOS, 稳定版 v2.2"

# 1. 查找 Ollama 安装路径
VOL_PREFIXES=(/vol1 /vol2 /vol3 /vol4 /vol5 /vol6 /vol7 /vol8 /vol9)
AI_INSTALLER=""

echo "🔍 查找 Ollama 安装路径..."
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

# 2. 当前版本
echo "📦 正在检测当前 Ollama 客户端版本..."
if [ -x "./ollama/bin/ollama" ]; then
    VERSION_RAW=$(./ollama/bin/ollama --version 2>&1)
    CLIENT_VER=$(echo "$VERSION_RAW" | grep -i "client version" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    echo "📦 当前版本：v$CLIENT_VER（客户端）"
fi

# 3. 获取最新版本号（使用 releases.atom，极稳定）
echo "🌐 获取 Ollama 最新版本号..."

LATEST_TAG=$(curl -s https://github.com/ollama/ollama/releases.atom \
    | grep -oP '(?<=<title>v)[0-9]+\.[0-9]+\.[0-9]+(?=</title>)' \
    | head -n 1)

# 如果失败：给默认值，不阻塞流程
if [ -z "$LATEST_TAG" ]; then
    echo "⚠️ 无法从 GitHub 获取最新版本号，网络可能受限"
    echo "➡️ 默认使用 v0.13.1（不会停止脚本）"
    LATEST_TAG="0.13.1"
else
    echo "📦 最新版本号：v$LATEST_TAG"
fi

TAG_FULL="v$LATEST_TAG"
FILENAME="ollama-linux-amd64.tgz"
URL="https://github.com/ollama/ollama/releases/download/$TAG_FULL/$FILENAME"

echo "🔗 下载地址：$URL"

# 4. 如有旧包检查完整性
if [ -f "$FILENAME" ]; then
    echo "🔍 检测本地包完整性..."
    if gzip -t "$FILENAME" 2>/dev/null; then
        echo "✅ 本地压缩包正常"
    else
        echo "❌ 本地文件损坏，重新下载"
        rm -f "$FILENAME"
    fi
fi

# 5. 下载文件
if [ ! -f "$FILENAME" ]; then
    echo "⬇️ 下载 Ollama $TAG_FULL ..."
    if command -v aria2c >/dev/null 2>&1; then
        aria2c -x 16 -s 16 -k 1M -o "$FILENAME" "$URL"
    else
        curl -L -o "$FILENAME" "$URL"
    fi
fi

# 6. 备份旧版本
BACKUP_NAME="ollama_bk_$(date +%Y%m%d_%H%M%S)"
mv ollama "$BACKUP_NAME"
echo "📦 旧版本已备份：$BACKUP_NAME"

# 7. 解压新版本
echo "📦 解压新版本..."
mkdir -p ollama
tar -xzf "$FILENAME" -C ollama

# 8. 结束
if [ -x "./ollama/bin/ollama" ]; then
    NEW_RAW=$(./ollama/bin/ollama --version 2>&1)
    NEW_VER=$(echo "$NEW_RAW" | grep -i "client version" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    echo "🎉 升级成功！新版本：v$NEW_VER（客户端）"
fi

echo "🚀 Ollama 已成功升级！"
