#!/bin/bash

# ==============================
# CÀI ĐẶT DANTE SOCKS5 PROXY
# ==============================

# Chờ apt nếu đang bị chiếm
function wait_for_apt() {
  while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
        fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
        fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
    echo "⏳ Đang chờ apt unlock..."
    sleep 2
  done
}

# Phát hiện interface chính
function detect_interface() {
  ip route get 8.8.8.8 | awk '{print $5; exit}'
}

# Bắt đầu
wait_for_apt
apt update -y && apt install -y dante-server net-tools curl openssl

# Random user/pass
USERNAME="user$(openssl rand -hex 2)"
PASSWORD="$(openssl rand -hex 4)"
PORT=1080

# Interface chính
INTERFACE=$(detect_interface)

# Backup nếu có
mv /etc/danted.conf /etc/danted.conf.bak 2>/dev/null

# Ghi cấu hình mới
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

# Tạo user
useradd -M -s /usr/sbin/nologin "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd

# Restart dịch vụ
systemctl restart danted
systemctl enable danted

# Mở port nếu có ufw
if command -v ufw >/dev/null 2>&1; then
  ufw allow $PORT/tcp
fi

# Lấy IP
IP=$(curl -s ipv4.icanhazip.com)

# ✅ Kết quả
echo ""
echo -e "✅ \033[1;32mSOCKS5 Proxy đã được cài đặt thành công!\033[0m"
echo -e "🔐 \033[1;36mProxy: $IP:$PORT:$USERNAME:$PASSWORD\033[0m"

# Lưu ra file
echo "$IP:$PORT:$USERNAME:$PASSWORD" > proxy-info.txt
