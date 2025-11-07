# Handles runtime states and sessions
import json
import time
from .logger import logger

class SessionManager:
    def __init__(self, target):
        self.target = target
        self.start_time = time.time()
        self.data = {"target": target, "modules": {}}

    def update(self, module, key, value):
        """Store a piece of data related to a module."""
        self.data.setdefault(module, {})[key] = value

    def save(self, path):
        with open(path, "w") as f:
            json.dump(self.data, f, indent=2)
        logger.info(f"Session saved to {path}")

