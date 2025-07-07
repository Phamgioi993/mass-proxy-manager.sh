#!/bin/bash

###############################################
# 1. Cài đặt & cấu hình
###############################################
SCRIPT_URL="https://raw.githubusercontent.com/Phamgioi993/shocks5/main/install.sh"
PROXY_LIST="proxy-list.txt"
SERVERS_FILE="servers.txt"
SSH_USER="root"
SSH_KEY="$HOME/.ssh/id_rsa"  # Đường dẫn private key SSH

BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
CHAT_ID="YOUR_TELEGRAM_CHAT_ID"

> "$PROXY_LIST"

###############################################
# 2. Hàm: Cài đặt Dante SOCKS5 từ xa
###############################################
install_dante() {
    SERVER="$1"
    echo -e "\n🚀 Cài đặt Dante trên $SERVER ..."
    ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$SERVER" bash -s <<EOF
sudo -i
wget -q $SCRIPT_URL -O install.sh
sed -i 's/\r\$//' install.sh
chmod +x install.sh
./install.sh
EOF
}

###############################################
# 3. Hàm: Lấy thông tin proxy từ máy đã cài
###############################################
get_proxy_info() {
    SERVER="$1"
    echo "📥 Thu thập proxy từ $SERVER ..."
    PROXY=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER" "cat /root/proxy-connection.txt" 2>/dev/null)
    if [[ -n "\$PROXY" ]]; then
        echo "$PROXY" >> "$PROXY_LIST"
        echo "✅ $PROXY"
    else
        echo "❌ Không lấy được proxy từ $SERVER"
    fi
}

###############################################
# 4. Chạy từng bước cho tất cả máy
###############################################
while IFS= read -r SERVER; do
    install_dante "\$SERVER"
    get_proxy_info "\$SERVER"
done < "$SERVERS_FILE"

###############################################
# 5. Gửi proxy về Telegram
###############################################
if [[ -s "$PROXY_LIST" ]]; then
    echo -e "\n📤 Gửi danh sách proxy về Telegram..."
    curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendDocument" \
        -F chat_id="$CHAT_ID" \
        -F document=@"$PROXY_LIST" \
        -F caption="📦 Danh sách Proxy mới nhất"
else
    echo "⚠️ Không có proxy nào để gửi"
fi
