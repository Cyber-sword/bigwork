# 胡杨好物 · 校园闲置交易平台（CTF 文件上传靶场）

> 《网络虚拟化技术》课程大作业 —— 基于 **Docker + docker-compose** 构建的"看起来普通的 Web 网站 + CTF-Web 文件上传靶场"。
> 表面是校园二手交易平台「胡杨好物」，暗藏一个可解的文件上传漏洞挑战。

---

## 1. 项目简介

| 项目 | 说明 |
|------|------|
| 站点名称 | 胡杨好物（校园闲置交易平台） |
| 作者 | 张昌鑫 |
| 技术栈 | PHP 8.2 + Apache（`php:8.2-apache` 官方镜像）+ Session |
| 端口 | `26112:80`（宿主机 26112 → 容器 80） |
| 漏洞点 | 头像上传：仅校验 `Content-Type` 前缀 + 黑名单只拦 `exe/bat/sh/cmd`，不查内容、不重命名 |
| Flag | 容器内 `/flag`（Web 根目录之外，前端不可见） |

**网站功能**：首页商品广场（14 件好物）、收藏、购物车（数量增减/删除/合计）、登录、个人中心（昵称/性别/年龄/生日/地址资料编辑 + 头像上传）、Flag 提交校验。

**CTF 玩法**：主页源码藏有 hint → `admin/123456` 登录 → 伪造 `Content-Type: image/png` 上传 `shell.php` → 访问 `/uploads/shell.php?cmd=cat%20/flag` 拿 flag → 到"提交 Flag"页面验证。

---

## 2. 环境要求（依赖安装）

本项目的**唯一依赖是 Docker**，无需安装 PHP、Apache、MySQL 等任何运行时。

### 2.1 Windows

1. 安装 [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)；
2. 安装时勾选 **Use WSL 2 instead of Hyper-V**（需先启用 WSL2：管理员 PowerShell 执行 `wsl --install` 后重启）；
3. 启动 Docker Desktop，等待右下角鲸鱼图标变为运行状态；
4. 验证：打开 PowerShell 或 Git Bash 执行 `docker version`，能同时显示 Client/Server 信息即可。

> 运行验证脚本需要 Git Bash（Windows 推荐），可从 https://git-scm.com/download/win 安装。

### 2.2 macOS

1. 安装 [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)（Apple Silicon 选择 ARM 版即可，镜像支持多架构）；
2. 启动 Docker Desktop 后验证 `docker version`。

### 2.3 Linux（Ubuntu/Debian 示例）

```bash
# 安装 Docker Engine 与 compose 插件
curl -fsSL https://get.docker.com | bash
sudo systemctl enable --now docker

# 将当前用户加入 docker 组（免 sudo，重新登录生效）
sudo usermod -aG docker $USER

# 验证
docker version && docker compose version
```

> 若使用旧版 `docker-compose`（v1）独立命令亦可，脚本已做兼容探测。

---

## 3. 启动

### 3.1 一键启动（Linux / WSL / macOS，推荐）

```bash
# 首次部署：克隆仓库并一键启动
git clone https://github.com/Cyber-sword/bigwork.git
cd bigwork
bash start.sh

# 之后再次启动（项目目录内）
bash start.sh
```

`start.sh` 会自动完成：docker/compose 环境检测（缺失时给出安装指引）→ 构建镜像 → 后台启动 → 轮询等待就绪 → 打印访问地址与账号。WSL 环境需先在 Windows 安装 Docker Desktop 并开启 **Settings → Resources → WSL Integration**，或在 WSL 发行版内自行安装 Docker Engine。

### 3.2 手动启动（通用）

```bash
# 1. 进入项目根目录（即本 README 所在目录）
cd bigwork

# 2. 构建并启动（首次运行会自动拉取 php:8.2-apache 基础镜像）
docker compose up -d --build

# 3. 查看状态（应为 Up，端口 0.0.0.0:26112->80/tcp）
docker compose ps
```

启动后访问：

| 入口 | 地址 |
|------|------|
| 本机 | http://127.0.0.1:26112 |
| 局域网 | http://<本机局域网IP>:26112 |
| 登录账号 | `admin`（用户名输入框已预填）/ 密码 `123456` |

---

## 4. 关闭

