#!/bin/bash
# A dedicated script to prepare a fully proxied installer for the RGT tunnel.

# --- Settings ---
FILES_DIR="$HOME/rgt-proxied-files"
PORT=8890 # A different port to avoid conflicts

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}--- Preparing a fully proxied installer for RGT Tunnel ---${NC}"

# 1. Create directory
mkdir -p "$FILES_DIR"
cd "$FILES_DIR"

# 2. Define original URLs
MANAGER_SH_URL="https://raw.githubusercontent.com/black-sec/RGT/main/rgt_manager.sh"
ZIP_URL="https://github.com/black-sec/RGT/raw/main/core/RGT-x86-64-linux.zip"
# A slightly different URL is also used in the script
MANAGER_SH_URL_ALT="https://github.com/black-sec/RGT/raw/main/rgt_manager.sh"


# 3. Download the necessary files
echo "Downloading the manager script and the core program file..."
wget -q -O rgt_manager.sh "$MANAGER_SH_URL"
wget -q -O RGT-x86-64-linux.zip "$ZIP_URL"

if [ ! -f "rgt_manager.sh" ] || [ ! -f "RGT-x86-64-linux.zip" ]; then
    echo -e "${RED}Error: Failed to download one or more required files.${NC}"
    exit 1
fi
echo -e "${GREEN}All files downloaded successfully.${NC}"

# 4. Get IP and create the new download URLs
IP_ADDR=$(curl -s ifconfig.me)
NEW_MANAGER_SH_URL="http://$IP_ADDR:$PORT/rgt_manager.sh"
NEW_ZIP_URL="http://$IP_ADDR:$PORT/RGT-x86-64-linux.zip"

# 5. Automatically modify the installer script
echo "Rewriting the installer script to download from this server..."
# Use sed to replace all instances of the original URLs with the new proxy URLs
sed -i "s|$ZIP_URL|$NEW_ZIP_URL|g" rgt_manager.sh
sed -i "s|$MANAGER_SH_URL|$NEW_MANAGER_SH_URL|g" rgt_manager.sh
sed -i "s|$MANAGER_SH_URL_ALT|$NEW_MANAGER_SH_URL|g" rgt_manager.sh
echo -e "${GREEN}Installer script modified successfully.${NC}"

# 6. Start the web server
echo "Starting web server on port $PORT..."
pkill -f "python3 -m http.server $PORT" &>/dev/null
nohup python3 -m http.server $PORT &>/dev/null &
echo -e "${GREEN}Web server is running.${NC}"

# 7. Generate the final command for the Iran server
FINAL_INSTALLER_URL="http://$IP_ADDR:$PORT/rgt_manager.sh"
echo -e "\n====================================================================="
echo -e "${YELLOW}FINAL COMMAND FOR YOUR IRAN SERVER:${NC}"
echo -e "Copy and run this single command on your Iran server."
echo -e "====================================================================="
echo -e "${GREEN}bash <(curl -Ls $FINAL_INSTALLER_URL)${NC}\n"
