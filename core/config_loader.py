#!/usr/bin/python3
import os
import yaml
from .constants import CONFIG_PATH

class ConfigError(Exception):
    pass

class Config:
    def __init__(self, path: str = None):
        """
        Constructor for the Config class. It initializes the path to the config file 
        (using CONFIG_PATH from constants if not provided) and calls the internal 
        loading method to populate self.data.
        """
        self.path = path or CONFIG_PATH
        self.data = {}
        self._load()

    def _load(self):
        """
        Internal method to read the YAML configuration file from the specified path.
        It handles two main cases: 
        1. If the file does not exist, it initializes data as empty ({}) and returns silently.
        2. If the file exists, it attempts to parse it using yaml.safe_load.
           If YAML parsing fails (e.g., file syntax error), it raises a ConfigError.
        """
        if not os.path.exists(self.path):
            self.data = {}
            return
        with open(self.path, "r", encoding="utf-8") as f:
            try:
                # Use 'or {}' to handle empty config files gracefully.
                self.data = yaml.safe_load(f) or {}
            except yaml.YAMLError as e:
                raise ConfigError(f"Failed to parse config file: {e}")

    def reload(self):
        """
        Reloads the configuration data from the file path defined during initialization.
        Useful for applying changes made to the config file after the program has started.
        """
        self._load()

    def save(self, path: str = None):
        """
        Saves the current configuration data (self.data) back to a YAML file.
        It first creates the directory structure if it doesn't exist, then uses 
        yaml.safe_dump to write the content. Allows saving to an optional new path.
        """
        target = path or self.path
        # Ensures the output directory exists before attempting to write the file.
        os.makedirs(os.path.dirname(target), exist_ok=True)
        with open(target, "w", encoding="utf-8") as f:
            yaml.safe_dump(self.data, f)

    def get(self, key: str, default=None):
        """
        Retrieves a value from the configuration using a dot-notation key (e.g., 'subdomain.threads').
        It iterates through the key parts, safely traversing the nested dictionaries.
        Returns the specified default value if the key path is not found or is invalid.
        """
        if not key:
            return default
        parts = key.split(".")
        node = self.data
        for p in parts:
            if isinstance(node, dict) and p in node:
                node = node[p]
            else:
                return default
        return node

    def set(self, key: str, value):
        """
        Sets a specific value in the configuration data using a dot-notation key.
        It automatically creates any necessary intermediate dictionaries along the path.
        The final part of the key is assigned the new value.
        """
        if not key:
            raise ConfigError("Empty key")
        parts = key.split(".")
        node = self.data
        # Traverse the path, creating new dictionaries if they don't exist
        for p in parts[:-1]:
            if p not in node or not isinstance(node[p], dict):
                node[p] = {}
            node = node[p]
        # Set the value at the final part of the path
        node[parts[-1]] = value

    def merge(self, overrides: dict):
        """
        Deeply merges a dictionary of new settings (overrides) into the existing configuration (self.data).
        It is used to apply settings from command-line arguments or environment variables.
        If a value is a dictionary in both the current data and the override, it recursively merges them; 
        otherwise, it overwrites the value.
        """
        def _merge(a, b):
            for k, v in b.items():
                if k in a and isinstance(a[k], dict) and isinstance(v, dict):
                    # Recursive merge for nested dictionaries
                    _merge(a[k], v)
                else:
                    # Overwrite for non-dictionary values
                    a[k] = v
        _merge(self.data, overrides)

    def as_dict(self):
        """
        Returns a copy of the configuration data as a standard Python dictionary.
        This is useful for passing the configuration data to other functions or modules 
        without allowing them to modify the original instance data directly.
        """
        return self.data.copy()
