<?php require_once __DIR__ . '/auth.php'; ?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= htmlspecialchars($PAGE_TITLE ?? '青苗校园二手交易平台') ?></title>
<link rel="stylesheet" href="/assets/style.css">
</head>
<body>
<header class="site-header">
  <div class="container header-inner">
    <a class="brand" href="/index.php">🌱 青苗二手</a>
    <nav class="nav">
      <a href="/index.php">首页</a>
      <a href="/index.php#goods">好物广场</a>
      <?php if (is_logged_in()): ?>
        <a href="/dashboard.php">个人中心</a>
        <a href="/flag_submit.php">提交 Flag</a>
        <a href="/logout.php">退出</a>
        <span class="nav-user">👤 <?= htmlspecialchars(current_user()) ?></span>
      <?php else: ?>
        <a href="/login.php">登录</a>
      <?php endif; ?>
    </nav>
  </div>
</header>
<main class="container">
