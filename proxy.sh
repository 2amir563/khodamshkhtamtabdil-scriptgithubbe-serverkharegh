#!/bin/bash

# --- تنظیمات ---
# پوشه‌ای که فایل‌ها در آن دانلود و سرو می‌شوند
DOWNLOAD_DIR="$HOME/dl_files"
# پورتی که وب‌سرور روی آن اجرا می‌شود
PORT=8000

# --- رنگ‌ها برای خروجی ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ۱. چک کردن اینکه آیا URL به عنوان ورودی داده شده است یا نه
if [ -z "$1" ]; then
  echo -e "${YELLOW}خطا: لطفاً آدرس URL اسکریپت را به عنوان ورودی به این اسکریپت بدهید.${NC}"
  echo "مثال: ./proxy.sh https://example.com/script.sh"
  exit 1
fi

URL=$1
FILENAME=$(basename "$URL")

# ۲. ساخت پوشه دانلود و رفتن به آن
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# ۳. دانلود فایل
echo -e "\n${CYAN}در حال دانلود فایل: ${FILENAME}...${NC}"
wget -q -O "$FILENAME" "$URL"
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}خطا: دانلود فایل از آدرس داده شده با شکست مواجه شد.${NC}"
    exit 1
fi
echo -e "${GREEN}دانلود با موفقیت انجام شد.${NC}"

# ۴. چک کردن و اجرای وب‌سرور در پس‌زمینه
if ! pgrep -f "python3 -m http.server $PORT" > /dev/null; then
  echo -e "\n${CYAN}وب‌سرور در حال اجرا نیست. در حال فعال‌سازی روی پورت $PORT...${NC}"
  # اجرای وب‌سرور در پس‌زمینه
  nohup python3 -m http.server $PORT >/dev/null 2>&1 &
  echo -e "${GREEN}وب‌سرور فعال شد. (فراموش نکنید پورت $PORT را در فایروال باز کنید: sudo ufw allow $PORT/tcp)${NC}"
else
  echo -e "\n${GREEN}وب‌سرور از قبل روی پورت $PORT فعال است.${NC}"
fi

# ۵. دریافت IP عمومی سرور خارج
IP_ADDR=$(curl -s ifconfig.me)

# ۶. نمایش دستور نهایی برای سرور ایران
echo -e "\n====================================================================="
echo -e "${YELLOW}دستور زیر را کپی کرده و در سرور ایران خود اجرا کنید:${NC}"
echo -e "=====================================================================\n"

# تشخیص نوع دستور مورد نیاز بر اساس محتوای ورودی کاربر
if [[ "$URL" == *".py"* || "$URL" == *"/restart_scheduler.py"* ]]; then
    # Generate the multi-line command for python scripts that need local modification
    MODIFIED_SCRIPT_URL="http://$IP_ADDR:$PORT/$FILENAME"
    echo -e "${GREEN}sudo bash -c '
    set -e;
    SCRIPT_URL=\"$MODIFIED_SCRIPT_URL\";
    INSTALL_DIR=\"/usr/local/bin\";
    SCRIPT_NAME_IN_PATH=\"restart_scheduler\";
    # ... (rest of the multi-line script logic) ...
    echo \"INFO: Downloading script from your server...\";
    curl -fsSL \\\"\$SCRIPT_URL\\\" -o /tmp/temp_script.py && mv /tmp/temp_script.py \\\"\$INSTALL_DIR/\\\$SCRIPT_NAME_IN_PATH\\\" && chmod +x \\\"\$INSTALL_DIR/\\\$SCRIPT_NAME_IN_PATH\\\";
    \\\"\$INSTALL_DIR/\\\$SCRIPT_NAME_IN_PATH\\\";
    '${NC}\n"
elif [[ "$1" == *"&&"* ]]; then
    # Handle chained commands
    FIRST_PART=$(echo "$1" | awk -F '&&' '{print $1}' | sed 's/curl -O //g' | xargs)
    FILENAME_CHAIN=$(basename "$FIRST_PART")
    MODIFIED_URL="http://$IP_ADDR:$PORT/$FILENAME_CHAIN"
    echo -e "${GREEN}curl -O $MODIFIED_URL && ${1#*&& }${NC}\n"
else
    # Default simple pipe command
    echo -e "${GREEN}bash <(curl -Ls http://$IP_ADDR:$PORT/$FILENAME)${NC}\n"
fi
