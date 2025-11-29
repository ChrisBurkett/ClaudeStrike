#!/usr/bin/env python3
"""
ClaudeStrike with MCP Integration for Kali Linux
Usage: python claude_chat.py [--mcp] [--mcp-server URL]
By: Christopher M. Burkett DBA: ChrisFightsFun
GitHub: https://github.com/ChrisBurkett/ClaudeStrike
"""

import anthropic
import os
import sys
import argparse
import requests
from typing import Optional

# Colors for terminal output
class Colors:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_user(text):
    print(f"\n{Colors.BOLD}{Colors.BLUE}🧑 You:{Colors.RESET} {text}")

def print_claude(text):
    print(f"\n{Colors.BOLD}{Colors.GREEN}🤖 Claude:{Colors.RESET} {text}")

def print_tool(text):
    print(f"{Colors.YELLOW}🔧 {text}{Colors.RESET}")

def print_error(text):
    print(f"{Colors.RED}❌ Error: {text}{Colors.RESET}")

class MCPClient:
    """Client for interacting with MCP Kali server"""
    
    def __init__(self, server_url: str = "http://localhost:5000"):
        self.server_url = server_url
        self.enabled = False
        self.check_connection()
    
    def check_connection(self) -> bool:
        """Check if MCP server is running"""
        try:
            response = requests.get(f"{self.server_url}/health", timeout=2)
            self.enabled = response.status_code == 200
            return self.enabled
        except:
            self.enabled = False
            return False
    
    def execute_command(self, command: str, timeout: int = 30) -> dict:
        """Execute a command via MCP server"""
        if not self.enabled:
            return {"error": "MCP server not connected"}
        
        try:
            response = requests.post(
                f"{self.server_url}/api/command",
                json={"command": command},
                timeout=timeout
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            return {"error": f"Request failed: {str(e)}"}
        except Exception as e:
            return {"error": str(e)}

class ClaudeStrike:
    """Main CLI application"""
    
    def __init__(self, use_mcp: bool = False, mcp_server: str = "http://localhost:5000"):
        # Get API key
        self.api_key = os.environ.get("ANTHROPIC_API_KEY")
        if not self.api_key:
            print_error("ANTHROPIC_API_KEY not found in environment")
            sys.exit(1)
        
        # Initialize Anthropic client
        self.client = anthropic.Anthropic(api_key=self.api_key)
        
        # Initialize MCP if requested
        self.mcp = None
        if use_mcp:
            self.mcp = MCPClient(mcp_server)
            if self.mcp.enabled:
                print_tool(f"MCP connected to {mcp_server} ✓")
            else:
                print_error(f"MCP server not available at {mcp_server}")
                print("Continuing without MCP. Start it with:")
                print("  Terminal 1: kali-server-mcp --port 5000")
                print("  Terminal 2: mcp-server --server http://localhost:5000")
        
        # Conversation history
        self.conversation = []
        
    def detect_command_request(self, text: str) -> Optional[str]:
        """Detect if user is asking to run a command"""
        text_lower = text.lower()
        
        # Direct command indicators
        if text_lower.startswith(("run ", "execute ", "exec ")):
            return text.split(maxsplit=1)[1] if len(text.split()) > 1 else None
        
        # Command-like patterns
        common_tools = ["nmap", "nikto", "gobuster", "dirb", "sqlmap", "hydra", 
                       "netcat", "nc", "curl", "wget", "dig", "whois"]
        
        first_word = text.split()[0] if text.split() else ""
        if first_word in common_tools:
            return text
        
        return None
    
    def run_command(self, command: str) -> str:
        """Execute command via MCP and return results"""
        if not self.mcp or not self.mcp.enabled:
            return f"Cannot execute command. MCP not connected.\nYou can run manually: {command}"
        
        print_tool(f"Executing: {command}")
        result = self.mcp.execute_command(command)
        
        if "error" in result:
            return f"Command failed: {result['error']}"
        
        # The Kali MCP server returns stdout, stderr, return_code
        output = result.get("stdout", "")
        errors = result.get("stderr", "")
        
        combined = ""
        if output:
            combined += output
        if errors:
            combined += f"\n[stderr]: {errors}"
        
        return combined if combined else str(result)
    
    def chat(self, user_message: str) -> str:
        """Send message to Claude and get response"""
        
        # Check if user wants to execute a command
        command = self.detect_command_request(user_message) if self.mcp else None
        
        if command:
            # Execute command and add results to context
            cmd_output = self.run_command(command)
            
            enhanced_message = f"{user_message}\n\nCommand output:\n```\n{cmd_output}\n```"
            self.conversation.append({
                "role": "user",
                "content": enhanced_message
            })
        else:
            self.conversation.append({
                "role": "user",
                "content": user_message
            })
        
        try:
            # Call Claude API
            response = self.client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=4096,
                messages=self.conversation
            )
            
            assistant_message = response.content[0].text
            
            # Add to conversation history
            self.conversation.append({
                "role": "assistant",
                "content": assistant_message
            })
            
            return assistant_message
            
        except Exception as e:
            return f"Error calling Claude API: {e}"
    
    def run(self):
        """Main chat loop"""
        print(f"\n{Colors.BOLD}{Colors.GREEN}{'╔'+'═'*58+'╗'}{Colors.RESET}")
        print(f"{Colors.BOLD}{Colors.GREEN}║{Colors.RESET}  {Colors.BOLD}⚡ ClaudeStrike - AI Pentesting Assistant ⚡{Colors.RESET}     {Colors.BOLD}{Colors.GREEN}║{Colors.RESET}")
        print(f"{Colors.BOLD}{Colors.GREEN}╠{'═'*58}╣{Colors.RESET}")
        print(f"{Colors.BOLD}{Colors.GREEN}║{Colors.RESET}  {Colors.BOLD}{Colors.BLUE}🚀 FULL FEATURES MODE{Colors.RESET}                              {Colors.BOLD}{Colors.GREEN}║{Colors.RESET}")
        print(f"{Colors.BOLD}{Colors.GREEN}║{Colors.RESET}  By: Christopher M. Burkett (ChrisFightsFun)        {Colors.BOLD}{Colors.GREEN}║{Colors.RESET}")
        print(f"{Colors.BOLD}{Colors.GREEN}╚{'═'*58}╝{Colors.RESET}")
        
        if self.mcp and self.mcp.enabled:
            print(f"\n{Colors.GREEN}  ✓ MCP Mode: Commands will be executed automatically{Colors.RESET}")
        else:
            print(f"\n{Colors.YELLOW}  ⚠ Manual Mode: I'll provide guidance only{Colors.RESET}")
        
        print(f"\n{Colors.BOLD}  Commands:{Colors.RESET}")
        print(f"  • Type 'quit' or 'exit' to leave")
        print(f"  • Type 'clear' to clear conversation history")
        print(f"\n{Colors.BOLD}{Colors.GREEN}{'─'*60}{Colors.RESET}\n")
        
        while True:
            try:
                user_input = input(f"{Colors.BOLD}{Colors.BLUE}You:{Colors.RESET} ").strip()
                
                if not user_input:
                    continue
                
                if user_input.lower() in ['quit', 'exit', 'q']:
                    print(f"\n{Colors.GREEN}Goodbye! Happy hacking! 🔐{Colors.RESET}\n")
                    break
                
                if user_input.lower() == 'clear':
                    self.conversation = []
                    print(f"{Colors.YELLOW}Conversation cleared.{Colors.RESET}")
                    continue
                
                # Get Claude's response
                response = self.chat(user_input)
                print_claude(response)
                
            except KeyboardInterrupt:
                print(f"\n\n{Colors.GREEN}👋 Exiting ClaudeStrike. Every command teaches. Every mistake refines! 🔐{Colors.RESET}\n")
                break
            except Exception as e:
                print_error(f"Unexpected error: {e}")

def main():
    parser = argparse.ArgumentParser(
        description="ClaudeStrike - AI pentesting assistant with MCP integration"
    )
    parser.add_argument(
        "--mcp",
        action="store_true",
        help="Enable MCP integration for command execution"
    )
    parser.add_argument(
        "--mcp-server",
        default="http://localhost:5000",
        help="MCP server URL (default: http://localhost:5000)"
    )
    
    args = parser.parse_args()
    
    app = ClaudeStrike(use_mcp=args.mcp, mcp_server=args.mcp_server)
    app.run()

if __name__ == "__main__":
    main()
