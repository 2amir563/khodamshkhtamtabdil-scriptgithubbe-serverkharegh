#!/bin/bash

# --- تنظیمات ---
BASE_DIR="$HOME/dl_files"
CONFIG_FILE="$BASE_DIR/.port_config"
COMMAND_LOG_FILE="original_command.log"

# --- رنگ‌ها ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# --- توابع ---

manage_port_and_server() {
    mkdir -p "$BASE_DIR"
    if [ -f "$CONFIG_FILE" ]; then
        PORT=$(cat "$CONFIG_FILE")
    else
        read -p "Lotfan port mored nazar ra vared konid (pishfarz: 8000): " USER_PORT
        PORT=${USER_PORT:-8000}
        echo "$PORT" > "$CONFIG_FILE"
        echo -e "${CYAN}Port rooye ${PORT} tanzim va zakhire shod.${NC}"
    fi
    cd "$BASE_DIR"
    if ! pgrep -f "python3 -m http.server $PORT" > /dev/null; then
      echo -e "\n${CYAN}Dar hale راه andazi web server rooye port $PORT...${NC}"
      nohup python3 -m http.server $PORT >/dev/null 2>&1 &
      echo -e "${GREEN}Web server fa'al shod.${NC}"
    fi
}

add_script_simple_proxy() {
    echo -e "\n--- Simple Proxy (Baraye script-haye sade) ---"
    echo "Lotfan dastoor-e nasb-e asli ra vared konid:"
    read -r USER_INPUT
    if [ -z "$USER_INPUT" ]; then echo -e "${RED}Voroodi nemitavanad khali bashad.${NC}"; return; fi
    URL=$(echo "$USER_INPUT" | grep -oE 'https?://[a-zA-Z0-9./_-]+')
    if [ -z "$URL" ]; then echo -e "${RED}Error: URL-e mo'tabari peyda nashod.${NC}"; return; fi
    echo -e "${CYAN}URL-e estekhraj shode: $URL${NC}"
    
    manage_port_and_server
    PORT=$(cat "$CONFIG_FILE")
    FILENAME=$(basename "$URL")
    DIR_HASH=$(echo -n "$URL" | md5sum | cut -c1-8)
    TARGET_DIR="$BASE_DIR/$DIR_HASH"
    
    mkdir -p "$TARGET_DIR"
    echo "$USER_INPUT" > "$TARGET_DIR/$COMMAND_LOG_FILE"

    if [ -f "$TARGET_DIR/$FILENAME" ]; then
        echo -e "${YELLOW}File-e script ghablan download shode ast.${NC}"
    else
        echo -e "${CYAN}Dar hale download: ${FILENAME}...${NC}"
        if ! wget -q -O "$TARGET_DIR/$FILENAME" "$URL"; then echo -e "${RED}Download-e file namovafagh bood.${NC}"; rm -rf "$TARGET_DIR"; return; fi
        echo -e "${GREEN}Download ba movafaghiat anjam shod.${NC}"
    fi

    IP_ADDR=$(curl -s ifconfig.me)
    NEW_DOWNLOAD_URL="http://$IP_ADDR:$PORT/$DIR_HASH/$FILENAME"
    echo -e "\n${YELLOW}--- Dastoor-ha baraye Server-e Iran ---${NC}"
    if [[ "$USER_INPUT" != *"&&"* && "$USER_INPUT" != *"sudo bash -c"* ]]; then
        echo -e "In yek script-e sade ast. Dastoor-e zir ra mostaghim dar server-e Iran ejra konid:"
        echo -e "\n${GREEN}bash <(curl -Ls $NEW_DOWNLOAD_URL)${NC}"
    else
        echo -e "\n${YELLOW}In script yek script-e pichide ast. Baraye nasb, 3 dastoor-e zir ra be tartib dar server-e Iran vared konid:${NC}\n"
        echo -e "${CYAN}1. Aval, script ra ba dastoor-e zir download konid:${NC}"
        echo -e "${GREEN}curl -O $NEW_DOWNLOAD_URL${NC}\n"
        echo -e "${CYAN}2. Dovom, file ra ghabele ejra konid:${NC}"
        echo -e "${GREEN}chmod +x $FILENAME${NC}\n"
        echo -e "${CYAN}3. Sevom, script ra mostaghim ejra konid:${NC}"
        echo -e "${GREEN}./$FILENAME${NC}"
    fi
}

