<?php
require_once __DIR__ . '/includes/auth.php';

$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim((string)($_POST['username'] ?? ''));
    $password = (string)($_POST['password'] ?? '');

    if ($username === APP_USER && $password === APP_PASS) {
        session_regenerate_id(true);
        $_SESSION['user'] = $username;
        header('Location: dashboard.php');
        exit;
    }
    $error = '用户名或密码错误';
}

$PAGE_TITLE = '登录 - 青苗校园二手交易平台';
require_once __DIR__ . '/includes/header.php';
?>
<section class="auth-card">
  <h2>登录</h2>
  <?php if ($error !== ''): ?>
    <p class="alert alert-error"><?= htmlspecialchars($error) ?></p>
  <?php endif; ?>
  <form method="post" action="login.php">
    <label>用户名
      <input type="text" name="username" value="admin" required>
    </label>
    <label>密码
      <input type="password" name="password" placeholder="请输入密码" required>
    </label>
    <button class="btn btn-primary btn-block" type="submit">登 录</button>
  </form>
  <p class="muted small">演示账号：admin / 123456</p>
</section>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
