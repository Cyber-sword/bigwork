FROM php:8.2-apache

# 在镜像构建阶段写入固定 flag（位于 Web 根目录之外，前端页面不可见）
# 使用双引号包裹，避免 flag 值中单引号的转义问题
RUN printf "%s\n" "flag{this_is_zhangchangxin's_bigwork}" > /flag && chmod 644 /flag

# 复制站点源码到 Apache Web 根目录
COPY src/ /var/www/html/

# uploads 目录授予 www-data 写权限（保留该目录的 PHP 执行能力，不部署任何 .htaccess 限制）
RUN mkdir -p /var/www/html/uploads \
    && chown -R www-data:www-data /var/www/html/uploads \
    && chmod -R 775 /var/www/html/uploads

EXPOSE 80
