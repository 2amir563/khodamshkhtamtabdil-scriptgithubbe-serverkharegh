#!/bin/bash

# --- تنظیمات ---
BASE_DIR="$HOME/dl_files"
CONFIG_FILE="$BASE_DIR/.port_config"

# --- رنگ‌ها ---
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# چک کردن که آیا پوشه اصلی اصلا وجود دارد یا خالی است
if [ ! -d "$BASE_DIR" ] || [ -z "$(ls -A "$BASE_DIR")" ]; then
    echo -e "${YELLOW}پوشه '$BASE_DIR' وجود ندارد یا خالی است. هیچ اسکریپتی برای حذف یافت نشد.${NC}"
    exit 0
fi

echo -e "${CYAN}اسکریپت‌های دانلود شده در سرور شما:${NC}"

# نمایش منوی انتخاب
PS3=$'\n'"${YELLOW}کدام مورد را می‌خواهید حذف کنید؟ (شماره را وارد کنید): ${NC}"
select DIRS in "$BASE_DIR"/*/ "DELETE-ALL-SCRIPTS" "Quit"; do
    case $DIRS in
        "DELETE-ALL-SCRIPTS")
            read -p "آیا از حذف تمام اسکریپت‌ها و پوشه '$BASE_DIR' مطمئن هستید؟ [y/N] " confirm
            if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                # توقف وب‌سرور با پورت ذخیره شده
                if [ -f "$CONFIG_FILE" ]; then
                    PORT=$(cat "$CONFIG_FILE")
                    echo "در حال توقف وب‌سرور روی پورت $PORT..."
                    pkill -f "python3 -m http.server $PORT"
                else
                    echo "فایل تنظیمات پورت یافت نشد. تلاش برای توقف هر وب‌سرور پایتون..."
                    pkill -f "python3 -m http.server"
                fi
                
                rm -rf "$BASE_DIR"
                echo -e "${RED}تمام اسکریپت‌ها و فایل تنظیمات پورت حذف شدند.${NC}"
            else
                echo "عملیات لغو شد."
            fi
            break
            ;;
        "Quit")
            echo "هیچ تغییری ایجاد نشد."
            break
            ;;
        *)
            if [ -d "$DIRS" ]; then
                read -p "آیا از حذف پوشه '$DIRS' مطمئن هستید؟ [y/N] " confirm
                if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
                    rm -rf "$DIRS"
                    echo -e "${RED}پوشه '$DIRS' حذف شد.${NC}"
                else
                    echo "عملیات لغو شد."
                fi
            else
                echo -e "${RED}انتخاب نامعتبر است. لطفاً یک شماره از لیست انتخاب کنید.${NC}"
            fi
            break
            ;;
    esac
done
