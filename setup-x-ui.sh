#!/bin/bash
# This script automates the process of preparing a fully proxied installer for the 3x-ui panel.

# --- Settings ---
FILES_DIR="$HOME/x-ui-proxied-files"
PORT=8888 # You can change this port if you like

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}--- Starting Fully Automated Proxy Setup for x-ui Panel ---${NC}"

# 1. Create a directory and download all necessary files
mkdir -p "$FILES_DIR"
cd "$FILES_DIR"
echo "Downloading necessary files (install.sh, x-ui.tar.gz, x-ui.sh)..."
wget -q -O install.sh https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh
wget -q -O x-ui-linux-amd64.tar.gz https://github.com/MHSanaei/3x-ui/releases/latest/download/x-ui-linux-amd64.tar.gz
wget -q -O x-ui.sh https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh

# Check if all downloads were successful
if [ ! -f "install.sh" ] || [ ! -f "x-ui-linux-amd64.tar.gz" ] || [ ! -f "x-ui.sh" ]; then
    echo -e "${RED}Error: Failed to download one or more required files.${NC}"
    exit 1
fi
echo -e "${GREEN}All required files have been downloaded successfully.${NC}"

# 2. Modify the installer script to disable its internal downloads
echo "Modifying the installer script to prevent it from connecting to GitHub..."
sed -i -e '/releases\/download/ s/^/# /' -e '/x-ui\.sh/ s/^/# /' install.sh
echo -e "${GREEN}Installer script has been successfully modified.${NC}"

# 3. Start the web server
echo "Starting web server on port ${PORT}..."
# Stop any previous server on the same port to avoid conflicts
pkill -f "python3 -m http.server $PORT" &>/dev/null
# Start the new server in the background
nohup python3 -m http.server $PORT &>/dev/null &
echo -e "${GREEN}Web server is now active.${NC}"

# 4. Generate the final, step-by-step instructions for the Iran server
IP_ADDR=$(curl -s ifconfig.me)
echo -e "\n====================================================================="
echo -e "${YELLOW}INSTRUCTIONS FOR YOUR IRAN SERVER:${NC}"
echo -e "Run the following commands one by one on your Iran server."
echo -e "====================================================================="

echo -e "\n${CYAN}Step 1: Download all files from your proxy server:${NC}"
echo -e "${GREEN}curl -O http://$IP_ADDR:$PORT/install.sh"
echo -e "${GREEN}curl -O http://$IP_ADDR:$PORT/x-ui-linux-amd64.tar.gz"
echo -e "${GREEN}curl -O http://$IP_ADDR:$PORT/x-ui.sh${NC}"

echo -e "\n${CYAN}Step 2: Move the files to the correct system locations:${NC}"
echo -e "${GREEN}sudo mv x-ui-linux-amd64.tar.gz /usr/local/"
echo -e "${GREEN}sudo mv x-ui.sh /usr/bin/x-ui-temp${NC}"

echo -e "\n${CYAN}Step 3: Run the installer:${NC}"
echo -e "${GREEN}chmod +x install.sh && bash ./install.sh${NC}\n"
