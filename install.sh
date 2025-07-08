#!/bin/bash

# Kiểm tra quyền root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Vui lòng chạy script với quyền root!"
  exit 1
fi

# Cài gói cần thiết
apt update && apt install -y dante-server curl

# Phát hiện interface mạng
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)

# Tạo user ngẫu nhiên
USERNAME="user$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 4)"
PASSWORD="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)"
PORT=$((RANDOM % 10000 + 10000))  # random port từ 10000 đến 19999

# Tạo user cho Dante
useradd -M -s /usr/sbin/nologin $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Cấu hình Dante
cat > /etc/danted.conf <<EOF
logoutput: /var/log/danted.log
internal: $INTERFACE port = $PORT
external: $INTERFACE

method: username
user.notprivileged: nobody

client pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  log: connect disconnect error
}

pass {
  from: 0.0.0.0/0 to: 0.0.0.0/0
  protocol: tcp udp
  method: username
  log: connect disconnect error
}
EOF

# Bật dịch vụ Dante
systemctl enable danted
systemctl restart danted

# Lấy IP public
IP=$(curl -s ipv4.icanhazip.com)

# Hiển thị & lưu thông tin
echo -e "✅ SOCKS5 Proxy đã được cài đặt thành công!"
echo -e "🔐 Proxy: $IP:$PORT:$USERNAME:$PASSWORD"

echo "$IP:$PORT:$USERNAME:$PASSWORD" > /root/proxy-credentials.txt
echo "socks5://$USERNAME:$PASSWORD@$IP:$PORT" > /root/proxy-connection.txt
