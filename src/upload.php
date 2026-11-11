<?php
require_once __DIR__ . '/includes/auth.php';
require_login();

$PAGE_TITLE = '上传头像 - 青苗校园二手交易平台';

$msg      = '';
$msgType  = 'error';
$savedUrl = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['avatar'])) {
    $file = $_FILES['avatar'];

    if (!is_array($file) || $file['error'] !== UPLOAD_ERR_OK) {
        $msg = '上传失败：请重新选择文件（错误码 ' . (int)($file['error'] ?? -1) . '）';
    } elseif (!is_uploaded_file($file['tmp_name'])) {
        $msg = '上传失败：无效的上传请求';
    } else {
        $mime = (string)($file['type'] ?? '');

        // ===== 基本类型防护 1：Content-Type 必须以 image/ 开头 =====
        if (stripos($mime, 'image/') !== 0) {
            $msg = '类型校验未通过：仅允许上传图片（Content-Type 需以 image/ 开头）';
        } else {
            $name = basename((string)$file['name']);
            $ext  = strtolower(pathinfo($name, PATHINFO_EXTENSION));

            // ===== 基本类型防护 2：扩展名黑名单（旧版遗留规则，仅拦截 exe/bat/sh/cmd） =====
            $blacklist = ['exe', 'bat', 'sh', 'cmd'];
            if (in_array($ext, $blacklist, true)) {
                $msg = '类型校验未通过：禁止上传可执行脚本文件（exe / bat / sh / cmd）';
            } else {
                $targetDir = __DIR__ . '/uploads';
                if (!is_dir($targetDir)) {
                    @mkdir($targetDir, 0775, true);
                }
                $target = $targetDir . '/' . $name;

                // 保留原文件名保存
                if (move_uploaded_file($file['tmp_name'], $target)) {
                    @chmod($target, 0644);
                    $_SESSION['avatar'] = $name;
                    $msgType  = 'success';
                    $msg      = '上传成功：头像已保存为 /uploads/' . $name;
                    $savedUrl = '/uploads/' . rawurlencode($name);
                } else {
                    $msg = '保存失败：上传目录不可写';
                }
            }
        }
    }
} else {
    header('Location: dashboard.php');
    exit;
}

require_once __DIR__ . '/includes/header.php';
?>
<section class="card">
  <h2>头像上传结果</h2>
  <p class="alert <?= $msgType === 'success' ? 'alert-success' : 'alert-error' ?>">
    <?= htmlspecialchars($msg) ?>
  </p>
  <?php if ($savedUrl !== ''): ?>
    <img class="avatar" src="<?= htmlspecialchars($savedUrl) ?>" alt="已上传头像">
  <?php endif; ?>
  <p><a class="btn" href="dashboard.php">返回个人中心</a></p>
</section>
<?php require_once __DIR__ . '/includes/footer.php'; ?>