add_script_full_proxy() {
    echo -e "\n--- Full Proxy (Baraye nasb-konandehaye chand file-i) ---"
    echo "Lotfan dastoor-e nasb-e asli ra vared konid:"
    read -r USER_INPUT
    if [ -z "$USER_INPUT" ]; then echo -e "${RED}Voroodi nemitavanad khali bashad.${NC}"; return; fi

    URL=$(echo "$USER_INPUT" | grep -oE 'https?://[a-zA-Z0-9./_-]+')
    if [ -z "$URL" ]; then echo -e "${RED}Error: URL-e mo'tabari peyda nashod.${NC}"; return; fi
    echo -e "${CYAN}URL-e estekhraj shode: $URL${NC}"

    manage_port_and_server
    PORT=$(cat "$CONFIG_FILE")
    IP_ADDR=$(curl -s ifconfig.me)

    DIR_HASH=$(echo -n "$URL" | md5sum | cut -c1-8)
    TARGET_DIR="$BASE_DIR/$DIR_HASH"
    
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}In script ghablan pardazesh shode. Dastoor az file-haye mojood sakhte mishavad.${NC}"
    else
        mkdir -p "$TARGET_DIR"
        echo "$USER_INPUT" > "$TARGET_DIR/$COMMAND_LOG_FILE"
        MODIFIED_SCRIPT_PATH="$TARGET_DIR/$(basename "$URL")"
        echo -e "${CYAN}Dar hale download-e script-e asli be ${MODIFIED_SCRIPT_PATH}...${NC}"
        if ! wget -q -O "$MODIFIED_SCRIPT_PATH" "$URL"; then echo -e "${RED}Namovafagh.${NC}"; rm -rf "$TARGET_DIR"; return; fi

        echo -e "${CYAN}Dar hale jostojoo baraye file-haye vabaste...${NC}"
        DEPENDENCY_URLS=$(grep -oE 'https?://[a-zA-Z0-9./_-]+\.(tar\.gz|sh|zip|dat)' "$MODIFIED_SCRIPT_PATH" | sort -u)

        if [ -z "$DEPENDENCY_URLS" ]; then
            echo -e "${YELLOW}Hich file-e vabaste-i peyda nashod.${NC}"
        else
            for dep_url in $DEPENDENCY_URLS; do
                dep_filename=$(basename "$dep_url")
                echo -e "--> Dar hale download-e file-e vabaste: ${CYAN}$dep_filename${NC}"
                if ! wget -q -O "$TARGET_DIR/$dep_filename" "$dep_url"; then echo -e "${RED}Download-e file-e vabaste namovafagh bood: $dep_url${NC}"; continue; fi
                
                new_dep_url="http://$IP_ADDR:$PORT/$DIR_HASH/$dep_filename"
                sed -i "s|$dep_url|$new_dep_url|g" "$MODIFIED_SCRIPT_PATH"
            done
            echo -e "${GREEN}Tamam-e file-haye vabaste download va script-e asli baznevisi shod.${NC}"
        fi
    fi
    
    FINAL_URL="http://$IP_ADDR:$PORT/$DIR_HASH/$(basename "$URL")"
    echo -e "\n${YELLOW}--- Dastoor-e Nahayi baraye Server-e Iran (Kamelan Proxy Shode) ---${NC}"
    echo -e "In dastoor hala hame chiz ra az server-e kharej-e shoma download mikonad."
    echo -e "${GREEN}bash <(curl -Ls $FINAL_URL)${NC}"
}

list_commands() {
    if [ ! -f "$CONFIG_FILE" ]; then echo -e "${YELLOW}Hanooz scripti ezafe nashode ya port tanzim nashode ast.${NC}"; return; fi
    PORT=$(cat "$CONFIG_FILE"); IP_ADDR=$(curl -s ifconfig.me)
    echo -e "\n--- Liste Dastoor-ha baraye Server-e Iran ---"
    echo -e "IP Address: ${CYAN}$IP_ADDR${NC}, Port: ${CYAN}$PORT${NC}\n"
    
    found_scripts=false
    for dir in "$BASE_DIR"/*/; do
        if [ -d "$dir" ]; then
            LOG_FILE_PATH="$dir/$COMMAND_LOG_FILE"
            if [ -f "$LOG_FILE_PATH" ]; then
                ORIGINAL_CMD=$(cat "$LOG_FILE_PATH")
                URL=$(echo "$ORIGINAL_CMD" | grep -oE 'https?://[a-zA-Z0-9./_-]+')
                FILENAME=$(basename "$URL")
                DIR_HASH=${dir%/}
                DIR_HASH=${DIR_HASH##*/}
                NEW_DOWNLOAD_URL="http://$IP_ADDR:$PORT/$DIR_HASH/$FILENAME"
                echo -e "-----------------------------------------"
                echo -e "${YELLOW}Script: '${FILENAME}'${NC}"
                if [[ "$ORIGINAL_CMD" != *"&&"* && "$ORIGINAL_CMD" != *"sudo bash -c"* ]]; then
                    echo -e "${GREEN}bash <(curl -Ls $NEW_DOWNLOAD_URL)${NC}"
                else
                    echo -e "${CYAN}1. Download:${NC} ${GREEN}curl -O $NEW_DOWNLOAD_URL${NC}"
                    echo -e "${CYAN}2. Ghabele Ejra Kardan:${NC} ${GREEN}chmod +x $FILENAME${NC}"
                    echo -e "${CYAN}3. Ejra:${NC} ${GREEN}./$FILENAME${NC}"
                fi
                found_scripts=true
            fi
        fi
    done
    if [ "$found_scripts" = false ]; then echo -e "${YELLOW}Hich scripti peyda nashod.${NC}"; fi
}

