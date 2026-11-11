<?php
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/goods.php';
require_login();

/* 收藏 toggle：POST 后 302 回来源页（index 或 favorites） */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = (int)($_POST['id'] ?? 0);
    if (!isset($_SESSION['fav']) || !is_array($_SESSION['fav'])) {
        $_SESSION['fav'] = [];
    }
    if (get_goods($GOODS, $id) !== null) {
        if (isset($_SESSION['fav'][$id])) {
            unset($_SESSION['fav'][$id]);
        } else {
            $_SESSION['fav'][$id] = true;
        }
    }
    $back = ($_POST['return'] ?? 'favorites') === 'index' ? 'index.php#goods' : 'favorites.php';
    header('Location: ' . $back);
    exit;
}

$PAGE_TITLE = '我的收藏 - 胡杨好物';
$favs = fav_items();
$rows = [];
foreach (array_keys($favs) as $gid) {
    $g = get_goods($GOODS, (int)$gid);
    if ($g !== null) {
        $rows[] = $g;
    }
}

require_once __DIR__ . '/includes/header.php';
?>
<section class="card">
  <h2>⭐ 我的收藏</h2>

  <?php if (empty($rows)): ?>
    <p class="empty-tip">还没有收藏任何好物，去 <a href="index.php#goods">好物广场</a> 点亮第一颗星吧。</p>
  <?php else: ?>
    <div class="goods-grid">
      <?php foreach ($rows as $g): ?>
      <div class="goods-card">
        <div class="thumb"><?= $g['emoji'] ?></div>
        <span class="badge-cat"><?= htmlspecialchars($g['category']) ?></span>
        <h3><?= htmlspecialchars($g['name']) ?></h3>
        <p class="price">¥ <?= number_format($g['price'], 2) ?></p>
        <p class="meta"><?= htmlspecialchars($g['meta']) ?></p>
        <div class="card-actions">
          <form method="post" action="favorites.php">
            <input type="hidden" name="id" value="<?= (int)$g['id'] ?>">
            <input type="hidden" name="return" value="favorites">
            <button class="btn-mini btn-fav-on" type="submit">★ 取消收藏</button>
          </form>
          <form method="post" action="cart.php">
            <input type="hidden" name="action" value="add">
            <input type="hidden" name="id" value="<?= (int)$g['id'] ?>">
            <button class="btn-mini btn-cart" type="submit">🛒 加购</button>
          </form>
        </div>
      </div>
      <?php endforeach; ?>
    </div>
  <?php endif; ?>
</section>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
