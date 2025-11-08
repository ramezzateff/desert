import subprocess
from core.logger import Logger

logger = Logger()
def send_notification(title, message):
    """Send notification and display colored output in console."""
    try:
        command = f'echo "{cyan}{title}{reset}: {yellow}{message}{reset}" | notify -silent'
        subprocess.run(command, shell=True, check=True)
        logger.success(f"[+] Notification sent successfully!")
    except subprocess.CalledProcessError:
        logger.error(f"[-] Failed to send notification. Make sure 'notify' is installed and configured.")
