# python/crawler/downloader.py
import requests
from .session_manager import get_session

class Downloader:
    def __init__(self):
        self.session = get_session()

    def fetch(self, url):
        try:
            resp = self.session.get(url, timeout=10)
            return resp.status_code, resp.text, resp.headers, resp.elapsed.total_seconds()*1000
        except requests.RequestException as e:
            print(f"[x] Failed to fetch {url}: {e}")
            return None, None, None, None

