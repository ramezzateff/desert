# python/crawler/session_manager.py
import requests

def get_session():
    session = requests.Session()
    session.headers.update({
        "User-Agent": "DESERT-Crawler/1.0"
    })
    return session

