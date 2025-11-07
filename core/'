import yaml
from .constants import CONFIG_PATH

class Config:
    def __init__(self, path=CONFIG_PATH):
        with open(path, "r") as f:
            self.data = yaml.safe_load(f)

    def get(self, key, default=None):
        """Fetch a value safely from config."""
        return self.data.get(key, default)

# Example usage:
# config = Config()
# webhook_url = config.get("notifications.webhook")

