# Handles output directories and result storage

import os
from .constants import OUTPUT_DIR
from .logger import logger

class OutputManager:
    def __init__(self, target):
        self.target_dir = os.path.join(OUTPUT_DIR, target)
        os.makedirs(self.target_dir, exist_ok=True)

    def save(self, filename, content):
        """Save content to a file in the target's output folder."""
        path = os.path.join(self.target_dir, filename)
        with open(path, "w") as f:
            f.write(content)
        logger.success(f"Saved output → {path}")
        return path

