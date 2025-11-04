import subprocess
from colors import cyan, RED, GREEN
def run_bash_script(script_path, args, success_msg, error_msg, colors):
    """
    when run any script in bash in cli.py use FUNCTION!! 
    """
    try:
        subprocess.run(["bash", script_path] + args, check=True)
        print(f"\n{GREEN}[✔] {success_msg}\n")
    except subprocess.CalledProcessError:
        print(f"{RED}[x] {error_msg}")
    except KeyboardInterrupt:
        print(f"\n{RED}[▲] Process interrupted by user.")

