#!/usr/bin/env python3
"""
ClaudeStrike with MCP Integration for Kali Linux
MCP Connection Test Script
By: Christopher M. Burkett DBA: ChrisFightsFun
GitHub: https://github.com/ChrisBurkett/ClaudeStrike
"""

import requests
import json

# Test the MCP connection directly
url = "http://localhost:5000/api/command"
data = {"command": "whoami"}

print("Testing MCP connection...")
print(f"URL: {url}")
print(f"Data: {data}")

try:
    response = requests.post(url, json=data, timeout=5)
    print(f"\nStatus Code: {response.status_code}")
    print(f"Response Text: {response.text}")
    print(f"\nParsed JSON:")
    result = response.json()
    print(json.dumps(result, indent=2))
    print(f"\nStdout: {result.get('stdout')}")
except Exception as e:
    print(f"ERROR: {e}")
