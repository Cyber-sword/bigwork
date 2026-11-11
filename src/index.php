<?php
$PAGE_TITLE = '青苗校园二手交易平台 - 首页';
require_once __DIR__ . '/includes/header.php';
?>

<!-- TODO(dev): avatar upload legacy validation only blocks exe/bat/sh/cmd; php/png/jpg are not filtered and original filename is kept under /uploads/. -->

<section class="hero">
  <h1>校园二手，好物不落灰</h1>
  <p>青苗二手是面向全校师生的校园闲置交易平台：教材、数码、宿舍好物一键发布，让每一件闲置都找到新主人。</p>
  <div class="hero-actions">
    <a class="btn btn-primary" href="/login.php">立即登录</a>
    <a class="btn" href="#goods">逛逛好物</a>
  </div>
</section>

<section id="goods" class="goods">
  <h2>🔥 今日好物</h2>
  <div class="goods-grid">
    <div class="goods-card">
      <div class="thumb">📚</div>
      <h3>高等数学（第七版）上下册</h3>
      <p class="price">¥ 25.00</p>
      <p class="meta">九成新 · 数学学院 · 3 分钟前</p>
    </div>
    <div class="goods-card">
      <div class="thumb">⌨️</div>
      <h3>87 键蓝牙机械键盘</h3>
      <p class="price">¥ 89.00</p>
      <p class="meta">红轴 · 计算机学院 · 12 分钟前</p>
    </div>
    <div class="goods-card">
      <div class="thumb">💡</div>
      <h3>宿舍护眼小台灯</h3>
      <p class="price">¥ 15.00</p>
      <p class="meta">可充电 · 5 号楼 · 30 分钟前</p>
    </div>
    <div class="goods-card">
      <div class="thumb">🚲</div>
      <h3>26 寸变速自行车</h3>
      <p class="price">¥ 199.00</p>
      <p class="meta">毕业转让 · 东门面交 · 1 小时前</p>
    </div>
    <div class="goods-card">
      <div class="thumb">🎧</div>
      <h3>头戴式降噪耳机</h3>
      <p class="price">¥ 129.00</p>
      <p class="meta">95 新 · 研究生楼 · 2 小时前</p>
    </div>
    <div class="goods-card">
      <div class="thumb">🪴</div>
      <h3>多肉植物小盆栽</h3>
      <p class="price">¥ 8.00</p>
      <p class="meta">含盆 · 宿管阿姨推荐 · 3 小时前</p>
    </div>
  </div>
</section>

<section class="features">
  <div class="feature">
    <h3>📝 一键发布</h3>
    <p>拍照上传、填写价格，10 秒挂出你的闲置好物。</p>
  </div>
  <div class="feature">
    <h3>💬 站内沟通</h3>
    <p>买卖双方站内私聊，砍价、约面交两不误。</p>
  </div>
  <div class="feature">
    <h3>🤝 校内面交</h3>
    <p>同校交易更放心，宿舍楼、食堂门口随时约。</p>
  </div>
</section>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
