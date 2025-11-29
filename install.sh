#!/bin/bash
#===============================================================================
# ClaudeStrike Installer for Kali Linux
# By: Christopher M. Burkett DBA: ChrisFightsFun
# GitHub: https://github.com/ChrisBurkett/ClaudeStrike
#===============================================================================

set -e  # Exit on any error

# Colors
RED='\033[91m'
GREEN='\033[92m'
YELLOW='\033[93m'
BLUE='\033[94m'
BOLD='\033[1m'
RESET='\033[0m'

INSTALL_DIR="$HOME/claudestrike"
REPO_URL="https://github.com/ChrisBurkett/ClaudeStrike"

echo ""
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║${RESET}  ${BOLD}⚡ ClaudeStrike Installer ⚡${RESET}                       ${BOLD}${GREEN}║${RESET}"
echo -e "${BOLD}${GREEN}║${RESET}  AI-Powered Pentesting Assistant                      ${BOLD}${GREEN}║${RESET}"
echo -e "${BOLD}${GREEN}║${RESET}  By: Christopher M. Burkett                            ${BOLD}${GREEN}║${RESET}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║${RESET}  ${BOLD}• Type 'claudestrike' or 'cstrike' in terminal${RESET} ${BOLD}${GREEN}║${RESET}"
echo -e "${BOLD}${GREEN}║${RESET}  • Search for 'ClaudeStrike' in applications menu (02-Resource Development) ${BOLD}${GREEN}║${RESET}"
echo -e "${BOLD}${GREEN}║${RESET}  • Or run: $INSTALL_DIR/start_claudestrike.sh                            ${BOLD}${GREEN}║${RESET}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${RESET}"


# Check if running on Kali
if [ ! -f /etc/os-release ] || ! grep -q "Kali" /etc/os-release; then
    echo -e "${YELLOW}⚠️  Warning: This installer is designed for Kali Linux${RESET}"
    echo -e "${YELLOW}   It may work on other Debian-based systems but is not tested.${RESET}"
    echo ""
    read -p "Continue anyway? (y/N): " continue
    if [[ ! "$continue" =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Check for git
echo -e "${BLUE}[1/8]${RESET} Checking for git..."
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}   Git not found. Installing...${RESET}"
    sudo apt update
    sudo apt install -y git
fi
echo -e "${GREEN}   ✓ Git found${RESET}"

# Check for Python 3
echo -e "${BLUE}[2/8]${RESET} Checking for Python 3..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}   ✗ Python 3 not found!${RESET}"
    echo "   Install Python 3 and try again: sudo apt install python3 python3-venv"
    exit 1
fi
PYTHON_VERSION=$(python3 --version)
echo -e "${GREEN}   ✓ ${PYTHON_VERSION} found${RESET}"

# Check for mcp-kali-server
echo -e "${BLUE}[3/8]${RESET} Checking for mcp-kali-server..."
if ! command -v kali-server-mcp &> /dev/null; then
    echo -e "${YELLOW}   mcp-kali-server not found. Installing...${RESET}"
    sudo apt update
    sudo apt install -y mcp-kali-server
    echo -e "${GREEN}   ✓ mcp-kali-server installed${RESET}"
else
    echo -e "${GREEN}   ✓ mcp-kali-server already installed${RESET}"
fi

# Clone or update repository
echo -e "${BLUE}[4/8]${RESET} Setting up ClaudeStrike..."
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}   ClaudeStrike directory exists. Updating...${RESET}"
    cd "$INSTALL_DIR"
    
    # Backup user data
    if [ -f "start_claudestrike.sh" ]; then
        echo -e "${YELLOW}   Creating backup of existing installation...${RESET}"
        BACKUP_DIR="$HOME/claudestrike_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        cp -r "$INSTALL_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
        echo -e "${GREEN}   ✓ Backup saved to: $BACKUP_DIR${RESET}"
    fi
    
    # Pull updates
    if [ -d ".git" ]; then
        echo -e "${YELLOW}   Pulling latest updates from GitHub...${RESET}"
        git pull origin main || git pull origin master
    else
        echo -e "${YELLOW}   Directory exists but not a git repo. Re-cloning...${RESET}"
        cd "$HOME"
        rm -rf "$INSTALL_DIR"
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi
else
    echo -e "${YELLOW}   Cloning ClaudeStrike from GitHub...${RESET}"
    git clone "$REPO_URL" "$INSTALL_DIR"
fi
cd "$INSTALL_DIR"
echo -e "${GREEN}   ✓ ClaudeStrike repository ready${RESET}"

