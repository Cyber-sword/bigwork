<?php require_once __DIR__ . '/auth.php'; $P = load_profile(); ?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= htmlspecialchars($PAGE_TITLE ?? '胡杨好物 - 校园闲置交易平台') ?></title>
<link rel="stylesheet" href="/assets/style.css">
</head>
<body>
<div class="bg-blobs" aria-hidden="true"><span class="blob b1"></span><span class="blob b2"></span><span class="blob b3"></span></div>
<header class="site-header">
  <div class="container header-inner">
    <a class="brand" href="/index.php"><span class="brand-ico">🍂</span> 胡杨好物</a>
    <nav class="nav">
      <a href="/index.php">首页</a>
      <a href="/index.php#goods">好物广场</a>
      <?php if (is_logged_in()): ?>
        <a href="/favorites.php">收藏</a>
        <a href="/cart.php" class="nav-cart">购物车<?php $cc = cart_count(); if ($cc > 0): ?><span class="cart-badge"><?= $cc ?></span><?php endif; ?></a>
        <a href="/dashboard.php">个人中心</a>
        <a href="/flag_submit.php">提交 Flag</a>
        <a href="/logout.php">退出</a>
        <span class="nav-user">👤 <?= htmlspecialchars($P['username']) ?></span>
      <?php else: ?>
        <a href="/login.php">登录</a>
      <?php endif; ?>
    </nav>
  </div>
</header>
<main class="container">
