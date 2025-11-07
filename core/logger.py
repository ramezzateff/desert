# Colored + structured console output
from datetime import datetime
from utils.colors import color_text

class Logger:
    def _log(self, level, message, color):
        now = datetime.now().strftime("%H:%M:%S")
        print(f"[{color_text(level, color)}] {now} | {message}")

    def info(self, message):
        self._log("INFO", message, "cyan")

    def success(self, message):
        self._log("SUCCESS", message, "green")

    def warning(self, message):
        self._log("WARN", message, "yellow")

    def error(self, message):
        self._log("ERROR", message, "red")

logger = Logger()

