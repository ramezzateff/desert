#!/usr/bin/python3
# Reads config.yml

import os

# Base directories
BASE_DIR = os.path.dirname(os.path.dirname(__file__))
OUTPUT_DIR = os.path.join(BASE_DIR, "output")
TEMP_DIR = os.path.join(BASE_DIR, "temp")

# Common tool names, insert any tool you need with the extension of it .py, etc..
TOOLS = {
    "httpx": "httpx",
    "subfinder": "subfinder",
    "amass": "amass",
    "gau": "gau",
}

# Default config file
CONFIG_PATH = os.path.join(BASE_DIR, "config", "config.yml")