```bash
docker compose down       # 停止并移除容器与网络（镜像保留）
docker compose down -v    # 同时清除匿名卷
docker compose stop       # 仅停止，不删除容器（下次 start 直接拉起）
```

---

## 5. 重置 / 完整重建

```bash
# 彻底重置（含 --no-cache 重建镜像，用于代码变更后或环境异常时）
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

> 说明：购物车与收藏保存在 Session 中，`down` 后自动清空；用户资料持久化在容器内 `/var/www/html/data/profile.json`，`down -v` + 重建后恢复默认。

---

## 6. 自动化验证（可选）

```bash
bash scripts/verify.sh        # Windows 用 Git Bash / Linux、macOS 直接 bash
```

脚本自动完成：重建服务 → 60 秒启动等待 → 13 大项 38 条断言（品牌/作者、商品数量、登录、购物车、收藏、资料修改、exe 拦截、上传绕过 GetFlag、flag 校验、全站源码零泄露、本机 IP 可达）。结果输出到 `reports/verify.log`，全部 PASS 会打印 `结论：全部验证通过 ✔`。

---

## 7. 目录结构

```
bigwork/
├── Dockerfile                  # 镜像构建（写 /flag、拷贝源码、目录授权）
├── docker-compose.yml          # 服务编排（26112:80、unless-stopped）
├── start.sh                    # 一键启动脚本（Linux / WSL / macOS）
├── README.md                   # 本文档
├── src/                        # 站点源码 → 拷贝至容器 /var/www/html/
│   ├── index.php               # 首页（商品广场 + 隐藏 hint 注释）
│   ├── goods.php               # 商品数据源（14 件好物）
│   ├── login.php / logout.php  # 登录 / 退出（admin / 123456）
│   ├── dashboard.php           # 个人中心（头像上传入口 = 漏洞入口）
│   ├── profile.php             # 个人资料编辑（昵称/性别/年龄/生日/地址）
│   ├── favorites.php           # 收藏（收藏 / 取消收藏）
│   ├── cart.php                # 购物车（加购 / 增减 / 删除 / 合计）
│   ├── upload.php              # 上传处理（弱校验，漏洞点）
│   ├── flag_submit.php         # Flag 提交校验（hash_equals）
│   ├── includes/               # auth / header / footer 公共组件
│   ├── assets/style.css        # 主题（暗色玻璃拟态 + 颗粒噪点 + 金色渐变）
│   ├── data/profile.json       # 用户资料持久化文件（容器内可写）
│   └── uploads/                # 上传目录（可写、允许 PHP 执行）
├── scripts/verify.sh           # 自动化验证脚本
├── reports/                    # 结课报告 / CTF 解题报告 / 验证日志
└── dist/bigwork.zip            # 项目分发包（git archive 导出）
```

---

## 8. 常见问题（FAQ）

**Q1：启动时报 `port is already allocated` / 端口被占用？**
编辑 `docker-compose.yml`，把 `ports: ["26112:80"]` 的左值改成其他空闲端口（如 `"27000:80"`），重新 `docker compose up -d`。

**Q2：Windows 上 `docker compose` 命令不存在？**
确认 Docker Desktop 正在运行；老版本用 `docker-compose`（带连字符）。脚本会自动探测。

**Q3：浏览器访问不了 26112？**
`docker compose ps` 确认容器 Up；检查本机防火墙/安全组是否放行 26112；局域网访问需用宿主机真实 IP。

**Q4：上传头像提示"保存失败：目录不可写"？**
镜像内 `uploads/` 已授权 www-data；若手工改动过容器，执行 `docker compose up -d --build` 重建即可恢复。

**Q5：flag 是什么？**
完成 CTF 解题路径后由 `/uploads/shell.php?cmd=cat%20/flag` 获得；也可在容器内执行 `docker compose exec web cat /flag` 直接查看（仅限出题人/教师）。

**Q6：本靶场可以部署到公网吗？**
不可以。站点存在**故意保留的文件上传漏洞**，仅限课程实验、靶场演练使用，请勿部署到生产或公网环境。

---

## 9. 免责声明

本项目为《网络虚拟化技术》课程大作业的教学演示环境：漏洞为**教学目的刻意设计**，仅供学习文件上传漏洞原理与加固方案使用，请勿用于任何未授权测试。
