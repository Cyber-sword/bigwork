<?php
require_once __DIR__ . '/includes/auth.php';
require_login();

$PAGE_TITLE = '个人中心 - 青苗校园二手交易平台';
$avatar    = $_SESSION['avatar'] ?? '';
$avatarUrl = $avatar !== '' ? '/uploads/' . rawurlencode($avatar) : '';

require_once __DIR__ . '/includes/header.php';
?>
<section class="card">
  <h2>👋 欢迎，<?= htmlspecialchars(current_user()) ?></h2>
  <p>这是你的个人中心。在这里可以更换头像、管理发布的好物、提交挑战 Flag。</p>

  <div class="profile-grid">
    <div class="avatar-box">
      <h3>当前头像</h3>
      <?php if ($avatarUrl !== ''): ?>
        <img class="avatar" src="<?= htmlspecialchars($avatarUrl) ?>" alt="头像">
        <p class="muted small">文件：<?= htmlspecialchars($avatar) ?></p>
      <?php else: ?>
        <div class="avatar avatar-placeholder">🌱</div>
        <p class="muted small">还没有头像，快上传一个吧</p>
      <?php endif; ?>
    </div>

    <div class="upload-box">
      <h3>上传头像</h3>
      <form action="upload.php" method="post" enctype="multipart/form-data">
        <input type="file" name="avatar" accept="image/*" required>
        <button class="btn btn-primary" type="submit">上传头像</button>
      </form>
      <p class="muted small">支持 png / jpg 等常见图片格式，文件将保存到 /uploads/ 目录。</p>
    </div>
  </div>

  <div class="card-inner">
    <h3>🏆 Flag 挑战</h3>
    <p>如果你在靶场中挖到了 flag，可前往 <a href="flag_submit.php">提交 Flag 页面</a> 进行校验。</p>
  </div>
</section>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
