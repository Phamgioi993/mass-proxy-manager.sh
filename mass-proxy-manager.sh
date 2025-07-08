#!/bin/bash

###########################################
# 1. Cài đặt & cấu hình
###########################################
SCRIPT_URL="https://raw.githubusercontent.com/Phamgioi993/shocks5/main/install.sh"
PROXY_LIST="proxy-list.txt"
SERVERS_FILE="servers.txt"
SSH_USER="root"
SSH_KEY="$HOME/.ssh/id_rsa"  # Đường dẫn private key SSH

BOT_TOKEN="8101843998:AAEXeV13VjLn7w9Gev60ea6S12v2f01hy_A"
CHAT_ID="YOUR_TELEGRAM_CHAT_ID"

> "$PROXY_LIST"

###########################################
# 2. Hàm: Cài đặt Dante SOCKS5 từ xa
###########################################
install_dante() {
  SERVER="$1"
  echo -e "\n🔧 Cài đặt Dante trên $SERVER ..."
  ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$SERVER" bash -s <<EOF
    sudo -i
    wget -q \$SCRIPT_URL -O install.sh
    sed -i 's/\r\$//' install.sh
    chmod +x install.sh
    ./install.sh
EOF
}

###########################################
# 3. Hàm: Lấy thông tin proxy từ máy đã cài
###########################################
get_proxy_info() {
  SERVER="$1"
  echo -e "\n📦 Lấy thông tin proxy từ $SERVER ..."
  ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$SERVER" 'cat /root/proxy-connection.txt' >> "$PROXY_LIST"
}

###########################################
# 4. Hàm: Gửi proxy qua Telegram
###########################################
send_to_telegram() {
  MESSAGE="$(cat "$PROXY_LIST")"
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
       -d "chat_id=$CHAT_ID" \
       -d "text=\`\`\`
$MESSAGE
\`\`\`" \
       -d "parse_mode=Markdown"
}

###########################################
# 5. Vòng lặp qua từng server để thực hiện
###########################################
while read SERVER; do
  install_dante "$SERVER"
  get_proxy_info "$SERVER"
done < "$SERVERS_FILE"

###########################################
# 6. Gửi kết quả về Telegram
###########################################
send_to_telegram

###########################################
# DONE
###########################################
echo -e "\n✅ Đã hoàn tất quá trình cài đặt và gửi proxy!"
