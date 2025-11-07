# python/crawler/core.py
from .downloader import Downloader
from .parser import extract_links, extract_forms
from .utils import save_jsonl, save_json

class SkeletonCrawler:
    def __init__(self, max_depth=2, max_pages=200, outdir="results"):
        self.queue = []
        self.visited = set()
        self.max_depth = max_depth
        self.max_pages = max_pages
        self.outdir = outdir
        self.downloader = Downloader()

    def start(self):
        print("[*] Starting crawler...")
        while self.queue and len(self.visited) < self.max_pages:
            url, depth = self.queue.pop(0)
            if url in self.visited or depth > self.max_depth:
                continue

            print(f"[+] Fetching: {url} (depth={depth})")
            status_code, html, headers, elapsed_ms = self.downloader.fetch(url)
            self.visited.add(url)

            # حفظ visited URL
            save_jsonl(f"{self.outdir}/visited_urls.jsonl",
                       {"url": url, "status": status_code, "elapsed_ms": elapsed_ms})

            if not html:
                continue

            # parse page
            links = extract_links(html, url)
            forms = extract_forms(html, url)

            print(f"    Found {len(links)} links and {len(forms)} forms")

            # حفظ forms
            for form in forms:
                save_jsonl(f"{self.outdir}/forms.jsonl", form)

            # add new links to queue
            for link in links:
                if link not in self.visited:
                    self.queue.append((link, depth + 1))

