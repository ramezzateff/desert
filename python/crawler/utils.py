# python/crawler/utils.py
import json
import os

def save_jsonl(filepath, data):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, "a") as f:
        f.write(json.dumps(data) + "\n")

def save_json(filepath, data):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, "w") as f:
        json.dump(data, f, indent=2)

