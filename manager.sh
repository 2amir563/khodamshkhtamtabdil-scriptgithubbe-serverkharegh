#!/bin/bash

# --- تنظیمات ---
BASE_DIR="$HOME/dl_files"
CONFIG_FILE="$BASE_DIR/.port_config"

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
        read -p "Enter the port for the web server (default: 8000): " USER_PORT
        PORT=${USER_PORT:-8000}
        echo "$PORT" > "$CONFIG_FILE"
        echo -e "${CYAN}Port set to ${PORT} and saved.${NC}"
    fi

    cd "$BASE_DIR"
    if ! pgrep -f "python3 -m http.server $PORT" > /dev/null; then
      echo -e "\n${CYAN}Starting web server on port $PORT...${NC}"
      nohup python3 -m http.server $PORT >/dev/null 2>&1 &
      echo -e "${GREEN}Web server started.${NC}"
    fi
}

add_script() {
    echo "Please paste the full original installation command:"
    read -r USER_INPUT
    if [ -z "$USER_INPUT" ]; then
        echo -e "${RED}Input cannot be empty.${NC}"
        return
    fi

    URL=$(echo "$USER_INPUT" | grep -oP 'https?://[^\s"''\)\`]+')
    if [ -z "$URL" ]; then
        echo -e "${RED}Error: No valid URL found in your input.${NC}"
        return
    fi
    echo -e "${CYAN}Extracted URL: $URL${NC}"
    
    manage_port_and_server
    PORT=$(cat "$CONFIG_FILE")
    FILENAME=$(basename "$URL")
    DIR_HASH=$(echo -n "$URL" | md5sum | cut -c1-8)
    TARGET_DIR="$BASE_DIR/$DIR_HASH"
    
    if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR"
        echo -e "${CYAN}Downloading: ${FILENAME}...${NC}"
        if ! wget -q -O "$TARGET_DIR/$FILENAME" "$URL"; then
            echo -e "${RED}Error: Download failed.${NC}"; rm -rf "$TARGET_DIR"; return
        fi
        echo -e "${GREEN}Download successful.${NC}"
    fi

    IP_ADDR=$(curl -s ifconfig.me)
    FINAL_URL_PATH="$DIR_HASH/$FILENAME"
    NEW_DOWNLOAD_URL="http://$IP_ADDR:$PORT/$FINAL_URL_PATH"

    # --- Corrected and Simplified Command Generation ---
    # This single line robustly replaces the original URL with the new one in the user's command.
    FINAL_COMMAND=$(echo "$USER_INPUT" | sed "s|$URL|$NEW_DOWNLOAD_URL|")
    # --------------------------------------------------------

    echo -e "\n${YELLOW}--- Automatically Generated Command for Iran Server ---${NC}"
    echo -e "${GREEN}${FINAL_COMMAND}${NC}"
}

list_commands() {
    if [ ! -f "$CONFIG_FILE" ]; then echo -e "${YELLOW}No scripts downloaded or port not set yet.${NC}"; return; fi
    PORT=$(cat "$CONFIG_FILE"); IP_ADDR=$(curl -s ifconfig.me); echo -e "\n--- List of Commands ---"; echo -e "IP: ${CYAN}$IP_ADDR${NC}, Port: ${CYAN}$PORT${NC}\n"
    found_scripts=false
    for dir in "$BASE_DIR"/*/; do
        if [ -d "$dir" ]; then
            for script_path in "$dir"*; do
                if [ -f "$script_path" ]; then
                    relative_path=${script_path#"$BASE_DIR/"}; script_name=$(basename "$script_path")
                    echo -e "${YELLOW}'${script_name}':${NC} ${GREEN}bash <(curl -Ls http://$IP_ADDR:$PORT/$relative_path)${NC}\n"
                    found_scripts=true
                fi; done; fi; done
    if [ "$found_scripts" = false ]; then echo -e "${YELLOW}No scripts found.${NC}"; fi
}

delete_script() {
    if [ ! -d "$BASE_DIR" ] || [ -z "$(ls -A "$BASE_DIR")" ]; then echo -e "${YELLOW}No scripts to delete.${NC}"; return; fi
    PS3=$'\n'"${YELLOW}Which item to delete?: ${NC}"
    select DIRS in "$BASE_DIR"/*/ "DELETE-ALL-SCRIPTS" "Back to Main Menu"; do
        case $DIRS in
            "DELETE-ALL-SCRIPTS")
                read -p "Delete ALL? [y/N] " confirm; if [[ $confirm == [yY]* ]]; then
                    if [ -f "$CONFIG_FILE" ]; then PORT=$(cat "$CONFIG_FILE"); pkill -f "python3 -m http.server $PORT"; fi
                    rm -rf "$BASE_DIR"; echo -e "${RED}All deleted.${NC}"
                else echo "Canceled."; fi; break ;;
            "Back to Main Menu") break ;;
            *)
                if [ -d "$DIRS" ]; then read -p "Delete '$DIRS'? [y/N] " confirm
                    if [[ $confirm == [yY]* ]]; then rm -rf "$DIRS"; echo -e "${RED}Deleted.${NC}";
                    else echo "Canceled."; fi
                else echo -e "${RED}Invalid selection.${NC}"; fi; break ;;
        esac; done
}

change_port() {
    if [ -f "$CONFIG_FILE" ]; then
        OLD_PORT=$(cat "$CONFIG_FILE"); echo "Current: $OLD_PORT"
        if pgrep -f "python3 -m http.server $OLD_PORT" > /dev/null; then
            pkill -f "python3 -m http.server $OLD_PORT"; echo -e "${GREEN}Server stopped.${NC}"
        fi
    fi
    read -p "Enter new port: " NEW_PORT
    if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]] || [ "$NEW_PORT" -lt 1024 ] || [ "$NEW_PORT" -gt 65535 ]; then
        echo -e "${RED}Invalid port.${NC}"; return
    fi
    echo "$NEW_PORT" > "$CONFIG_FILE"; echo -e "${GREEN}Port changed to ${NEW_PORT}.${NC}"
    manage_port_and_server
}

uninstall_manager() {
    read -p "Uninstall manager and all scripts? [y/N] " confirm
    if [[ $confirm == [yY]* ]]; then
        if [ -f "$CONFIG_FILE" ]; then PORT=$(cat "$CONFIG_FILE"); pkill -f "python3 -m http.server $PORT"; fi
        echo -e "\n${YELLOW}To complete, run this command after exit:${NC}"
        echo -e "\n${GREEN}rm -rf \"$BASE_DIR\" \"$0\"${NC}\n"; exit 0
    else echo "Canceled."; fi
}

# --- Main Menu ---
while true; do
    clear
    echo -e "\n${CYAN}--- Script Management Menu ---${NC}"
    echo "1. Add New Script"
    echo "2. List Generated Commands"
    echo "3. Delete a Script / All Scripts"
    echo "4. Change Port"
    echo -e "${RED}5. Uninstall Script Manager${NC}"
    echo "6. Quit"
    read -p "Please select an option [1-6]: " choice
    case $choice in
        1) add_script ;; 2) list_commands ;; 3) delete_script ;; 4) change_port ;;
        5) uninstall_manager ;; 6) exit 0 ;; *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
    if [[ "$choice" != "6" && "$choice" != "5" ]]; then read -p $'\nPress Enter to return...'; fi
done
