#!/usr/bin/env python3
import json
import time
from core.logger import logger

class SessionManager:
    """
    Manages the runtime state and shared data between modules.
    It acts as a central repository for reconnaissance findings, 
    allowing data to be shared, tracked, and saved for later use.
    """
    def __init__(self, target: str):
        """
        Initializes the session with the target domain and records the start time.
        The core data structure (self.data) is initialized to hold global and module-specific results.
        """
        self.target = target
        # Use time.time() for high-precision timestamp (float)
        self.start_time = time.time() 
        self.data = {
            "target": target,
            "start_time": self.start_time,
            # 'modules' will store dictionaries of results for each module (e.g., 'subenum', 'crawler')
            "modules": {}
        }

    def update(self, module: str, key: str, value):
        """
        Updates the session data for a specific module and key.
        This method ensures that the nested dictionary structure (data -> modules -> module) 
        exists before setting the value, preventing KeyErrors.
        
        Example: session.update("subenum", "subdomains_count", 1500)
        """
        # Ensure 'modules' key exists (redundant but safe)
        self.data.setdefault("modules", {})
        # Ensure the specific module dictionary exists
        self.data["modules"].setdefault(module, {})
        # Set the key/value pair
        self.data["modules"][module][key] = value

    def save(self, path: str):
        """
        Saves the entire session data structure (self.data) to a JSON file.
        This method is critical for persistence, allowing the session to be resumed 
        or analyzed even after the script exits.
        
        It ensures the parent directory exists before attempting to write the file.
        """
        os_path = path
        # ensure parent dir exists
        import os
        parent = os.path.dirname(os_path)
        if parent:
            os.makedirs(parent, exist_ok=True)
        with open(os_path, "w", encoding="utf-8") as f:
            # Use json.dump with indent=2 for human-readable output
            json.dump(self.data, f, indent=2) 
        logger.info(f"Session saved to {os_path}")
