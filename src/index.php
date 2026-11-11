<?php
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/goods.php';

$PAGE_TITLE = '胡杨好物 - 校园闲置交易平台';
$favs = fav_items();
$cart = cart_items();

require_once __DIR__ . '/includes/header.php';
?>

<!-- TODO(dev): avatar upload legacy validation only blocks exe/bat/sh/cmd; php/png/jpg are not filtered and original filename is kept under /uploads/. -->

<section class="hero">
  <h1>大漠胡杨 · 好物不落灰</h1>
  <p>三千年的胡杨，一秒的心动 —— 胡杨好物是面向全校师生的校园闲置交易平台：教材、数码、宿舍好物一键发布、收藏加购，让每一件闲置都找到新主人。</p>
  <div class="hero-actions">
    <a class="btn btn-primary" href="/login.php">立即登录</a>
    <a class="btn" href="#goods">逛逛好物</a>
  </div>
  <div class="hero-stats">
    <div class="stat"><b><?= count($GOODS) ?></b><span>在售好物</span></div>
    <div class="stat"><b>327</b><span>校内用户</span></div>
    <div class="stat"><b>1.2k</b><span>累计成交</span></div>
  </div>
</section>

<section id="goods" class="goods">
  <h2>🔥 今日好物</h2>
  <div class="goods-grid">
    <?php foreach ($GOODS as $g): ?>
    <div class="goods-card">
      <div class="thumb"><?= $g['emoji'] ?></div>
      <span class="badge-cat"><?= htmlspecialchars($g['category']) ?></span>
      <h3><?= htmlspecialchars($g['name']) ?></h3>
      <p class="price">¥ <?= number_format($g['price'], 2) ?></p>
      <p class="meta"><?= htmlspecialchars($g['meta']) ?></p>
      <p class="desc"><?= htmlspecialchars($g['desc']) ?></p>
      <div class="card-actions">
        <form method="post" action="favorites.php">
          <input type="hidden" name="id" value="<?= (int)$g['id'] ?>">
          <input type="hidden" name="return" value="index">
          <button class="btn-mini <?= isset($favs[$g['id']]) ? 'btn-fav-on' : 'btn-fav' ?>" type="submit">
            <?= isset($favs[$g['id']]) ? '★ 已收藏' : '☆ 收藏' ?>
          </button>
        </form>
        <form method="post" action="cart.php">
          <input type="hidden" name="action" value="add">
          <input type="hidden" name="id" value="<?= (int)$g['id'] ?>">
          <button class="btn-mini btn-cart" type="submit">🛒 加购<?= isset($cart[$g['id']]) ? ' ×' . (int)$cart[$g['id']] : '' ?></button>
        </form>
      </div>
    </div>
    <?php endforeach; ?>
  </div>
</section>

<section class="features">
  <div class="feature">
    <h3>📝 一键发布</h3>
    <p>拍照上传、填写价格，10 秒挂出你的闲置好物。</p>
  </div>
  <div class="feature">
    <h3>⭐ 收藏关注</h3>
    <p>心动好物先收藏，降价捡漏不错过。</p>
  </div>
  <div class="feature">
    <h3>🛒 购物车合单</h3>
    <p>多件好物一口价合单，东门面交一次拿齐。</p>
  </div>
</section>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
