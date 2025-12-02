#!/bin/bash
#===============================================================================
# ClaudeStrike Updater
# By: Christopher M. Burkett DBA: CyberAndFires
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

LOCAL=$(git rev-parse @ 2>/dev/null || echo "")
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")

if [ -z "$LOCAL" ] || [ -z "$REMOTE" ]; then
    echo -e "${RED}✗ Could not check for updates${RESET}"
    echo "Your installation may not be properly set up with git."
    exit 1
fi

if [ "$LOCAL" = "$REMOTE" ]; then
    echo -e "${GREEN}✓ ClaudeStrike is already up to date!${RESET}"
    
    # Still update desktop launcher and venv
    echo -e "${BLUE}Verifying installation...${RESET}"
else
    echo -e "${YELLOW}Updates available. Pulling changes...${RESET}"
    
    # Stash any local changes
    if ! git diff-index --quiet HEAD --; then
        echo -e "${YELLOW}Stashing local changes...${RESET}"
        git stash push -m "ClaudeStrike auto-stash before update"
        STASHED=true
    else
        STASHED=false
    fi
    
    # Pull updates
    if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
        echo -e "${GREEN}✓ Updates downloaded successfully${RESET}"
        
        # Restore stashed changes if any
        if [ "$STASHED" = true ]; then
            echo -e "${YELLOW}Restoring your local changes...${RESET}"
            if git stash pop; then
                echo -e "${GREEN}✓ Local changes restored${RESET}"
                echo -e "${YELLOW}Note: Review any merge conflicts if present${RESET}"
            else
                echo -e "${RED}⚠ Could not restore local changes automatically${RESET}"
                echo -e "${YELLOW}Your changes are saved in: git stash list${RESET}"
                echo -e "${YELLOW}To restore manually: git stash pop${RESET}"
            fi
        fi
    else
        echo -e "${RED}✗ Update failed${RESET}"
        
        # Restore stashed changes
        if [ "$STASHED" = true ]; then
            git stash pop
        fi
        
        echo "Check logs above for details"
        exit 1
    fi
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

# Update command-line aliases
echo -e "${BLUE}Updating command-line aliases...${RESET}"

if [ -f "$HOME/.bashrc" ]; then
    sed -i '/# ClaudeStrike aliases/d' "$HOME/.bashrc"
    sed -i '/alias claudestrike=/d' "$HOME/.bashrc"
    sed -i '/alias cstrike=/d' "$HOME/.bashrc"
    
    echo "" >> "$HOME/.bashrc"
    echo "# ClaudeStrike aliases (added by installer)" >> "$HOME/.bashrc"
    echo "alias claudestrike='$HOME/claudestrike/start_claudestrike.sh'" >> "$HOME/.bashrc"
    echo "alias cstrike='$HOME/claudestrike/start_claudestrike.sh'" >> "$HOME/.bashrc"
fi

if [ -f "$HOME/.zshrc" ]; then
    sed -i '/# ClaudeStrike aliases/d' "$HOME/.zshrc"
    sed -i '/alias claudestrike=/d' "$HOME/.zshrc"
    sed -i '/alias cstrike=/d' "$HOME/.zshrc"
    
    echo "" >> "$HOME/.zshrc"
    echo "# ClaudeStrike aliases (added by installer)" >> "$HOME/.zshrc"
    echo "alias claudestrike='$HOME/claudestrike/start_claudestrike.sh'" >> "$HOME/.zshrc"
    echo "alias cstrike='$HOME/claudestrike/start_claudestrike.sh'" >> "$HOME/.zshrc"
fi

echo -e "${GREEN}✓ Command aliases updated${RESET}"

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
