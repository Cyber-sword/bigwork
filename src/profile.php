<?php
require_once __DIR__ . '/includes/auth.php';
require_login();

$PAGE_TITLE = '个人资料 - 胡杨好物';

$errors = [];
$saved  = false;
$profile = load_profile();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim((string)($_POST['username'] ?? ''));
    $gender   = (string)($_POST['gender'] ?? '');
    $age      = trim((string)($_POST['age'] ?? ''));
    $birthday = trim((string)($_POST['birthday'] ?? ''));
    $address  = trim((string)($_POST['address'] ?? ''));

    /* 服务端校验 */
    if ($username === '' || mb_strlen($username) > 20) {
        $errors[] = '用户名需为 1-20 个字符';
    }
    if (!in_array($gender, ['男', '女', '保密'], true)) {
        $errors[] = '性别取值不合法';
    }
    if (!preg_match('/^\d{1,3}$/', $age) || (int)$age < 1 || (int)$age > 120) {
        $errors[] = '年龄需为 1-120 的数字';
    }
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $birthday) || strtotime($birthday) === false) {
        $errors[] = '生日格式需为 YYYY-MM-DD';
    }
    if (mb_strlen($address) > 100) {
        $errors[] = '地址不能超过 100 个字符';
    }

    if (empty($errors)) {
        $profile = [
            'username' => $username,
            'gender'   => $gender,
            'age'      => (string)(int)$age,
            'birthday' => $birthday,
            'address'  => $address,
        ];
        $saved = save_profile($profile);
        if ($saved) {
            header('Location: profile.php?saved=1');
            exit;
        }
        $errors[] = '资料保存失败：数据文件不可写';
    }
}

$savedFlag = ($_GET['saved'] ?? '') === '1';
require_once __DIR__ . '/includes/header.php';
?>
<section class="card">
  <h2>👤 个人资料</h2>
  <p>维护你的个人信息，昵称将显示在导航栏（登录账号 admin 不受影响）。</p>

  <?php if ($savedFlag): ?>
    <p class="alert alert-success">✔ 资料已保存</p>
  <?php endif; ?>
  <?php if (!empty($errors)): ?>
    <div class="alert alert-error">
      <?php foreach ($errors as $e): ?><p style="margin:2px 0">✘ <?= htmlspecialchars($e) ?></p><?php endforeach; ?>
    </div>
  <?php endif; ?>

  <form method="post" action="profile.php" class="profile-form">
    <label>用户名（昵称）
      <input type="text" name="username" maxlength="20" value="<?= htmlspecialchars($profile['username']) ?>" required>
    </label>
    <label>性别
      <select name="gender">
        <?php foreach (['男', '女', '保密'] as $opt): ?>
          <option value="<?= $opt ?>" <?= $profile['gender'] === $opt ? 'selected' : '' ?>><?= $opt ?></option>
        <?php endforeach; ?>
      </select>
    </label>
    <label>年龄
      <input type="number" name="age" min="1" max="120" value="<?= htmlspecialchars($profile['age']) ?>" required>
    </label>
    <label>生日
      <input type="date" name="birthday" value="<?= htmlspecialchars($profile['birthday']) ?>" required>
    </label>
    <label>地址
      <input type="text" name="address" maxlength="100" value="<?= htmlspecialchars($profile['address']) ?>">
    </label>
    <button class="btn btn-primary" type="submit">保存资料</button>
  </form>
</section>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
