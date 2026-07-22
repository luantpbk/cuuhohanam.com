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

echo "Cập nhật các gói hệ thống..."
apt-get update -y

echo "Cài đặt Nginx và Git..."
apt-get install -y nginx git

echo "Thiết lập thư mục web..."
if [ -d "$WEB_DIR/.git" ]; then
    echo "Thư mục đã tồn tại. Đang pull source mới nhất..."
    cd $WEB_DIR
    git reset --hard
    git pull origin main # Sử dụng branch main, đổi thành master nếu repo của bạn dùng master
else
    echo "Đang clone repository..."
    rm -rf $WEB_DIR
    git clone $REPO_URL $WEB_DIR
fi

# Phân quyền cho Nginx có thể đọc được file
chown -R www-data:www-data $WEB_DIR
chmod -R 755 $WEB_DIR

echo "Cấu hình Nginx..."
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"

cat > $NGINX_CONF <<EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name $DOMAIN www.$DOMAIN; # Thay bằng domain hoặc IP của bạn

    root $WEB_DIR;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF

# Kích hoạt site
ln -sf $NGINX_CONF /etc/nginx/sites-enabled/

# Xóa default site nếu có
rm -f /etc/nginx/sites-enabled/default

echo "Đang kiểm tra cấu hình Nginx..."
nginx -t

if [ $? -eq 0 ]; then
    echo "Khởi động lại Nginx..."
    systemctl restart nginx
    echo "Deploy thành công!"
else
    echo "Cấu hình Nginx lỗi. Vui lòng kiểm tra lại."
    exit 1
fi
