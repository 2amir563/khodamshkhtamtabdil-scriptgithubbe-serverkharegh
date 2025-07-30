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

add_script_simple_proxy() {
    echo -e "\n--- Simple Proxy (For single-file scripts) ---"
    echo "Please paste the full original installation command:"
    read -r USER_INPUT
    if [ -z "$USER_INPUT" ]; then echo -e "${RED}Input cannot be empty.${NC}"; return; fi
    URL=$(echo "$USER_INPUT" | grep -oE 'https?://[a-zA-Z0-9./_-]+')
    if [ -z "$URL" ]; then echo -e "${RED}Error: No valid URL found.${NC}"; return; fi
    echo -e "${CYAN}Extracted URL: $URL${NC}"
    
    manage_port_and_server
    PORT=$(cat "$CONFIG_FILE")
    FILENAME=$(basename "$URL")
    DIR_HASH=$(echo -n "$URL" | md5sum | cut -c1-8)
    TARGET_DIR="$BASE_DIR/$DIR_HASH"
    
    if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR"
        echo -e "${CYAN}Downloading: ${FILENAME}...${NC}"
        if ! wget -q -O "$TARGET_DIR/$FILENAME" "$URL"; then echo -e "${RED}Download failed.${NC}"; rm -rf "$TARGET_DIR"; return; fi
        echo "$USER_INPUT" > "$TARGET_DIR/$COMMAND_LOG_FILE"
        echo -e "${GREEN}Download successful.${NC}"
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
    echo -e "\n--- Full Proxy (For multi-file installers) ---"
    echo "Please paste the full original installation command:"
    read -r USER_INPUT
    if [ -z "$USER_INPUT" ]; then echo -e "${RED}Input cannot be empty.${NC}"; return; fi

    URL=$(echo "$USER_INPUT" | grep -oE 'https?://[a-zA-Z0-9./_-]+')
    if [ -z "$URL" ]; then echo -e "${RED}Error: No valid URL found.${NC}"; return; fi
    echo -e "${CYAN}Extracted URL: $URL${NC}"

    manage_port_and_server
    PORT=$(cat "$CONFIG_FILE")
    IP_ADDR=$(curl -s ifconfig.me)

    DIR_HASH=$(echo -n "$URL" | md5sum | cut -c1-8)
    TARGET_DIR="$BASE_DIR/$DIR_HASH"
    
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}This script has been processed before. Generating command from existing files.${NC}"
    else
        mkdir -p "$TARGET_DIR"
        MODIFIED_SCRIPT_PATH="$TARGET_DIR/$(basename "$URL")"
        echo -e "${CYAN}Downloading main script to ${MODIFIED_SCRIPT_PATH}...${NC}"
        if ! wget -q -O "$MODIFIED_SCRIPT_PATH" "$URL"; then echo -e "${RED}Failed.${NC}"; rm -rf "$TARGET_DIR"; return; fi

        # *** BUG FIX IS HERE ***
        # Save the original command log so the list function can find it
        echo "$USER_INPUT" > "$TARGET_DIR/$COMMAND_LOG_FILE"

        echo -e "${CYAN}Searching for dependencies inside the script...${NC}"
        DEPENDENCY_URLS=$(grep -oE 'https?://[a-zA-Z0-9./_-]+\.(tar\.gz|sh|zip|dat)' "$MODIFIED_SCRIPT_PATH" | sort -u)

        if [ -z "$DEPENDENCY_URLS" ]; then
            echo -e "${YELLOW}No downloadable dependencies found inside. Simple mode would have worked.${NC}"
        else
            for dep_url in $DEPENDENCY_URLS; do
                dep_filename=$(basename "$dep_url")
                echo -e "--> Downloading dependency: ${CYAN}$dep_filename${NC}"
                if ! wget -q -O "$TARGET_DIR/$dep_filename" "$dep_url"; then echo -e "${RED}Failed to download dependency: $dep_url${NC}"; continue; fi
                
                new_dep_url="http://$IP_ADDR:$PORT/$DIR_HASH/$dep_filename"
                sed -i "s|$dep_url|$new_dep_url|g" "$MODIFIED_SCRIPT_PATH"
            done
            echo -e "${GREEN}All dependencies downloaded and main script rewritten successfully.${NC}"
        fi
    fi
    
    FINAL_URL="http://$IP_ADDR:$PORT/$DIR_HASH/$(basename "$URL")"
    echo -e "\n${YELLOW}--- Final Command for Iran Server (Fully Proxied) ---${NC}"
    echo -e "This command will now download everything from your foreign server."
    echo -e "${GREEN}bash <(curl -Ls $FINAL_URL)${NC}"
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

delete_script() {
    if [ ! -d "$BASE_DIR" ] || [ -z "$(ls -A "$BASE_DIR")" ]; then echo -e "${YELLOW}No scripts to delete.${NC}"; return; fi
    local options=()
    for dir in "$BASE_DIR"/*/; do
        if [ -d "$dir" ]; then
            local script_file=$(find "$dir" -maxdepth 1 -type f -print -quit)
            if [ -n "$script_file" ]; then
                # Look for the original command log to get the real script name
                local log_file="$dir/$COMMAND_LOG_FILE"
                if [ -f "$log_file" ]; then
                    local url_in_log=$(grep -oE 'https?://[a-zA-Z0-9./_-]+' "$log_file" | head -n 1)
                    local script_name=$(basename "$url_in_log")
                    options+=("Script: '$script_name' (Dir: ${dir%/})")
                else # Fallback if log is missing
                    options+=("Unknown Script (Dir: ${dir%/})")
                fi
            fi
        fi
    done
    options+=("DELETE-ALL-SCRIPTS" "Back to Main Menu")
    PS3=$'\n'"${YELLOW}Which item to delete?: ${NC}"
    select opt in "${options[@]}"; do
        case $opt in
            "DELETE-ALL-SCRIPTS")
                read -p "Delete ALL? [y/N] " confirm; if [[ $confirm == [yY]* ]]; then
                    if [ -f "$CONFIG_FILE" ]; then PORT=$(cat "$CONFIG_FILE"); pkill -f "python3 -m http.server $PORT"; fi
                    rm -rf "$BASE_DIR"; echo -e "${RED}All deleted.${NC}"
                else echo "Canceled."; fi; break ;;
            "Back to Main Menu") break ;;
            *)
                if [ -n "$opt" ]; then
                    local dir_to_delete=$(echo "$opt" | grep -oP '\(Dir: \K[^)]+')
                    read -p "Delete script in '$dir_to_delete'? [y/N] " confirm
                    if [[ $confirm == [yY]* ]]; then rm -rf "$dir_to_delete"; echo -e "${RED}Deleted.${NC}";
                    else echo "Canceled."; fi
                else echo -e "${RED}Invalid selection.${NC}"; fi; break ;;
        esac
    done
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
    echo "1. Add Script (Simple Proxy - For single files)"
    echo "2. Add Script (Full Proxy - For multi-file installers)"
    echo "3. List Generated Commands"
    echo "4. Delete a Script / All Scripts"
    echo "5. Change Port"
    echo -e "${RED}6. Uninstall Script Manager${NC}"
    echo "7. Quit"
    read -p "Please select an option [1-7]: " choice
    case $choice in
        1) add_script_simple_proxy ;;
        2) add_script_full_proxy ;;
        3) list_commands ;;
        4) delete_script ;;
        5) change_port ;;
        6) uninstall_manager ;;
        7) exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}" ;;
    esac
    if [[ "$choice" -lt 6 ]]; then read -p $'\nPress Enter to return...'; fi
done
