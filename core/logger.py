# Colored + structured console output
#!/usr/bin/python3
from utils.colors import color_text
from datetime import datetime

class Logger:
    def _log(self, level, color, message):
        time = datetime.now().strftime("%H:%M:%S")
        # use color_text before printing
        colored_msg = color_text(message, color)
        print(f"[{level}] {time} | {colored_msg}")

    def info(self, message):
        self._log("INFO", "cyan", message)

    def success(self, message):
        self._log("SUCCESS", "green", message)

    def warning(self, message):
        self._log("WARNING", "yellow", message)

    def error(self, message):
        self._log("ERROR", "red", message)

# single logger instance — import this everywhere:
logger = Logger()
