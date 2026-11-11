<?php
declare(strict_types=1);

/**
 * 会话与认证公共逻辑（CTF 课程靶场演示环境，非生产用途）
 */

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// 演示环境固定账号
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
