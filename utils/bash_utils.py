import subprocess
from utils.colors import color_text

def run_bash_script(script_path, args, success_msg, error_msg):
    """
    when run any script in bash in cli.py use FUNCTION!! 
    """
    try:
        subprocess.run(["bash", script_path] + args,
                       check=True,
                       capture_output=True,
                       test=True)
        print(color_text(f"\n[✔] {success_msg}\n"), green)
    except subprocess.CalledProcessError:
        print(color_text(f"[x] {error_msg}"), red)
    except KeyboardInterrupt:
        print(color_text(f"\n[▲] Process interrupted by user."), red)