# Create virtual environment
echo -e "${BLUE}[5/8]${RESET} Setting up Python virtual environment..."
if [ -d "venv" ]; then
    echo -e "${YELLOW}   Existing venv found. Recreating...${RESET}"
    rm -rf venv
fi
python3 -m venv venv
echo -e "${GREEN}   ✓ Virtual environment created${RESET}"

# Install Python dependencies
echo -e "${BLUE}[6/8]${RESET} Installing Python dependencies..."
source venv/bin/activate

# Install required packages
pip install --upgrade pip > /dev/null 2>&1
pip install anthropic requests > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}   ✓ Python packages installed (anthropic, requests)${RESET}"
else
    echo -e "${RED}   ✗ Failed to install Python packages${RESET}"
    exit 1
fi

deactivate

# Make scripts executable
echo -e "${BLUE}[7/8]${RESET} Configuring scripts..."
chmod +x start_claudestrike.sh 2>/dev/null || true
chmod +x claude_chat.py 2>/dev/null || true
chmod +x claude_chat_debug.py 2>/dev/null || true
chmod +x claude_chat_cost.py 2>/dev/null || true
chmod +x test_mcp.py 2>/dev/null || true
chmod +x preview_headers.sh 2>/dev/null || true
echo -e "${GREEN}   ✓ Scripts configured${RESET}"

# Install desktop launcher
echo -e "${BLUE}[8/8]${RESET} Installing desktop launcher..."
DESKTOP_DIR="$HOME/.local/share/applications"
mkdir -p "$DESKTOP_DIR"

# Use current user's home directory dynamically
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

# Update desktop database
update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

# Clear GNOME cache to force menu refresh
rm -rf "$HOME/.cache/gnome-shell/" 2>/dev/null || true

echo -e "${GREEN}   ✓ Desktop launcher installed${RESET}"
echo -e "${YELLOW}   Note: You may need to log out and back in to see ClaudeStrike in the menu${RESET}"

# Install command-line aliases
echo -e "${BLUE}[9/9]${RESET} Installing command-line aliases..."

# Add aliases to both bash and zsh
if [ -f "$HOME/.bashrc" ]; then
    # Remove old aliases if they exist
    sed -i '/# ClaudeStrike aliases/d' "$HOME/.bashrc"
    sed -i '/alias claudestrike=/d' "$HOME/.bashrc"
    sed -i '/alias cstrike=/d' "$HOME/.bashrc"
    
    # Add new aliases
    echo "" >> "$HOME/.bashrc"
    echo "# ClaudeStrike aliases (added by installer)" >> "$HOME/.bashrc"
    echo "alias claudestrike='$HOME/claudestrike/start_claudestrike.sh'" >> "$HOME/.bashrc"
    echo "alias cstrike='$HOME/claudestrike/start_claudestrike.sh'" >> "$HOME/.bashrc"
fi

if [ -f "$HOME/.zshrc" ]; then
    # Remove old aliases if they exist
    sed -i '/# ClaudeStrike aliases/d' "$HOME/.zshrc"
    sed -i '/alias claudestrike=/d' "$HOME/.zshrc"
    sed -i '/alias cstrike=/d' "$HOME/.zshrc"
    
    # Add new aliases
    echo "" >> "$HOME/.zshrc"
    echo "# ClaudeStrike aliases (added by installer)" >> "$HOME/.zshrc"
    echo "alias claudestrike='$HOME/claudestrike/start_claudestrike.sh'" >> "$HOME/.zshrc"
    echo "alias cstrike='$HOME/claudestrike/start_claudestrike.sh'" >> "$HOME/.zshrc"
fi

echo -e "${GREEN}   ✓ Command aliases installed (claudestrike, cstrike)${RESET}"

# Installation complete

# Installation complete
echo ""
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║${RESET}  ${BOLD}✓ Installation Complete!${RESET}                          ${BOLD}${GREEN}║${RESET}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${BOLD}📁 Installation Directory:${RESET} $INSTALL_DIR"
echo -e "${BOLD}🚀 Launch Methods:${RESET}"
echo "   • Search for 'ClaudeStrike' in your applications menu"
echo "   • Or run: $INSTALL_DIR/start_claudestrike.sh"
echo ""
echo -e "${BOLD}🔑 Next Steps:${RESET}"
echo "   1. Get your Anthropic API key from: https://console.anthropic.com"
echo "   2. Launch ClaudeStrike (it will prompt for your API key)"
echo ""
echo -e "${BOLD}📚 Documentation:${RESET} https://github.com/ChrisBurkett/ClaudeStrike"
echo ""
echo -e "${GREEN}Happy hacking! 🔐⚡${RESET}"
echo ""
