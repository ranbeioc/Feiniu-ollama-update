
# Feiniu-ollama-update

一键更新飞牛（HyperNAS）上 Ollama 的脚本工具。

飞牛上的 Ollama 很不错，但官方版本更新较慢，很多新模型无法使用。本项目提供一个可靠的一键升级脚本，让你始终使用最新版 Ollama 与 WebUI。

---

## 🚀 一键升级命令

**1. 先在应用商店停用 Ollama**

**2. SSH 登录飞牛系统，执行以下命令：**

```bash
curl -sL https://raw.githubusercontent.com/ranbeioc/Feiniu-ollama-update/refs/heads/main/upgrade_ollama.sh | bash
```

**3. 升级完成后，从应用商店手动重新启用 Ollama 即可。**

---

## 📦 当前测试环境

- 飞牛系统版本：`fnOS 0.9.13`
- 原始 Ollama 版本：`0.5.13`
- 升级后版本：`0.9.5`

升级过程中将自动执行以下操作：

- 自动识别安装路径 `/volX/@appcenter/ai_installer`
- 自动备份旧版本至 `ollama_bk_YYYYMMDD_HHMMSS`
- 自动下载并部署最新 Ollama 版本
- 自动升级 `pip` 和 `open-webui`
- 自动检查版本一致性，若已是最新则跳过更新

---

## ✨ 示例运行输出

```bash
taco@MS-FnOS:~$ curl -sL https://raw.githubusercontent.com/wzqvip/Feiniu-ollama-update/main/upgrade_ollama.sh | bash
🔍 查找 Ollama 安装路径...
✅ 找到安装路径：/vol1/@appcenter/ai_installer
📦 正在检测当前 Ollama 客户端版本...
📦 当前已安装版本：v0.5.13（客户端）
📦 已备份原版 Ollama 为：ollama_bk_20250707_023630
🌐 获取 Ollama 最新版本号...
⬇️ 正在下载版本 v0.9.5 ...
📦 解压到 ollama/ ...
⬆️ 正在升级 pip...
⬆️ 正在升级 open-webui...
✅ 新 Ollama 版本为：v0.9.5（客户端）
🎉 升级完成！Ollama 与 open-webui 均为最新版本。
```

---

## 🧩 其他实用脚本

### 🔁 ollama 版本还原脚本（可选）

如果你遇到兼容性或运行异常，可以一键还原之前版本：

```bash
curl -sL https://raw.githubusercontent.com/wzqvip/Feiniu-ollama-update/main/restore_ollama.sh | bash
```

> 自动查找最新的 `ollama_bk_****` 备份并恢复为当前版本。

---

### 🧹 清理旧版本与缓存压缩包（推荐）

升级成功后建议清理系统残留的旧版本与下载文件：

```bash
curl -sL https://raw.githubusercontent.com/wzqvip/Feiniu-ollama-update/main/cleanup_ollama.sh | bash -s -- --force

```

> 交互式确认可选删除内容：

```bash
curl -O https://raw.githubusercontent.com/wzqvip/Feiniu-ollama-update/main/cleanup_ollama.sh
bash cleanup_ollama.sh

```

示例：

```
🧹 正在查找 Ollama 安装目录...
✅ 找到目录：/vol1/@appcenter/ai_installer
📦 将删除以下备份目录：
ollama_bk_20250707_023630
ollama_bk_20250707_024938
❓ 是否删除这些目录？[y/N]
y 
🗑️ 删除：ollama_bk_20250707_023630
🗑️ 删除：ollama_bk_20250707_024938
📦 将删除以下压缩包文件：
ollama-linux-amd64.tgz
❓ 是否删除这些压缩包？[y/N]
y
🗑️ 删除：ollama-linux-amd64.tgz
✅ 清理完成！
```

---

## 🧾 致谢

- 教程灵感参考：https://post.smzdm.com/p/av7kp427/
- 脚本作者：[wzqvip](https://github.com/wzqvip)

---

## 📜 License

MIT License
