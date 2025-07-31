#!/bin/bash
# A dedicated script to prepare a fully proxied installer for the s-ui panel.

# --- Settings ---
FILES_DIR="$HOME/sui-proxied-files"
PORT=8889 # You can change this port
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" || "$ARCH" == "x64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH="arm64"
fi

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}--- Preparing a fully proxied installer for s-ui Panel ---${NC}"

# 1. Create directory
mkdir -p "$FILES_DIR"
cd "$FILES_DIR"

# 2. Find the latest version
echo "Finding the latest version of s-ui panel..."
LAST_VERSION=$(curl -Ls "https://api.github.com/repos/alireza0/s-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$LAST_VERSION" ]; then
    echo -e "${RED}Error: Failed to find the latest version.${NC}"
    exit 1
fi
echo -e "${GREEN}Latest version found: $LAST_VERSION${NC}"

# 3. Download the necessary files
INSTALL_SH_URL="https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh"
TAR_GZ_URL="https://github.com/alireza0/s-ui/releases/download/$LAST_VERSION/s-ui-linux-$ARCH.tar.gz"

echo "Downloading the installer and the main program file..."
wget -q -O install.sh "$INSTALL_SH_URL"
wget -q -O "s-ui-linux-$ARCH.tar.gz" "$TAR_GZ_URL"

if [ ! -f "install.sh" ] || [ ! -f "s-ui-linux-$ARCH.tar.gz" ]; then
    echo -e "${RED}Error: Failed to download one or more required files.${NC}"
    exit 1
fi
echo -e "${GREEN}All files downloaded successfully.${NC}"

# 4. Get IP and create the new download URL for the .tar.gz file
IP_ADDR=$(curl -s ifconfig.me)
NEW_TAR_GZ_URL="http://$IP_ADDR:$PORT/s-ui-linux-$ARCH.tar.gz"

# 5. Automatically modify the installer script
echo "Rewriting the installer script to download from this server..."
# Disable the API call by hardcoding the version we found
sed -i "s/last_version=\$(curl -Ls \"https:\/\/api.github.com\/repos\/alireza0\/s-ui\/releases\/latest\" |.*)/last_version=\"$LAST_VERSION\"/" install.sh
# Replace the GitHub download URL with our proxy URL
sed -i "s|https://github.com/alireza0/s-ui/releases/download/\${last_version}/s-ui-linux-\$(arch).tar.gz|$NEW_TAR_GZ_URL|g" install.sh
echo -e "${GREEN}Installer script modified successfully.${NC}"

# 6. Start the web server
echo "Starting web server on port $PORT..."
pkill -f "python3 -m http.server $PORT" &>/dev/null
nohup python3 -m http.server $PORT &>/dev/null &
echo -e "${GREEN}Web server is running.${NC}"

# 7. Generate the final command for the Iran server
FINAL_INSTALLER_URL="http://$IP_ADDR:$PORT/install.sh"
echo -e "\n====================================================================="
echo -e "${YELLOW}FINAL COMMAND FOR YOUR IRAN SERVER:${NC}"
echo -e "Copy and run this single command on your Iran server."
echo -e "====================================================================="
echo -e "${GREEN}bash <(curl -Ls $FINAL_INSTALLER_URL)${NC}\n"
