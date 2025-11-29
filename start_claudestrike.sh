#!/bin/bash
#===============================================================================
# ClaudeStrike - AI Pentesting Assistant with MCP Integration
# By: Christopher M. Burkett DBA: ChrisFightsFun
# GitHub: https://github.com/ChrisBurkett/ClaudeStrike
#===============================================================================
# Author line (appears instantly)
echo ""
echo -e "${RED}${BOLD}By: Christopher M. Burkett (ChrisFightsFun)${RESET}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ⚡ ClaudeStrike Launcher ⚡                              ║"
echo "║  AI-Powered Pentesting Assistant                          ║"
echo "║  GitHub.com/ChrisBurkett/ClaudeStrike                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Function to check if kali-server-mcp is running
check_kali_server() {
    pgrep -f "kali_server.py" > /dev/null
}

echo ""

# ============================================================
# CHECK FOR API KEY
# ============================================================
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ ANTHROPIC_API_KEY not found!"
    echo ""
    echo "💡 If you recently added your key:"
    echo -e "   → \e[91m\e[1mClose ALL terminal windows and open a fresh one\e[0m"
    echo "   → Or run: source ~/.zshrc (or ~/.bashrc)"
    echo ""
    echo "Would you like to set it up now?"
    echo ""
    echo "  Get your key from: https://console.anthropic.com"
    echo ""
    read -p "Enter your API key (or press Enter to exit): " api_key
    
    if [ -z "$api_key" ]; then
        echo ""
        echo "👋 Exiting. Run again when you have your API key."
        exit 0
    fi
    
    # Validate key format
    if [[ ! "$api_key" =~ ^sk-ant- ]]; then
        echo ""
        echo "❌ Invalid API key format. Keys should start with 'sk-ant-'"
        exit 1
    fi
    
    # Add to both bash and zsh config files if they exist
    configs_updated=0
    
    if [ -f "$HOME/.bashrc" ]; then
        echo "" >> "$HOME/.bashrc"
        echo "# Anthropic API Key (added by ClaudeStrike)" >> "$HOME/.bashrc"
        echo "export ANTHROPIC_API_KEY=\"$api_key\"" >> "$HOME/.bashrc"
        echo "✅ API key added to ~/.bashrc"
        configs_updated=1
    fi
    
    if [ -f "$HOME/.zshrc" ]; then
        echo "" >> "$HOME/.zshrc"
        echo "# Anthropic API Key (added by ClaudeStrike)" >> "$HOME/.zshrc"
        echo "export ANTHROPIC_API_KEY=\"$api_key\"" >> "$HOME/.zshrc"
        echo "✅ API key added to ~/.zshrc"
        configs_updated=1
    fi
    
    if [ $configs_updated -eq 0 ]; then
        echo "⚠️  No shell config files found!"
        echo "   Manually add to your shell config:"
        echo "   export ANTHROPIC_API_KEY=\"$api_key\""
    fi
    
    # Set for current session
    export ANTHROPIC_API_KEY="$api_key"
    
    echo ""
    echo "📝 Note: Restart your terminal for changes to take effect in new sessions"
    echo ""
    sleep 2
else
    echo "✅ API key found"
fi

#API Key check end

