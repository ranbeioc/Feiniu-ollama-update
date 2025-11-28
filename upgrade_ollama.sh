#!/bin/bash

set -e
set -o pipefail

echo "🔄 Ollama 升级脚本 for FnOS（国内镜像版 v2.3）"

# 1. 查找安装路径
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

# 2. 获取当前版本
echo "📦 检测当前版本..."
if [ -x "./ollama/bin/ollama" ]; then
    RAW=$(./ollama/bin/ollama --version 2>&1)
    CLIENT_VER=$(echo "$RAW" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    echo "📦 当前版本：v$CLIENT_VER"
fi

# 3. 获取最新版本号（不访问 github.com，仅用镜像源）
echo "🌐 获取 Ollama 最新版本号..."

LATEST_TAG=$(curl -sL https://ghproxy.cn/https://github.com/ollama/ollama/releases.atom \
    | grep -oP '(?<=<title>v)[0-9]+\.[0-9]+\.[0-9]+(?=</title>)' \
    | head -n 1)

if [ -z "$LATEST_TAG" ]; then
    echo "⚠️ 镜像源无法解析版本号，使用默认最新版本 v0.13.1"
    LATEST_TAG="0.13.1"
fi

echo "📦 最新可用版本：v$LATEST_TAG"
TAG_FULL="v$LATEST_TAG"
FILENAME="ollama-linux-amd64.tgz"

# 4. 构建镜像下载链接
DL1="https://ghproxy.cn/https://github.com/ollama/ollama/releases/download/$TAG_FULL/$FILENAME"
DL2="https://hub.gitmirror.com/https://github.com/ollama/ollama/releases/download/$TAG_FULL/$FILENAME"
DL3="https://fastgit.org/ollama/ollama/releases/download/$TAG_FULL/$FILENAME"

DOWNLOAD_URL=""

echo "🌐 尝试使用镜像源下载..."

# 5. 自动选择可访问的镜像链接
for url in "$DL1" "$DL2" "$DL3"; do
    if curl -s --head --fail "$url" >/dev/null 2>&1; then
        DOWNLOAD_URL="$url"
        break
    fi
done

if [ -z "$DOWNLOAD_URL" ]; then
    echo "❌ 所有镜像源都无法访问"
    echo "➡️ 请确认你的网络是否可以访问 ghproxy.cn 或 gitmirror"
    exit 1
fi

echo "🔗 使用下载地址：$DOWNLOAD_URL"

# 6. 如果已有文件且完整就跳过下载
if [ -f "$FILENAME" ]; then
    if gzip -t "$FILENAME" 2>/dev/null; then
        echo "✅ 本地压缩包完整，跳过下载"
    else
        echo "❌ 本地文件损坏，重新下载"
        rm -f "$FILENAME"
    fi
fi

# 7. 下载
if [ ! -f "$FILENAME" ]; then
    echo "⬇️ 开始下载 Ollama..."
    curl -L -o "$FILENAME" "$DOWNLOAD_URL"
fi

# 8. 备份旧版本
BK="ollama_bk_$(date +%Y%m%d_%H%M%S)"
mv ollama "$BK"
echo "📦 旧版本已备份：$BK"

# 9. 解压新版本
echo "📦 解压中..."
mkdir -p ollama
tar -xzf "$FILENAME" -C ollama

echo "🔎 确认新版本..."
NEW_RAW=$(./ollama/bin/ollama --version 2>&1)
NEW_VER=$(echo "$NEW_RAW" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

echo "🎉 升级完成！当前 Ollama 版本：v$NEW_VER"
