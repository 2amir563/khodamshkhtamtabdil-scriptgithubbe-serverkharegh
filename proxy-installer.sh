#!/bin/bash

# This script automates the entire process of proxying a multi-file installer.

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}--- Starting Fully Automated Proxy Setup ---${NC}"

# --- Settings ---
# Directory to store the proxied files
FILES_DIR="$HOME/proxied-files"
# Port for the web server
PORT=8888

# 1. Create directory
mkdir -p "$FILES_DIR"
cd "$FILES_DIR"

# 2. Download all required files for 3x-ui panel
echo "Downloading necessary files (install.sh, x-ui.tar.gz, x-ui.sh)..."
wget -q -O install.sh https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh
wget -q -O x-ui-linux-amd64.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz
wget -q -O x-ui.sh https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
echo -e "${GREEN}All required files have been downloaded.${NC}"

# 3. Get server IP and create new download URLs
IP_ADDR=$(curl -s ifconfig.me)
TAR_GZ_URL="http://$IP_ADDR:$PORT/x-ui-linux-amd64.tar.gz"
XUI_SH_URL="http://$IP_ADDR:$PORT/x-ui.sh"

# 4. Automatically modify the installer script to use the new URLs
echo "Rewriting install.sh to download from this server..."
# Find the original GitHub URLs in install.sh and replace them with our new proxy URLs
sed -i "s|https://github.com/MHSanaei/3x-ui/releases/download/.*/x-ui-linux-amd64.tar.gz|$TAR_GZ_URL|g" install.sh
sed -i "s|https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh|$XUI_SH_URL|g" install.sh
echo -e "${GREEN}Installer script has been successfully modified.${NC}"

# 5. Start the web server
echo "Starting web server on port ${PORT}..."
# Stop any previous server on the same port to avoid conflicts
pkill -f "python3 -m http.server $PORT" &>/dev/null
# Start the new server in the background
nohup python3 -m http.server $PORT &>/dev/null &
echo -e "${GREEN}Web server is now active.${NC}"

# 6. Generate the final, single command for the Iran server
FINAL_URL="http://$IP_ADDR:$PORT/install.sh"
echo -e "\n====================================================================="
echo -e "${YELLOW}FINAL COMMAND FOR YOUR IRAN SERVER:${NC}"
echo -e "Copy and run this single command on your Iran server."
echo -e "It will install the panel without connecting to GitHub."
echo -e "====================================================================="
echo -e "${GREEN}bash <(curl -Ls $FINAL_URL)${NC}\n"
