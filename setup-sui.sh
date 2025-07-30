#!/bin/bash
# A dedicated script to prepare a fully proxied installer for the s-ui panel.

# --- تنظیمات ---
FILES_DIR="$HOME/s-ui-proxied-files"
PORT=8888 # می‌توانید این پورت را تغییر دهید
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" || "$ARCH" == "x64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
fi

# --- رنگ‌ها ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}--- شروع آماده‌سازی پراکسی کامل برای پنل s-ui ---${NC}"

# ۱. ساخت پوشه
mkdir -p "$FILES_DIR"
cd "$FILES_DIR"

# ۲. پیدا کردن آخرین نسخه پنل
echo "در حال پیدا کردن آخرین نسخه پنل s-ui..."
LAST_VERSION=$(curl -Ls "https://api.github.com/repos/alireza0/s-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LAST_VERSION" ]; then
    echo -e "${RED}خطا: پیدا کردن آخرین نسخه با شکست مواجه شد.${NC}"
    exit 1
fi
echo -e "${GREEN}آخرین نسخه یافت شد: $LAST_VERSION${NC}"

# ۳. دانلود فایل‌های لازم
INSTALL_SH_URL="https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh"
TAR_GZ_URL="https://github.com/alireza0/s-ui/releases/download/$LAST_VERSION/s-ui-linux-$ARCH.tar.gz"

echo "در حال دانلود فایل نصب‌کننده و فایل اصلی برنامه..."
wget -q -O install.sh "$INSTALL_SH_URL"
wget -q -O "s-ui-linux-$ARCH.tar.gz" "$TAR_GZ_URL"
echo -e "${GREEN}تمام فایل‌ها با موفقیت دانلود شدند.${NC}"

# ۴. دریافت IP سرور و ساخت لینک‌های جدید
IP_ADDR=$(curl -s ifconfig.me)
NEW_TAR_GZ_URL="http://$IP_ADDR:$PORT/s-ui-linux-$ARCH.tar.gz"

# ۵. ویرایش خودکار اسکریپت نصب
echo "در حال بازنویسی اسکریپت نصب برای دانلود از همین سرور..."
# غیرفعال کردن بخش پیدا کردن آخرین نسخه
sed -i "/last_version=\$(curl/c\last_version=\"$LAST_VERSION\"" install.sh
# جایگزینی لینک دانلود گیت‌هاب با لینک پراکسی
sed -i "s|https://github.com/alireza0/s-ui/releases/download/\${last_version}/s-ui-linux-\$(arch).tar.gz|$NEW_TAR_GZ_URL|g" install.sh
echo -e "${GREEN}اسکریپت نصب با موفقیت ویرایش شد.${NC}"

# ۶. راه‌اندازی وب‌سرور
echo "در حال فعال‌سازی وب‌سرور روی پورت ${PORT}..."
pkill -f "python3 -m http.server $PORT" &>/dev/null
nohup python3 -m http.server $PORT &>/dev/null &
echo -e "${GREEN}وب‌سرور فعال است.${NC}"

# ۷. تولید دستور نهایی برای سرور ایران
FINAL_INSTALLER_URL="http://$IP_ADDR:$PORT/install.sh"
echo -e "\n====================================================================="
echo -e "${YELLOW}دستور نهایی برای سرور ایران:${NC}"
echo -e "این دستور یک خطی را کپی کرده و در سرور ایران خود اجرا کنید."
echo -e "====================================================================="
echo -e "${GREEN}bash <(curl -Ls $FINAL_INSTALLER_URL)${NC}\n"
