import subprocess
from colors import yellow, cyan, reset, RED, GREEN

def send_notification(title, message):
    """Send notification and display colored output in console."""
    try:
        command = f'echo "{cyan}{title}{reset}: {yellow}{message}{reset}" | notify -silent'
        subprocess.run(command, shell=True, check=True)
        print(f"{GREEN}[+] Notification sent successfully!{reset}")
    except subprocess.CalledProcessError:
        print(f"{RED}[-] Failed to send notification. Make sure 'notify' is installed and configured.{reset}")
