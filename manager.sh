#!/bin/bash

# --- Settings ---
BASE_DIR="$HOME/dl_files"
CONFIG_FILE="$BASE_DIR/.port_config"
COMMAND_LOG_FILE="original_command.log"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# --- Functions ---

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
        echo -e "${RED}Input cannot be empty.${NC}"; return
    fi

    URL=$(echo "$USER_INPUT" | grep -oE 'https?://[a-zA-Z0-9./_-]+')
    if [ -z "$URL" ]; then
        echo -e "${RED}Error: No valid URL found.${NC}"; return
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
            echo -e "${RED}Download failed.${NC}"; rm -rf "$TARGET_DIR"; return
        fi
        echo "$USER_INPUT" > "$TARGET_DIR/$COMMAND_LOG_FILE"
        echo -e "${GREEN}Download successful.${NC}"
    fi

    echo -e "\n${YELLOW}--- Dastoor-ha baraye Server-e Iran ---${NC}"
    if [[ "$USER_INPUT" != *"&&"* && "$USER_INPUT" != *"sudo bash -c"* ]]; then
        NEW_DOWNLOAD_URL="http://$(curl -s ifconfig.me):$PORT/$DIR_HASH/$FILENAME"
        echo -e "In yek script-e sade ast. Dastoor-e zir ra mostaghim dar server-e Iran ejra konid:"
        echo -e "\n${GREEN}bash <(curl -Ls $NEW_DOWNLOAD_URL)${NC}"
    else
        NEW_DOWNLOAD_URL="http://$(curl -s ifconfig.me):$PORT/$DIR_HASH/$FILENAME"
        echo -e "\n${YELLOW}In script yek script-e pichide ast. Baraye nasb, 3 dastoor-e zir ra be tartib dar server-e Iran vared konid:${NC}\n"
        echo -e "${CYAN}1. Aval, script ra ba dastoor-e zir download konid:${NC}"
        echo -e "${GREEN}curl -O $NEW_DOWNLOAD_URL${NC}\n"
        echo -e "${CYAN}2. Dovom, file ra ghabele ejra konid:${NC}"
        echo -e "${GREEN}chmod +x $FILENAME${NC}\n"
        echo -e "${CYAN}3. Sevom, script ra mostaghim ejra konid:${NC}"
        echo -e "${GREEN}./$FILENAME${NC}"
    fi
}

list_commands() {
    if [ ! -f "$CONFIG_FILE" ]; then echo -e "${YELLOW}No scripts or port configured.${NC}"; return; fi
    PORT=$(cat "$CONFIG_FILE"); IP_ADDR=$(curl -s ifconfig.me)
    echo -e "\n--- List of Commands for Iran Server ---"
    echo -e "IP: ${CYAN}$IP_ADDR${NC}, Port: ${CYAN}$PORT${NC}\n"
    
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
                    echo -e "${CYAN}2. Make Executable:${NC} ${GREEN}chmod +x $FILENAME${NC}"
                    echo -e "${CYAN}3. Run:${NC} ${GREEN}./$FILENAME${NC}"
                fi
                found_scripts=true
            fi
        fi
    done
    if [ "$found_scripts" = false ]; then echo -e "${YELLOW}No scripts found.${NC}"; fi
}

# --- IMPROVED DELETE FUNCTION ---
delete_script() {
    if [ ! -d "$BASE_DIR" ] || [ -z "$(ls -A "$BASE_DIR")" ]; then
        echo -e "${YELLOW}No scripts to delete.${NC}"; return
    fi

    echo -e "${CYAN}Downloaded scripts:${NC}"
    
    # Build a user-friendly menu with script names
    local options=()
    for dir in "$BASE_DIR"/*/; do
        if [ -d "$dir" ]; then
            local script_file
            script_file=$(find "$dir" -maxdepth 1 -type f -name "*.sh" -o -name "*.py" -o -name "config-installer" -print -quit)
            if [ -n "$script_file" ]; then
                local script_name=$(basename "$script_file")
                options+=("Script: '$script_name' (Directory: $dir)")
            else
                options+=("Unknown Script (Directory: $dir)")
            fi
        fi
    done
    options+=("DELETE-ALL-SCRIPTS" "Back to Main Menu")

    PS3=$'\n'"${YELLOW}Which item do you want to delete? (Enter number): ${NC}"
    select opt in "${options[@]}"; do
        case $opt in
            "DELETE-ALL-SCRIPTS")
                read -p "Delete ALL? [y/N] " confirm; if [[ $confirm == [yY]* ]]; then
                    if [ -f "$CONFIG_FILE" ]; then PORT=$(cat "$CONFIG_FILE"); pkill -f "python3 -m http.server $PORT"; fi
                    rm -rf "$BASE_DIR"; echo -e "${RED}All deleted.${NC}"
                else echo "Canceled."; fi
                break
                ;;
            "Back to Main Menu")
                break
                ;;
            *)
                if [ -n "$opt" ]; then
                    # Extract the directory path from the selected option string
                    local dir_to_delete=$(echo "$opt" | grep -oP '\(Directory: \K[^)]+')
                    
                    read -p "Delete script in '$dir_to_delete'? [y/N] " confirm
                    if [[ $confirm == [yY]* ]]; then
                        rm -rf "$dir_to_delete"
                        echo -e "${RED}Directory '$dir_to_delete' deleted.${NC}"
                    else
                        echo "Canceled."
                    fi
                else
                    echo -e "${RED}Invalid selection.${NC}"
                fi
                break
                ;;
        esac
    done
}

change_port() {
    # (This function remains unchanged)
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
    # (This function remains unchanged)
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
