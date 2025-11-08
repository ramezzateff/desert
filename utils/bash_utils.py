import subprocess

from core.logger import logger


def run_bash_script(script_path, args, success_msg, error_msg):
    """
    when run any script in bash in Desert.py use FUNCTION!! 
    """
    try:
        subprocess.run(["bash", script_path] + args, check=True)
        logger.success(f"\n[✔] {success_msg}\n")
    
    except subprocess.CalledProcessError:
        logger.error(f"[x] {error_msg}")
    
    except KeyboardInterrupt:
        logger.error(f"\n[▲] Process interrupted by user.")
