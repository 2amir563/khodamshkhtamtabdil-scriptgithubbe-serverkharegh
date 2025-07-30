#!/bin/bash

# این اسکریپت به صورت خودکار تمام فایل‌های لازم برای نصب پنل را دانلود،
# اسکریپت نصب را ویرایش، و دستورات نهایی را برای شما آماده می‌کند.

# --- تنظیمات ---
PANEL_FILES_DIR="$HOME/sanaei-panel-files"
PORT=8888 # می‌توانید این پورت را تغییر دهید

# --- رنگ‌ها ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}--- Shoro-e amaliat-e amade sazi-e file-ha ---${NC}"

# ۱. ساخت پوشه
mkdir -p "$PANEL_FILES_DIR"
cd "$PANEL_FILES_DIR"

# ۲. دانلود تمام فایل‌های لازم
echo "Dar hale download-e file-haye panel (install.sh, x-ui.tar.gz, x-ui.sh)..."
wget -q -O install.sh https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh
wget -q -O x-ui-linux-amd64.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz
wget -q -O x-ui.sh https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
echo -e "${GREEN}Tamam-e file-ha download shodand.${NC}"

# ۳. ویرایش خودکار اسکریپت نصب
echo "Dar hale virayesh-e script-e nasb baraye estefade az proxy..."
# غیرفعال کردن دستورات دانلود از گیت‌هاب در اسکریپت نصب
sed -i -e '/releases\/download/ s/^/# /' -e '/x-ui\.sh/ s/^/# /' install.sh
echo -e "${GREEN}Script-e nasb virayesh shod.${NC}"

# ۴. راه‌اندازی وب‌سرور
echo "Dar hale راه andazi-e web server rooye port ${PORT}..."
# متوقف کردن سرور قبلی اگر در حال اجرا باشد
pkill -f "python3 -m http.server $PORT" &>/dev/null
# اجرای سرور جدید در پس‌زمینه
nohup python3 -m http.server $PORT &>/dev/null &
echo -e "${GREEN}Web server fa'al shod.${NC}"

# ۵. ساخت دستورات نهایی برای سرور ایران
IP_ADDR=$(curl -s ifconfig.me)
echo -e "\n====================================================================="
echo -e "${YELLOW}RAHNAY-E NASB DAR SERVER-E IRAN:${NC}"
echo -e "Dastoorat-e zir ra be tartib dar server-e Iran vared va ejra konid:"
echo -e "====================================================================="

echo -e "\n${CYAN}1. Download-e hame-ye file-ha (in block ra copy/paste konid):${NC}"
echo -e "${GREEN}curl -O http://$IP_ADDR:$PORT/install.sh && curl -O http://$IP_ADDR:$PORT/x-ui-linux-amd64.tar.gz && curl -O http://$IP_ADDR:$PORT/x-ui.sh${NC}"

echo -e "\n${CYAN}2. Ejra-ye script-e nasb:${NC}"
echo -e "${GREEN}chmod +x install.sh && bash ./install.sh${NC}\n"
