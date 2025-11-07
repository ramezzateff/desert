#!/usr/bin/python3
# colors that used in project
COLORS = {
    "red": "\033[91m",
    "green": "\033[92m",
    "yellow": "\033[93m",
    "cyan": "\033[96m",
    "reset": "\033[0m",
}

def color_text(text, color):
    return f"{COLORS.get(color, COLORS['reset'])}{text}{COLORS['reset']}"

