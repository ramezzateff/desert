#!/usr/bin/env bash
set -euo pipefail

# Adjust as needed
GOBIN="/usr/local/bin"
GO_TOOLS=(
  "github.com/projectdiscovery/notify/cmd/notify@latest"
  "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
  "github.com/projectdiscovery/httpx/cmd/httpx@latest"
  "github.com/projectdiscovery/katana/cmd/katana@latest"
  "github.com/tomnomnom/waybackurls@latest"
  "github.com/lc/gau/v2/cmd/gau@latest"
  "github.com/PentestPad/subzy@latest"
  # add other go tools you want:
  # "github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
)

echo "[*] Ensure Go is installed..."
if ! command -v go >/dev/null 2>&1; then
  echo "[!] Go not found. Installing golang (apt)..."
  sudo apt update
  sudo apt install -y golang-go
fi

echo "[*] Installing go tools to $GOBIN (requires sudo to write there)..."
for pkg in "${GO_TOOLS[@]}"; do
  echo " -> go install $pkg"
  # install with GOBIN so binary goes straight to /usr/local/bin
  sudo env "GOBIN=${GOBIN}" go install "$pkg"
done

echo "[*] Confirming binaries:"
for pkg in "${GO_TOOLS[@]}"; do
  name=$(basename "${pkg%%@*}")
  if command -v "$name" >/dev/null 2>&1; then
    echo "  ok: $name -> $(command -v $name)"
  else
    echo "  missing: $name"
  fi
done

echo
echo "[*] Other tools (amass, dirsearch, subzy etc.)"
echo "- amass: sudo apt install -y amass (or use snap/install from upstream)"
echo "- dirsearch: pipx install dirsearch OR pip install dirsearch"
echo
echo "[*] DONE. Binaries installed to $GOBIN"

