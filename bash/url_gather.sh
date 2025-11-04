#!/usr/bin/env bash
# bash/url_gather.sh
# usage: url_gather.sh <target> <outdir>
set -euo pipefail
TARGET="$1"
OUTDIR="$2"
WORK="$OUTDIR/$TARGET"
mkdir -p "$WORK"

echo "[*] URL gathering for $TARGET -> $WORK"

# clear old files
: > "$WORK/urls_raw.txt" 2>/dev/null || true

# 1) waybackurls
if command -v waybackurls >/dev/null 2>&1; then
  echo "[*] running waybackurls..."
  echo "$TARGET" | waybackurls >> "$WORK/urls_raw.txt" || true
else
  echo "[!] waybackurls not installed, skipping."
fi

# 2) gau (getallurls)
if command -v gau >/dev/null 2>&1; then
  echo "[*] running gau..."
  echo "$TARGET" | gau >> "$WORK/urls_raw.txt" || true
else
  echo "[!] gau not installed, skipping."


# 3) katana (JS-aware crawler) - good for dynamic endpoints
if command -v katana >/dev/null 2>&1; then
  echo "[*] running katana (JS-aware crawler)..."
  # katana requires a seed URL; run with moderate depth and common config
  katana -silent -url "https://$TARGET" -o "$WORK/katana_urls.txt" || true
  cat "$WORK/katana_urls.txt" >> "$WORK/urls_raw.txt" || true
else
  echo "[!] katana not installed, skipping."
fi

# 4) simple homepage link grab (fallback)
if command -v curl >/dev/null 2>&1 && command -v pup >/dev/null 2>&1; then
  echo "[*] scraping homepage links (curl + pup fallback)"
  curl -fsSL "https://$TARGET" 2>/dev/null | pup 'a[href] attr{href}' >> "$WORK/urls_raw.txt" || true
# ...

# 5) normalize & dedupe (keep only http/https)
grep -Eo "(https?://[^\"' <>]+)" "$WORK/urls_raw.txt" | \
  sed 's/\/$//' | sort -u > "$WORK/urls_sorted.txt" || true

# 6) filter basic unwanted params (optional)
if [ -f "$OUTDIR/../config/config.yml" ]; then
  # no YAML parsing here; user can run python dedupe for advanced cleaning
  :
fi # <--- تأكد من وجود هذه الكلمة

echo "[*] URL gathering done. outputs:"
echo "    $WORK/urls_raw.txt"
echo "    $WORK/urls_sorted.txt"
echo "    $WORK/katana_urls.txt  (if katana ran)"
