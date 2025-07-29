#!/bin/bash

# --- تنظیمات ---
BASE_DIR="$HOME/dl_files"
CONFIG_FILE="$BASE_DIR/.port_config"

# --- رنگ‌ها ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# اطمینان از وجود پوشه اصلی
mkdir -p "$BASE_DIR"

# --- مدیریت حالت‌های مختلف ---
if [[ "$1" == "--change-port" ]]; then
    echo -e "${CYAN}--- حالت تغییر پورت فعال شد ---${NC}"
    if [ -f "$CONFIG_FILE" ]; then
        OLD_PORT=$(cat "$CONFIG_FILE")
        echo "پورت فعلی: $OLD_PORT"
        if pgrep -f "python3 -m http.server $OLD_PORT" > /dev/null; then
            echo "در حال توقف وب‌سرور روی پورت $OLD_PORT..."
            pkill -f "python3 -m http.server $OLD_PORT"
            echo -e "${GREEN}وب‌سرور متوقف شد.${NC}"
        fi
    fi
    read -p "پورت جدید را وارد کنید (مثلا 8080): " NEW_PORT
    if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]] || [ "$NEW_PORT" -lt 1024 ] || [ "$NEW_PORT" -gt 65535 ]; then
        echo -e "${YELLOW}خطا: لطفاً یک شماره پورت معتبر بین 1024 و 65535 وارد کنید.${NC}"
        exit 1
    fi
    echo "$NEW_PORT" > "$CONFIG_FILE"
    echo -e "${GREEN}پورت با موفقیت به ${NEW_PORT} تغییر یافت و ذخیره شد.${NC}"
    echo -e "${CYAN}در حال فعال‌سازی وب‌سرور روی پورت جدید $NEW_PORT...${NC}"
    cd "$BASE_DIR"
    nohup python3 -m http.server "$NEW_PORT" >/dev/null 2>&1 &
    echo -e "${GREEN}وب‌سرور با پورت جدید فعال شد.${NC}"
    exit 0

elif [[ "$1" == "--list" ]]; then
    echo -e "${CYAN}--- لیست دستورهای آماده برای سرور ایران ---${NC}"
    if [ ! -d "$BASE_DIR" ] || [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}هنوز هیچ اسکریپتی دانلود نشده یا پورتی تنظیم نشده است.${NC}"
        exit 0
    fi
    PORT=$(cat "$CONFIG_FILE")
    IP_ADDR=$(curl -s ifconfig.me)
    echo -e "IP Address: ${CYAN}$IP_ADDR${NC}, Port: ${CYAN}$PORT${NC}\n"
    
    found_scripts=false
    for dir in "$BASE_DIR"/*/; do
        if [ -d "$dir" ]; then
            for script_path in "$dir"*; do
                if [ -f "$script_path" ]; then
                    relative_path=${script_path#"$BASE_DIR/"}
                    script_name=$(basename "$script_path")
                    echo -e "${YELLOW}دستور برای '${script_name}':${NC}"
                    echo -e "${GREEN}bash <(curl -Ls http://$IP_ADDR:$PORT/$relative_path)${NC}\n"
                    found_scripts=true
                fi
            done
        fi
    done

    if [ "$found_scripts" = false ]; then
        echo -e "${YELLOW}هیچ اسکریپتی دانلود شده‌ای یافت نشد.${NC}"
    fi
    exit 0
fi

# خواندن پورت از فایل یا پرسیدن برای اولین بار
if [ -f "$CONFIG_FILE" ]; then
    PORT=$(cat "$CONFIG_FILE")
else
    read -p "Enter the port for the web server (default: 8000): " USER_PORT
    PORT=${USER_PORT:-8000}
    echo "$PORT" > "$CONFIG_FILE"
    echo -e "${CYAN}Port set to ${PORT} and saved for future use.${NC}"
fi

# بررسی ورودی URL
if [ -z "$1" ]; then
  echo -e "${YELLOW}خطا: لطفاً آدرس URL اسکریپت را بدهید یا از --change-port یا --list استفاده کنید.${NC}"
  exit 1
fi

URL=$1
FILENAME=$(basename "$URL")
DIR_HASH=$(echo -n "$URL" | md5sum | cut -c1-8)
TARGET_DIR="$BASE_DIR/$DIR_HASH"
FINAL_URL_PATH="$DIR_HASH/$FILENAME"

cd "$BASE_DIR"
if ! pgrep -f "python3 -m http.server $PORT" > /dev/null; then
  echo -e "\n${CYAN}در حال فعال‌سازی وب‌سرور روی پورت $PORT...${NC}"
  nohup python3 -m http.server $PORT >/dev/null 2>&1 &
  echo -e "${GREEN}وب‌سرور فعال شد.${NC}"
else
  echo -e "\n${GREEN}وب‌سرور از قبل روی پورت $PORT فعال است.${NC}"
fi

if [ -d "$TARGET_DIR" ]; then
    echo -e "\n${YELLOW}این URL قبلاً پردازش شده است. از دانلود مجدد صرف‌نظر می‌شود.${NC}"
else
    mkdir -p "$TARGET_DIR"
    echo -e "${CYAN}در حال دانلود فایل: ${FILENAME}...${NC}"
    if ! wget -q -O "$TARGET_DIR/$FILENAME" "$URL"; then
        echo -e "${YELLOW}خطا: دانلود فایل با شکست مواجه شد.${NC}"
        rm -rf "$TARGET_DIR"
        exit 1
    fi
    echo -e "${GREEN}دانلود با موفقیت انجام شد.${NC}"
fi

IP_ADDR=$(curl -s ifconfig.me)
echo -e "\n====================================================================="
echo -e "${YELLOW}دستور زیر را کپی کرده و در سرور ایران خود اجرا کنید:${NC}"
echo -e "=====================================================================\n"
echo -e "${GREEN}bash <(curl -Ls http://$IP_ADDR:$PORT/$FINAL_URL_PATH)${NC}\n"
