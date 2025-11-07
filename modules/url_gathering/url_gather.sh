#!/usr/bin/env bash
# ============================================================
# URL Gathering Module - desert toolkit (passive-only)
# Usage: url_gather.sh <target_or_file> <output_dir> [threads]
# - Passive sources only: waybackurls, gau
# - No crawling, no analyzers (linkfinder, mantra, arjun) — those run in --crawl
# ============================================================

set -euo pipefail

INPUT="$1"
OUTDIR="$2"
THREADS="${3:-5}"  # optional parallelism for targets
TARGETS=()

# --------------------------
# 1. Input handling
# --------------------------
if [[ -f "$INPUT" ]]; then
    echo "[*] Reading targets from file: $INPUT"
    mapfile -t TARGETS < "$INPUT"
elif [[ -n "$INPUT" ]]; then
    TARGETS+=("$INPUT")
else
    echo "Usage: $0 <target_domain_or_file> <output_dir> [threads]"
    exit 1
fi

mkdir -p "$OUTDIR"

# --------------------------
# 2. URL collection for one target (passive sources only)
# --------------------------
collect_urls() {
    local TARGET="$1"
    local WORK="$OUTDIR/$TARGET"
    mkdir -p "$WORK"

    printf "\n=== URL gathering for: %s ===\n" "$TARGET"

    local RAW="$WORK/urls_raw.txt"
    local SORTED="$WORK/urls_sorted.txt"
    : > "$RAW"
    : > "$SORTED"

    # --- Waybackurls ---
    if command -v waybackurls >/dev/null 2>&1; then
        printf "[*] waybackurls\n"
        echo "$TARGET" | waybackurls >> "$RAW" 2>/dev/null || true
    else
        printf "[!] waybackurls not installed (skipping)\n"
    fi

    # --- gau ---
    if command -v gau >/dev/null 2>&1; then
        printf "[*] gau\n"
        echo "$TARGET" | gau >> "$RAW" 2>/dev/null || true
    else
        printf "[!] gau not installed (skipping)\n"
    fi

    # --------------------------
    # Cleanup & filtering
    # --------------------------
    printf "[*] Normalizing and deduplicating URLs...\n"
    # extract urls, remove trailing slash, dedupe
    grep -Eo "(https?://[^\"' <>]+)" "$RAW" 2>/dev/null | sed 's/\/$//' | sort -u > "$SORTED" || true

    if ! [ -s "$SORTED" ]; then
        printf "[!] No URLs found for %s.\n" "$TARGET"
        return
    fi

    # --------------------------
    # Categorization (save lists only)
    # --------------------------
    printf "[*] Extracting JS and PHP file URLs (saved, analyzers disabled)...\n"
    grep -Ei '\.js(\?.*)?$' "$SORTED" | sort -u > "$WORK/js_urls.txt" || true
    grep -Ei '\.php(\?.*)?$' "$SORTED" | sort -u > "$WORK/php_urls.txt" || true

    # final urls_sorted
    cp "$SORTED" "$WORK/urls_sorted.txt"

    printf "[✓] Done: %s → %s/\n" "$TARGET" "$WORK"
}

# --------------------------
# 3. Main loop (parallel support)
# --------------------------
for TARGET in "${TARGETS[@]}"; do
    collect_urls "$TARGET" &
    # simple job throttle
    while [[ $(jobs -r -p | wc -l) -ge $THREADS ]]; do
        wait -n
    done
done
wait

echo "================================================="
echo "[✓] URL gathering completed for all targets."
echo "Results saved in: $OUTDIR/"

