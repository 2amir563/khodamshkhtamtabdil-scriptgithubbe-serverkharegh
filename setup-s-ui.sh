#!/bin/bash
# This script automates the process of preparing a fully proxied installer for the s-ui panel.

# --- تنظیمات ---
FILES_DIR="$HOME/sui-proxied-files"
PORT=8889 # یک پورت متفاوت برای جلوگیری از تداخل
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
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}--- شروع آماده‌سازی پراکسی کامل برای پنل s-ui ---${NC}"

# ۱. ساخت پوشه
mkdir -p "$FILES_DIR"
cd "$FILES_DIR"

# ۲. پیدا کردن آخرین نسخه و دانلود فایل‌های لازم
echo "در حال پیدا کردن آخرین نسخه پنل s-ui..."
LAST_VERSION=$(curl -Ls "https://api.github.com/repos/alireza0/s-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LAST_VERSION" ]; then
    echo -e "${RED}خطا: پیدا کردن آخرین نسخه با شکست مواجه شد.${NC}"
    exit 1
fi
echo -e "${GREEN}آخرین نسخه یافت شد: $LAST_VERSION${NC}"

echo "در حال دانلود فایل‌های ضروری (install.sh و s-ui.tar.gz)..."
wget -q -O install.sh "https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh"
wget -q -O "s-ui-linux-$ARCH.tar.gz" "https://github.com/alireza0/s-ui/releases/download/$LAST_VERSION/s-ui-linux-$ARCH.tar.gz"

if [ ! -f "install.sh" ] || [ ! -f "s-ui-linux-$ARCH.tar.gz" ]; then
    echo -e "${RED}خطا: دانلود یک یا چند فایل ضروری با شکست مواجه شد.${NC}"
    exit 1
fi
echo -e "${GREEN}تمام فایل‌های مورد نیاز با موفقیت دانلود شدند.${NC}"

# ۳. ویرایش اسکریپت نصب برای غیرفعال کردن دانلودهای داخلی
echo "در حال ویرایش اسکریپت نصب برای جلوگیری از اتصال به گیت‌هاب..."
# غیرفعال کردن دستورات دانلود از گیت‌هاب در اسکریپت نصب
sed -i -e '/api\.github\.com/ s/^/# /' -e '/releases\/download/ s/^/# /' install.sh
echo -e "${GREEN}اسکریپت نصب با موفقیت ویرایش شد.${NC}"

# ۴. راه‌اندازی وب‌سرور
echo "در حال فعال‌سازی وب‌سرور روی پورت ${PORT}..."
pkill -f "python3 -m http.server $PORT" &>/dev/null
nohup python3 -m http.server $PORT &>/dev/null &
echo -e "${GREEN}وب‌سرور فعال است.${NC}"

# ۵. تولید دستورالعمل نهایی برای سرور ایران
IP_ADDR=$(curl -s ifconfig.me)
echo -e "\n====================================================================="
echo -e "${YELLOW}دستورالعمل برای سرور ایران:${NC}"
echo -e "دستورات زیر را به ترتیب در سرور ایران خود اجرا کنید."
echo -e "====================================================================="

echo -e "\n${CYAN}مرحله ۱: دانلود تمام فایل‌ها از سرور پراکسی خود:${NC}"
echo -e "${GREEN}curl -O http://$IP_ADDR:$PORT/install.sh"
echo -e "${GREEN}curl -O http://$IP_ADDR:$PORT/s-ui-linux-$ARCH.tar.gz${NC}"

echo -e "\n${CYAN}مرحله ۲: انتقال فایل اصلی برنامه به مکان صحیح:${NC}"
echo -e "${GREEN}sudo mv s-ui-linux-$ARCH.tar.gz /tmp/${NC}"

echo -e "\n${CYAN}مرحله ۳: اجرای نصب‌کننده:${NC}"
echo -e "${GREEN}chmod +x install.sh && bash ./install.sh${NC}\n"