# ============================================================
# CHECK FOR UPDATES
# ============================================================
if [ -d "$HOME/claudestrike/.git" ]; then
    # Fetch remote quietly
    git -C "$HOME/claudestrike" fetch origin --quiet 2>/dev/null || true
    
    LOCAL=$(git -C "$HOME/claudestrike" rev-parse @ 2>/dev/null || echo "")
    REMOTE=$(git -C "$HOME/claudestrike" rev-parse @{u} 2>/dev/null || echo "")
    
    if [ -n "$LOCAL" ] && [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
        echo "🔔 Update available for ClaudeStrike!"
        echo "   Select option [8] to update"
        echo ""
    fi
fi

# ============================================================
# CHECK MCP SERVERS
# ============================================================

# Check if mcp-server is running
#Function to check if mcp-server is running
check_mcp_server() {
    pgrep -f "mcp_server.py" > /dev/null || pgrep -f "kali-mcp" > /dev/null
}

# Check and start kali-server-mcp
if ! check_kali_server; then
    echo "⚠️  Kali server not running. Checking port 5000..."
    
    # Check if port 5000 is in use by something else
    if sudo lsof -i :5000 > /dev/null 2>&1; then
        echo "🔧 Port 5000 in use. Clearing it..."
        sudo fuser -k 5000/tcp > /dev/null 2>&1
        sleep 1
    fi
    
    echo "▶️  Starting kali-server-mcp..."
    nohup kali-server-mcp --port 5000 > /tmp/kali-server-mcp.log 2>&1 &
    sleep 3
    
    if check_kali_server; then
        echo "✅ Kali server started!"
    else
        echo "❌ Failed to start kali server"
        echo "Check logs: tail -f /tmp/kali-server-mcp.log"
        exit 1
    fi
else
    echo "✅ Kali server already running"
fi

# Check and start mcp-server
if ! check_mcp_server; then
    echo "▶️  Starting mcp-server..."
    nohup mcp-server --server http://localhost:5000 > /tmp/mcp-server.log 2>&1 &
    sleep 5
    echo "✅ MCP server started!"
else
    echo "✅ MCP server already running"
fi

echo ""
echo "Select mode:"
echo "  [1] 💰 Cost Optimized (recommended - caching + smart trimming)"
echo "  [2] 🚀 Full Features (no cost limits)"
echo "  [3] 🐛 Debug Mode (troubleshooting)"
echo "  [4] ❌ Quit"
echo ""
echo "  [8] 🔄 Update ClaudeStrike"
echo "  [9] !! 🗑️  Delete API Key !!"
echo ""
echo -n "Choice (auto-starting mode 1 in 5 seconds): "

# Read input with 5 second timeout
read -t 5 choice

# If timeout or enter pressed, default to cost optimized
if [ -z "$choice" ]; then
    choice="1"
fi

# Handle delete API key option
if [ "$choice" = "9" ]; then
    echo ""
    echo "⚠️  WARNING: This will permanently delete your API key from ALL shell config files!"
    echo ""
    read -p "Type 'yes' to confirm deletion (anything else cancels): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo ""
        echo "❌ Deletion cancelled. Your API key is safe."
        echo ""
        exit 0
    fi
    
    echo ""
    echo "🗑️  Deleting API key from all config files..."
    
    configs_cleaned=0
    
    # Remove from .bashrc
    if [ -f "$HOME/.bashrc" ]; then
        if grep -q "ANTHROPIC_API_KEY" "$HOME/.bashrc"; then
            cp "$HOME/.bashrc" "$HOME/.bashrc.backup"
            sed -i '/# Anthropic API Key (added by ClaudeStrike)/d' "$HOME/.bashrc"
            sed -i '/export ANTHROPIC_API_KEY=/d' "$HOME/.bashrc"
            echo "✅ Removed from ~/.bashrc (backup: ~/.bashrc.backup)"
            configs_cleaned=1
        fi
    fi
    
    # Remove from .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "ANTHROPIC_API_KEY" "$HOME/.zshrc"; then
            cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
            sed -i '/# Anthropic API Key (added by ClaudeStrike)/d' "$HOME/.zshrc"
            sed -i '/export ANTHROPIC_API_KEY=/d' "$HOME/.zshrc"
            echo "✅ Removed from ~/.zshrc (backup: ~/.zshrc.backup)"
            configs_cleaned=1
        fi
    fi
    
    if [ $configs_cleaned -eq 0 ]; then
        echo "⚠️  No API key found in any config files"
    fi
    
    # Unset from current session
    unset ANTHROPIC_API_KEY
    
    echo ""
    echo "👋 Restart ClaudeStrike to set a new key"
    echo ""
    exit 0
fi

# Handle quit option
if [ "$choice" = "4" ]; then
    echo ""
    echo "👋 Exiting ClaudeStrike. Every command teaches. Every mistake refines! 🔐"
    exit 0
fi

# Clear screen before starting
clear

RED="\e[91m"
CYAN="\e[96m"
BOLD="\e[1m"
DIM="\e[2m"
RESET="\e[0m"

clear

# --- GitHub line ---
echo -e "${CYAN}${DIM}Updates_at: GitHub.com/ChrisBurkett/ClaudeStrike${RESET}"
echo
sleep 0.5

# --- Header ---
header="C L A U D E S T R I K E   T E R M I N A L   O N L I N E"
len=${#header}

# Type header char by char
echo -ne "${RED}${BOLD}"
for (( i=0; i<len; i++ )); do
    echo -n "${header:$i:1}"
    sleep 0.03
done
echo -e "${RESET}"  # newline

# ===== line directly under header
echo -e "${RED}${BOLD}=======================================================${RESET}"
echo

sleep 0.6

# --- Action line centered and colored ---
actions=("► THINK" "► PROMPT" "► EXECUTE")

# Combine actions for centering
full_line=""
for word in "${actions[@]}"; do
    full_line+="$word    "
done
full_line=${full_line::-4}  # remove trailing spaces
len_actions=${#full_line}

# Calculate left padding for center
pad=$(( (len - len_actions) / 2 ))

# Print each word with color, word by word, centered
printf "%${pad}s" ""   # initial spaces to center
for word in "${actions[@]}"; do
    echo -ne "${CYAN}${BOLD}$word${RESET}    "
    sleep 0.6
done
echo


# Activate venv
cd ~/claudestrike
source venv/bin/activate

# Run based on choice
case $choice in
    2)
        echo "🚀 Starting in FULL FEATURES mode..."
        python claude_chat.py --mcp
        ;;
    3)
        echo "🐛 Starting in DEBUG mode..."
        python claude_chat_debug.py --mcp
        ;;
    *)
        echo "💰 Starting in COST OPTIMIZED mode..."
        python claude_chat_cost.py --mcp
        ;;
esac
