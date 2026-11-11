<?php
require_once __DIR__ . '/includes/auth.php';
require_once __DIR__ . '/goods.php';
require_login();

/* PRG：所有写操作 POST 后 302 回购物车页 */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = (string)($_POST['action'] ?? '');
    $id     = (int)($_POST['id'] ?? 0);

    if (!isset($_SESSION['cart']) || !is_array($_SESSION['cart'])) {
        $_SESSION['cart'] = [];
    }

    switch ($action) {
        case 'add':      // 加入购物车
            if (get_goods($GOODS, $id) !== null) {
                $_SESSION['cart'][$id] = ($_SESSION['cart'][$id] ?? 0) + 1;
            }
            break;
        case 'inc':      // 数量 +1
            if (isset($_SESSION['cart'][$id])) {
                $_SESSION['cart'][$id] = min(99, (int)$_SESSION['cart'][$id] + 1);
            }
            break;
        case 'dec':      // 数量 -1，减到 0 移除
            if (isset($_SESSION['cart'][$id])) {
                $_SESSION['cart'][$id] = (int)$_SESSION['cart'][$id] - 1;
                if ($_SESSION['cart'][$id] <= 0) {
                    unset($_SESSION['cart'][$id]);
                }
            }
            break;
        case 'remove':   // 移除单件
            unset($_SESSION['cart'][$id]);
            break;
        case 'clear':    // 清空
            $_SESSION['cart'] = [];
            break;
    }
    header('Location: cart.php');
    exit;
}

$PAGE_TITLE = '购物车 - 胡杨好物';
$cart = cart_items();
$total = 0.00;
$rows = [];
foreach ($cart as $gid => $qty) {
    $g = get_goods($GOODS, (int)$gid);
    if ($g === null) {
        continue;
    }
    $qty    = (int)$qty;
    $sum    = $g['price'] * $qty;
    $total += $sum;
    $rows[] = ['g' => $g, 'qty' => $qty, 'sum' => $sum];
}

require_once __DIR__ . '/includes/header.php';
?>
<section class="card">
  <h2>🛒 我的购物车</h2>

  <?php if (empty($rows)): ?>
    <p class="empty-tip">购物车空空如也，去 <a href="index.php#goods">好物广场</a> 逛逛吧。</p>
  <?php else: ?>
    <table class="cart-table">
      <thead>
        <tr><th>商品</th><th>单价</th><th>数量</th><th>小计</th><th>操作</th></tr>
      </thead>
      <tbody>
        <?php foreach ($rows as $r): $g = $r['g']; ?>
        <tr>
          <td class="cart-goods"><span class="cart-emoji"><?= $g['emoji'] ?></span><?= htmlspecialchars($g['name']) ?></td>
          <td>¥ <?= number_format($g['price'], 2) ?></td>
          <td>
            <span class="qty-box">
              <form method="post" action="cart.php"><input type="hidden" name="action" value="dec"><input type="hidden" name="id" value="<?= (int)$g['id'] ?>"><button class="qty-btn" type="submit">−</button></form>
              <b class="qty-num"><?= $r['qty'] ?></b>
              <form method="post" action="cart.php"><input type="hidden" name="action" value="inc"><input type="hidden" name="id" value="<?= (int)$g['id'] ?>"><button class="qty-btn" type="submit">＋</button></form>
            </span>
          </td>
          <td class="cart-sum">¥ <?= number_format($r['sum'], 2) ?></td>
          <td>
            <form method="post" action="cart.php"><input type="hidden" name="action" value="remove"><input type="hidden" name="id" value="<?= (int)$g['id'] ?>"><button class="btn-mini btn-danger" type="submit">删除</button></form>
          </td>
        </tr>
        <?php endforeach; ?>
      </tbody>
    </table>

    <div class="cart-footer">
      <form method="post" action="cart.php"><input type="hidden" name="action" value="clear"><button class="btn btn-ghost" type="submit">清空购物车</button></form>
      <div class="cart-total">合计：<b>¥ <?= number_format($total, 2) ?></b>
        <button class="btn btn-primary" type="button" onclick="alert('演示环境：已生成模拟订单，感谢体验胡杨好物！')">去结算</button>
      </div>
    </div>
  <?php endif; ?>
</section>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
