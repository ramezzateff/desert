#!/usr/bin/env python3
import argparse
import subprocess
import os
from banner import show_banner
from notify import send_notification
from colors import yellow, cyan, reset, RED, GREEN
from utils import run_bash_script

def main():
    show_banner()

    parser = argparse.ArgumentParser(
        prog="DESERT",
        description="DESERT - Automated Web Recon & Vulnerability Toolkit"
    )

    parser.add_argument("--subenum", action="store_true", help="Run subdomain enumeration")
    parser.add_argument("--crawl", action="store_true", help="Run web crawler")
    parser.add_argument("--scan", action="store_true", help="Run vulnerability scanner")
    parser.add_argument("--notify", action="store_true", help="Send test notification")
    parser.add_argument("--target", type=str, help="Target domain")
    parser.add_argument("--output", type=str, default="results", help="Output folder for results")
    parser.add_argument("--urlgather", action="store_true", help="Run URL gathering using waybackurls, gau, and katana")

    args = parser.parse_args()
    target = args.target
    outdir = args.output
    
    if args.notify:
        """Send Notification into Descord
        """
        send_notification("DESERT Notification", "DESERT TOOL IS FINISHED ✅")

    elif args.subenum:
        print("[+] Running subdomain enumeration...")

    elif args.urlgather:
        print(f"\n{cyan}[🕸️] Starting URL Gathering for: {target}\n")
        run_bash_script(
        "../bash/url_gather.sh",
        [target, outdir],
        f"URL Gathering completed. Results saved to: {outdir}/{target}/urls_sorted.txt",
        "URL gathering script failed to run properly.",
        (cyan, GREEN, RED)
    )

    elif args.crawl:
        print("[+] Running web crawler...")

    elif args.scan:
        print("[+] Running vulnerability scanner...")

    else:
        parser.print_help()

if __name__ == "__main__":
    main()

