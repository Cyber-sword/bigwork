<?php
declare(strict_types=1);

/**
 * 会话、认证与用户资料公共逻辑（CTF 课程靶场演示环境，非生产用途）
 */

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// 演示环境固定登录账号
const APP_USER = 'admin';
const APP_PASS = '123456';

function is_logged_in(): bool
{
    return isset($_SESSION['user']) && $_SESSION['user'] === APP_USER;
}

function current_user(): string
{
    return $_SESSION['user'] ?? '';
}

function require_login(): void
{
    if (!is_logged_in()) {
        header('Location: /login.php');
        exit;
    }
}

/* ---------------- 用户资料（JSON 文件持久化） ---------------- */

function profile_path(): string
{
    return __DIR__ . '/../data/profile.json';
}

function profile_defaults(): array
{
    return [
        'username' => '大漠胡杨',
        'gender'   => '男',
        'age'      => '21',
        'birthday' => '2004-09-01',
        'address'  => '胡杨大学金柳苑 6 号楼 520',
    ];
}

function load_profile(): array
{
    $raw = @file_get_contents(profile_path());
    $arr = $raw ? json_decode($raw, true) : [];
    return array_merge(profile_defaults(), is_array($arr) ? $arr : []);
}

function save_profile(array $profile): bool
{
    $json = json_encode($profile, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    return $json !== false && @file_put_contents(profile_path(), $json) !== false;
}

/* ---------------- 购物车 / 收藏（Session 存储） ---------------- */

function cart_items(): array
{
    return isset($_SESSION['cart']) && is_array($_SESSION['cart']) ? $_SESSION['cart'] : [];
}

function cart_count(): int
{
    $total = 0;
    foreach (cart_items() as $qty) {
        $total += (int)$qty;
    }
    return $total;
}

function fav_items(): array
{
    return isset($_SESSION['fav']) && is_array($_SESSION['fav']) ? $_SESSION['fav'] : [];
}
