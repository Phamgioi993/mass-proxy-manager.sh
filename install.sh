#!/bin/bash
if [[ $EUID -ne 0 ]]; then echo "Chạy bằng root nhé"; exit 1; fi
IFACE=$(ip route get 8.8.8.8 | grep -oP 'dev \K\S+')
apt update -y && apt install -y dante-server curl
USERNAME="user_$(tr -dc 'a-z0-9' </dev/urandom | head -c 8)"
PASSWORD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 10)"
useradd -M -s /usr/sbin/nologin $USERNAME && echo "$USERNAME:$PASSWORD" | chpasswd
PROXY_PORT=$(shuf -i 20000-30000 -n 1)
SERVER_IP=$(curl -s ifconfig.me)
cat <<EOF > /etc/danted.conf
logoutput: /var/log/danted.log
internal: $IFACE port = $PROXY_PORT
external: $IFACE
method: username
user.notprivileged: nobody
client pass { from: 0.0.0.0/0 to: 0.0.0.0/0 log: connect disconnect error }
pass { from: 0.0.0.0/0 to: 0.0.0.0/0 protocol: tcp udp method: username log: connect disconnect error }
EOF
echo "$SERVER_IP:$PROXY_PORT:$USERNAME:$PASSWORD" > /root/proxy-connection.txt
systemctl restart danted && systemctl enable danted
echo "Proxy: $SERVER_IP:$PROXY_PORT:$USERNAME:$PASSWORD"