delete_script() {
    if [ ! -d "$BASE_DIR" ] || [ -z "$(ls -A "$BASE_DIR")" ]; then echo -e "${YELLOW}Hich scripti baraye hazf vojood nadarad.${NC}"; return; fi
    local options=()
    for dir in "$BASE_DIR"/*/; do
        if [ -d "$dir" ]; then
            local script_file=$(find "$dir" -maxdepth 1 -type f -print -quit)
            if [ -n "$script_file" ]; then
                local log_file="$dir/$COMMAND_LOG_FILE"
                if [ -f "$log_file" ]; then
                    local url_in_log=$(grep -oE 'https?://[a-zA-Z0-9./_-]+' "$log_file" | head -n 1)
                    local script_name=$(basename "$url_in_log")
                    options+=("Script: '$script_name' (Pooshe: ${dir%/})")
                else
                    options+=("Script-e Nashenakhte (Pooshe: ${dir%/})")
                fi
            fi
        fi
    done
    options+=("HAZF-HAME-SCRIPT-HA" "Bargasht be Menu Asli")
    PS3=$'\n'"${YELLOW}Kodam mored ra mikhahid hazf konid?: ${NC}"
    select opt in "${options[@]}"; do
        case $opt in
            "HAZF-HAME-SCRIPT-HA")
                read -p "Aya motmaen hastid? [y/N] " confirm; if [[ $confirm == [yY]* ]]; then
                    if [ -f "$CONFIG_FILE" ]; then PORT=$(cat "$CONFIG_FILE"); pkill -f "python3 -m http.server $PORT"; fi
                    rm -rf "$BASE_DIR"; echo -e "${RED}Hame hazf shodand.${NC}"
                else echo "Amaliat laghv shod."; fi; break ;;
            "Bargasht be Menu Asli") break ;;
            *)
                if [ -n "$opt" ]; then
                    local dir_to_delete=$(echo "$opt" | grep -oP '\(Pooshe: \K[^)]+')
                    read -p "Aya az hazf-e script dar pooshe-ye '$dir_to_delete' motmaen hastid? [y/N] " confirm
                    if [[ $confirm == [yY]* ]]; then rm -rf "$dir_to_delete"; echo -e "${RED}Hazf shod.${NC}";
                    else echo "Amaliat laghv shod."; fi
                else echo -e "${RED}Entekhab namotabar ast.${NC}"; fi; break ;;
        esac
    done
}

change_port() {
    if [ -f "$CONFIG_FILE" ]; then
        OLD_PORT=$(cat "$CONFIG_FILE"); echo "Port-e fe'li: $OLD_PORT"
        if pgrep -f "python3 -m http.server $OLD_PORT" > /dev/null; then
            pkill -f "python3 -m http.server $OLD_PORT"; echo -e "${GREEN}Web server motevaghef shod.${NC}"
        fi
    fi
    read -p "Port-e jadid ra vared konid: " NEW_PORT
    if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]] || [ "$NEW_PORT" -lt 1024 ] || [ "$NEW_PORT" -gt 65535 ]; then
        echo -e "${RED}Shomare port namotabar ast.${NC}"; return
    fi
    echo "$NEW_PORT" > "$CONFIG_FILE"; echo -e "${GREEN}Port be ${NEW_PORT} taghir yaft.${NC}"; manage_port_and_server
}

uninstall_manager() {
    read -p "Aya mikhahid script-e modiriat va tamam-e file-ha hazf shavad? [y/N] " confirm
    if [[ $confirm == [yY]* ]]; then
        if [ -f "$CONFIG_FILE" ]; then PORT=$(cat "$CONFIG_FILE"); pkill -f "python3 -m http.server $PORT"; fi
        echo -e "\n${YELLOW}Baraye takmil-e amaliat, in dastoor ra bad az khorooj vared konid:${NC}"
        echo -e "\n${GREEN}rm -rf \"$BASE_DIR\" \"$0\"${NC}\n"; exit 0
    else echo "Amaliat laghv shod."; fi
}

# --- منوی اصلی ---
while true; do
    clear
    echo -e "\n${CYAN}--- Menu Asli Modiriat-e Script ---${NC}"
    echo "1. Ezafe Kardan-e Script (Halat-e Sade)"
    echo "2. Ezafe Kardan-e Script (Halat-e Pishrafte - Proxy Kamel)"
    echo "3. Namayesh-e Liste Dastoor-ha"
    echo "4. Hazf-e Script"
    echo "5. Taghir-e Port"
    echo -e "${RED}6. Hazf-e Koli (Uninstall)${NC}"
    echo "7. Khorooj"
    read -p "Lotfan yek gozine ra entekhab konid [1-7]: " choice
    case $choice in
        1) add_script_simple_proxy ;;
        2) add_script_full_proxy ;;
        3) list_commands ;;
        4) delete_script ;;
        5) change_port ;;
        6) uninstall_manager ;;
        7) exit 0 ;;
        *) echo -e "${RED}Gozine namotabar ast.${NC}" ;;
    esac
    if [[ "$choice" -lt 6 ]]; then read -p $'\nBaraye bargasht be menu Enter ra bezanid...'; fi
done
