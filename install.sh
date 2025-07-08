#!/bin/bash

# ==============================
# Cài đặt Dante SOCKS5 Proxy
# ==============================

# Tự động đợi lock apt nếu đang bị chiếm dụng
function wait_for_apt() {
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
    echo "Đang chờ apt unlock..."
    sleep 3
  done
}

# Tự động phát hiện interface chính
function detect_interface() {
  ip route get 8.8.8.8 | awk -- '{print $5; exit}'
}

# Thực thi cài đặt
wait_for_apt
apt update -y && apt install -y dante-server net-tools

# Tạo user/pass random
USERNAME="user$(openssl rand -hex 2)"
PASSWORD="$(openssl rand -hex 4)"

# Phát hiện interface
INTERFACE=$(detect_interface)
PORT=1080

# Backup cấu hình cũ nếu có
mv /etc/danted.conf /etc/danted.conf.bak 2>/dev/null

# Tạo cấu hình mới
cat <<EOF > /etc/danted.conf
logoutput: /var/log/danted.log
internal: $INTERFACE port = $PORT
external: $INTERFACE

method: username none
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
    command: connect
}
EOF

# Tạo user đăng nhập SOCKS5
useradd -M -s /usr/sbin/nologin $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Bật và khởi động dịch vụ
systemctl restart danted
systemctl enable danted

# Mở port firewall nếu có UFW
if command -v ufw >/dev/null 2>&1; then
  ufw allow $PORT/tcp
fi

# Lấy IP public
IP=$(curl -s ipv4.icanhazip.com)

# Hiển thị thông tin
echo ""
echo -e "✅ SOCKS5 Proxy đã được cài đặt thành công!"
echo -e "🔐 Proxy: $IP:$PORT:$USERNAME:$PASSWORD"

# Lưu thông tin ra file
echo "$IP:$PORT:$USERNAME:$PASSWORD" > proxy-info.txt
