#!/bin/bash
# This script automates the entire process of proxying the 3x-ui panel installer.

# --- تنظیمات ---
FILES_DIR="$HOME/panel-proxy-files"
PORT=8888 # یک پورت ثابت برای سادگی

# --- رنگ‌ها ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}--- شروع آماده‌سازی پراکسی کامل برای پنل ---${NC}"

# ۱. ساخت پوشه
mkdir -p "$FILES_DIR"
cd "$FILES_DIR"

# ۲. دانلود تمام فایل‌های لازم برای پنل
echo "در حال دانلود فایل‌های ضروری (install.sh, x-ui.tar.gz, x-ui.sh)..."
wget -q -O install.sh https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh
wget -q -O x-ui-linux-amd64.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz
wget -q -O x-ui.sh https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
echo -e "${GREEN}تمام فایل‌ها با موفقیت دانلود شدند.${NC}"

# ۳. دریافت IP سرور و ساخت لینک‌های جدید
IP_ADDR=$(curl -s ifconfig.me)
NEW_TAR_GZ_URL="http://$IP_ADDR:$PORT/x-ui-linux-amd64.tar.gz"
NEW_XUI_SH_URL="http://$IP_ADDR:$PORT/x-ui.sh"

# ۴. ویرایش خودکار اسکریپت نصب برای استفاده از لینک‌های جدید
echo "در حال بازنویسی اسکریپت نصب برای دانلود از همین سرور..."
# پیدا کردن خطوط دانلود اصلی و جایگزینی آن‌ها با لینک‌های پراکسی
sed -i "s|wget -N --no-check-certificate -O /usr/local/x-ui-linux-amd64.tar.gz.*|wget -N --no-check-certificate -O /usr/local/x-ui-linux-amd64.tar.gz \"$NEW_TAR_GZ_URL\"|" install.sh
sed -i "s|wget -N --no-check-certificate -O /usr/bin/x-ui-temp.*|wget -N --no-check-certificate -O /usr/bin/x-ui-temp \"$NEW_XUI_SH_URL\"|" install.sh
echo -e "${GREEN}اسکریپت نصب با موفقیت ویرایش شد.${NC}"

# ۵. راه‌اندازی وب‌سرور
echo "در حال فعال‌سازی وب‌سرور روی پورت ${PORT}..."
# متوقف کردن سرور قبلی برای جلوگیری از تداخل
pkill -f "python3 -m http.server $PORT" &>/dev/null
# اجرای سرور جدید در پس‌زمینه
nohup python3 -m http.server $PORT &>/dev/null &
echo -e "${GREEN}وب‌سرور فعال است.${NC}"

# ۶. تولید دستور نهایی برای سرور ایران
FINAL_INSTALLER_URL="http://$IP_ADDR:$PORT/install.sh"
echo -e "\n====================================================================="
echo -e "${YELLOW}دستور نهایی برای سرور ایران:${NC}"
echo -e "این دستور یک خطی را کپی کرده و در سرور ایران خود اجرا کنید."
echo -e "این دستور پنل را بدون نیاز به اتصال به گیت‌هاب نصب می‌کند."
echo -e "====================================================================="
echo -e "${GREEN}bash <(curl -Ls $FINAL_INSTALLER_URL)${NC}\n"
