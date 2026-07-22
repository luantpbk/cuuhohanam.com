#!/bin/bash

# Configuration
REPO_URL="https://github.com/luantpbk/cuuhohanam.com.git"
WEB_DIR="/var/www/cuuhohanam.com"
DOMAIN="cuuhohanam.com" # Thay bằng domain hoặc IP của bạn nếu cần

# Kiểm tra quyền root
if [ "$EUID" -ne 0 ]; then
  echo "Vui lòng chạy script với quyền root (sử dụng sudo)"
  exit 1
fi

echo "Thiết lập thư mục web..."
if [ -d "$WEB_DIR/.git" ]; then
    echo "Thư mục đã tồn tại. Đang pull source mới nhất..."
    cd $WEB_DIR
    git reset --hard
    git pull origin main
else
    echo "Đang clone repository..."
    rm -rf $WEB_DIR
    git clone $REPO_URL $WEB_DIR
fi

# Phân quyền cho Nginx (trên Oracle/CentOS dùng user nginx)
chown -R nginx:nginx $WEB_DIR
chmod -R 755 $WEB_DIR

echo "Cấu hình Nginx..."
NGINX_CONF="/etc/nginx/conf.d/${DOMAIN}.conf"

cat > $NGINX_CONF <<EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name $DOMAIN www.$DOMAIN;

    root $WEB_DIR;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;

    # Tạm dùng cert của kidzlab.edu.vn để Cloudflare (chế độ Full) có thể kết nối mà không bị trả về Express app
    ssl_certificate /etc/nginx/ssl/kidzlab.edu.vn.pem;
    ssl_certificate_key /etc/nginx/ssl/kidzlab.edu.vn.key;

    root $WEB_DIR;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

echo "Đang kiểm tra cấu hình Nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "Khởi động lại Nginx..."
    systemctl reload nginx
    echo "Deploy thành công!"
else
    echo "Cấu hình Nginx lỗi. Vui lòng kiểm tra lại."
    exit 1
fi

