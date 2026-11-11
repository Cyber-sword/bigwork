#!/bin/bash
# ============================================================
# 胡杨好物 · 一键启动脚本（Linux / WSL / macOS 通用）
# 用法：bash start.sh
# 前置：已安装 Docker Engine（或 Docker Desktop 并启用 WSL 集成）
# ============================================================
set -e
cd "$(dirname "$0")"

# ---------- 1. 检测 docker ----------
if ! command -v docker >/dev/null 2>&1; then
    echo "[!] 未检测到 docker 命令，请先安装："
    echo "    Linux : curl -fsSL https://get.docker.com | bash && sudo usermod -aG docker \$USER"
    echo "    WSL   : 先在 Windows 安装 Docker Desktop 并开启 Settings > Resources > WSL Integration"
    exit 1
fi

# 当前用户是否有 docker 权限
if ! docker info >/dev/null 2>&1; then
    echo "[!] 无权访问 docker 守护进程，尝试用 sudo 重新执行..."
    exec sudo -E bash "$0"
fi

# ---------- 2. 检测 compose（v2 插件 / v1 独立） ----------
if docker compose version >/dev/null 2>&1; then
    COMPOSE="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
else
    echo "[!] 缺少 compose：请安装 docker-compose-plugin（apt install docker-compose-plugin）"
    exit 1
fi

# ---------- 3. 构建并启动 ----------
echo "[*] 正在构建并启动容器（首次运行会拉取 php:8.2-apache 基础镜像，需数分钟）..."
$COMPOSE up -d --build

# ---------- 4. 等待服务就绪 ----------
echo "[*] 等待服务就绪..."
for i in $(seq 1 30); do
    code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://127.0.0.1:26112/ 2>/dev/null || echo 000)
    [ "$code" = "200" ] && break
    sleep 2
done

if [ "$code" = "200" ]; then
    echo ""
    echo "=============================================="
    echo "  [✔] 胡杨好物 已启动！"
    echo "  访问地址 : http://127.0.0.1:26112"
    echo "             http://\$(本机IP):26112 （局域网）"
    echo "  登录账号 : admin / 123456"
    echo "  关闭服务 : $COMPOSE down"
    echo "=============================================="
    $COMPOSE ps
else
    echo "[!] 服务未就绪，请查看日志：$COMPOSE logs -f web"
    exit 1
fi
