#!/usr/bin/env python3
import argparse
import subprocess
import sys
from banner import show_banner
from notify import send_notification
from colors import yellow, cyan, reset, RED, GREEN
from utils import run_bash_script
from crawler.core import SkeletonCrawler

def main():
    show_banner()

    parser = argparse.ArgumentParser(
        prog="DESERT",
        description="DESERT - Automated Web Recon & Vulnerability Toolkit"
    )

    # global flags
    parser.add_argument("--target", "-t", type=str, help="Target domain (e.g. example.com)")
    parser.add_argument("--output", "-o", type=str, default="results", help="Output folder for results")
    parser.add_argument("--force", "-f", action="store_true", help="Force re-run (overwrite existing outputs)")
    parser.add_argument("--no-probe", action="store_true", help="Skip active probing (httpx)")

    # actions
    parser.add_argument("--subenum", action="store_true", help="Run subdomain enumeration (passive + optional probe)")
    parser.add_argument("--urlgather", action="store_true", help="Run URL gathering using waybackurls, gau, katana")
    parser.add_argument("--crawl", action="store_true", help="Run web crawler")
    parser.add_argument("--scan", action="store_true", help="Run vulnerability scanner")
    parser.add_argument("--notify", action="store_true", help="Send test notification")

    # show help when called with no args
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(0)

    args = parser.parse_args()
    target = args.target
    outdir = args.output


    # SUBENUM handler
    if args.subenum:
        if not target:
            print(f"{RED}[x] --subenum requires --target. Example: desert --subenum --target example.com{reset}")
            parser.print_help()
            sys.exit(2)

        print(f"\n{cyan}[🕸️] Running subdomain enumeration for: {target}{reset}\n")

        bash_args = [target, outdir]
        if args.force:
            bash_args.append("--force")
        if args.no_probe:
            bash_args.append("--no-probe")

        run_bash_script(
            "../bash/subenum.sh",
            bash_args,
            f"Subdomain enumeration completed. Results saved to: {outdir}/{target}/subenum",
            "Subdomain enumeration script failed to run properly.",
            (cyan, GREEN, RED)
        )
        return

    # URL gathering
    if args.urlgather:
        if not target:
            print(f"{RED}[x] --urlgather requires --target. Example: desert --urlgather --target example.com{reset}")
            parser.print_help()
            sys.exit(2)

        print(f"\n{cyan}[🕸️] Starting URL Gathering for: {target}\n")
        run_bash_script(
            "../bash/url_gather.sh",
            [target, outdir],
            f"URL Gathering completed. Results saved to: {outdir}/{target}/urls_sorted.txt",
            "URL gathering script failed to run properly.",
            (cyan, GREEN, RED)
        )
        return
    # other actions (placeholders)
    if args.crawl:
        if not target:
            print(f"[x] --crawl reuires --target")
            parser.print(help)
            sys.exit(2)

        crawler = SkeletonCrawler(
                max_depth=2,
                max_pages=200,
                outdir=outdir
        )
        crawler.queue.append((target,0))
        crawler.start()
    if args.scan:
        print('.')


    # notify (simple)
    if args.notify:
        send_notification("DESERT Notification", "DESERT TOOL IS FINISHED ✅")
        return



if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{RED}[▲] Interrupted by user.{reset}")
        sys.exit(1)

