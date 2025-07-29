#!/bin/bash

# --- تنظیمات ---
BASE_DIR="$HOME/dl_files"
PORT=8000

# --- رنگ‌ها ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ۱. چک کردن ورودی URL
if [ -z "$1" ]; then
  echo -e "${YELLOW}خطا: لطفاً آدرس URL اسکریپت را به عنوان ورودی بدهید.${NC}"
  echo "مثال: ./proxy.sh https://example.com/script.sh"
  exit 1
fi

URL=$1
FILENAME=$(basename "$URL")

# --- بخش جدید: ساخت پوشه منحصر به فرد بر اساس هش URL ---
# از ۸ کاراکتر اول هش MD5 برای ساخت نام پوشه استفاده می‌کنیم
DIR_HASH=$(echo -n "$URL" | md5sum | cut -c1-8)
TARGET_DIR="$BASE_DIR/$DIR_HASH"
FINAL_URL_PATH="$DIR_HASH/$FILENAME"

# ۲. رفتن به پوشه اصلی و آماده‌سازی وب‌سرور
mkdir -p "$BASE_DIR"
cd "$BASE_DIR"

# چک کردن و اجرای وب‌سرور
if ! pgrep -f "python3 -m http.server $PORT" > /dev/null; then
  echo -e "\n${CYAN}در حال فعال‌سازی وب‌سرور روی پورت $PORT...${NC}"
  nohup python3 -m http.server $PORT >/dev/null 2>&1 &
  echo -e "${GREEN}وب‌سرور فعال شد. (فراموش نکنید پورت $PORT را در فایروال باز کنید)${NC}"
else
  echo -e "\n${GREEN}وب‌سرور از قبل فعال است.${NC}"
fi

# ۳. بررسی وجود پوشه و دانلود فایل
if [ -d "$TARGET_DIR" ]; then
    echo -e "\n${YELLOW}این URL قبلاً پردازش شده است. پوشه '$DIR_HASH' وجود دارد. از دانلود مجدد صرف‌نظر می‌شود.${NC}"
else
    echo -e "\n${CYAN}در حال ساخت پوشه جدید: $TARGET_DIR${NC}"
    mkdir -p "$TARGET_DIR"
    echo -e "${CYAN}در حال دانلود فایل: ${FILENAME}...${NC}"
    if ! wget -q -O "$TARGET_DIR/$FILENAME" "$URL"; then
        echo -e "${YELLOW}خطا: دانلود فایل با شکست مواجه شد.${NC}"
        rm -rf "$TARGET_DIR" # پاک کردن پوشه در صورت دانلود ناموفق
        exit 1
    fi
    echo -e "${GREEN}دانلود با موفقیت انجام شد.${NC}"
fi

# ۴. دریافت IP و نمایش دستور نهایی
IP_ADDR=$(curl -s ifconfig.me)
echo -e "\n====================================================================="
echo -e "${YELLOW}دستور زیر را کپی کرده و در سرور ایران خود اجرا کنید:${NC}"
echo -e "=====================================================================\n"
echo -e "${GREEN}bash <(curl -Ls http://$IP_ADDR:$PORT/$FINAL_URL_PATH)${NC}\n"
