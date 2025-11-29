#!/bin/bash
#===============================================================================
# ClaudeStrike Updater
# By: Christopher M. Burkett DBA: ChrisFightsFun
# GitHub: https://github.com/ChrisBurkett/ClaudeStrike
#===============================================================================

set -e

# Colors
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
RED='\033[91m'
BOLD='\033[1m'
RESET='\033[0m'

INSTALL_DIR="$HOME/claudestrike"

echo ""
echo -e "${BOLD}${BLUE}⚡ ClaudeStrike Updater${RESET}"
echo ""

# Check if ClaudeStrike is installed
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${RED}ClaudeStrike is not installed at $INSTALL_DIR${RESET}"
    echo "Run the installer first:"
    echo "  curl -sSL https://raw.githubusercontent.com/ChrisBurkett/ClaudeStrike/main/install.sh | bash"
    exit 1
fi

cd "$INSTALL_DIR"

# Check if it's a git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Not a git repository. Cannot update.${RESET}"
    echo "Reinstall ClaudeStrike to enable updates."
    exit 1
fi

# Create backup
echo -e "${BLUE}Creating backup...${RESET}"
BACKUP_DIR="$HOME/claudestrike_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$INSTALL_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✓ Backup saved to: $BACKUP_DIR${RESET}"

# Pull updates
echo -e "${BLUE}Checking for updates...${RESET}"
git fetch origin

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u})

if [ "$LOCAL" = "$REMOTE" ]; then
    echo -e "${GREEN}✓ ClaudeStrike is already up to date!${RESET}"
    
    # Still update desktop launcher and venv
    echo -e "${BLUE}Verifying installation...${RESET}"
else
    echo -e "${YELLOW}Updates available. Pulling changes...${RESET}"
    git pull origin main || git pull origin master
fi

# Recreate virtual environment
echo -e "${BLUE}Updating Python virtual environment...${RESET}"
if [ -d "venv" ]; then
    rm -rf venv
fi
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip > /dev/null 2>&1
pip install anthropic requests > /dev/null 2>&1
deactivate
echo -e "${GREEN}✓ Virtual environment updated${RESET}"

# Update desktop launcher
echo -e "${BLUE}Updating desktop launcher...${RESET}"
DESKTOP_DIR="$HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_DIR/claudestrike.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ClaudeStrike AI Terminal Emulator
Comment=AI-powered pentesting assistant with MCP
Exec=/bin/zsh -i -c "$HOME/claudestrike/start_claudestrike.sh; exec zsh"
Icon=/usr/share/icons/Tango/scalable/apps/terminal.svg
Terminal=true
Categories=kali-resource-development;System;Security;
StartupNotify=true
EOF

update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

# Clear GNOME cache to force menu refresh
rm -rf "$HOME/.cache/gnome-shell/" 2>/dev/null || true

echo -e "${GREEN}✓ Desktop launcher updated${RESET}"
echo -e "${YELLOW}Note: You may need to log out/in to see menu changes${RESET}"

# Make scripts executable
chmod +x start_claudestrike.sh 2>/dev/null || true
chmod +x *.py 2>/dev/null || true
chmod +x *.sh 2>/dev/null || true

echo ""
echo -e "${GREEN}✓ ClaudeStrike updated successfully!${RESET}"
echo ""
echo -e "${YELLOW}If you experience any issues, restore from backup:${RESET}"
echo "  cp -r $BACKUP_DIR/* $INSTALL_DIR/"
echo ""
echo ""
echo -e "${GREEN}✓ ClaudeStrike updated successfully!${RESET}"
echo ""
echo -e "${YELLOW}If you experience any issues, restore from backup:${RESET}"
echo "  cp -r $BACKUP_DIR/* $INSTALL_DIR/"
echo ""
echo -e "${BOLD}Run ClaudeStrike again to use the updated version!${RESET}"
echo ""
