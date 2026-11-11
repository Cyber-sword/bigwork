<?php
require_once __DIR__ . '/includes/auth.php';
require_login();

$PAGE_TITLE = '提交 Flag - 青苗校园二手交易平台';

$result = null; // null=未提交 true=正确 false=错误

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = trim((string)($_POST['flag'] ?? ''));
    // 服务端读取宿主容器内的 /flag（不在 Web 根目录，页面源码不可见）
    $real  = trim((string)@file_get_contents('/flag'));

    if ($real !== '' && $input !== '' && hash_equals($real, $input)) {
        $result = true;
    } else {
        $result = false;
    }
}

require_once __DIR__ . '/includes/header.php';
?>
<section class="card">
  <h2>🏆 提交 Flag</h2>
  <p>如果你在靶场中找到了 flag，请在下方输入并提交验证。</p>

  <?php if ($result === true): ?>
    <p class="alert alert-success">✔ Flag 正确，恭喜你完成挑战！</p>
  <?php elseif ($result === false): ?>
    <p class="alert alert-error">✘ Flag 不正确，请再试一次。</p>
  <?php endif; ?>

  <form method="post" action="flag_submit.php">
    <label>Flag 内容
      <input type="text" name="flag" placeholder="flag{...}" required>
    </label>
    <button class="btn btn-primary" type="submit">提交验证</button>
  </form>
</section>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
