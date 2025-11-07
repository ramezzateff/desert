# python/crawler/parser.py
from urllib.parse import urljoin
from bs4 import BeautifulSoup

def extract_links(html, base_url):
    soup = BeautifulSoup(html, "html.parser")
    links = set()
    for a in soup.find_all("a", href=True):
        links.add(urljoin(base_url, a["href"]))
    return list(links)

def extract_forms(html, base_url):
    soup = BeautifulSoup(html, "html.parser")
    forms = []
    for form in soup.find_all("form"):
        f = {"action": urljoin(base_url, form.get("action", "")),
             "method": form.get("method", "get").lower(),
             "inputs": [i.get("name") for i in form.find_all("input")]}
        forms.append(f)
    return forms

