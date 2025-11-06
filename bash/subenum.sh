#!/usr/bin/env bash
# File: bash/subenum.sh
# Fancy, silent, and clear passive subdomain enumeration + optional httpx probe
# All tools run silently (stdout/stderr -> log)
set -euo pipefail

# -------------------------
# args
# -------------------------
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <domain> <output_base_dir> [--force] [--no-probe]" >&2
  exit 1
fi

DOMAIN="$1"
OUT_BASE="$2"
shift 2

FORCE=0
PROBE=1
while [ "$#" -gt 0 ]; do
  case "$1" in
    --force|-f) FORCE=1 ;;
    --no-probe) PROBE=0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

# -------------------------
# paths
# -------------------------
WORK_DIR="$OUT_BASE/$DOMAIN/subenum"
mkdir -p "$WORK_DIR"

# per-tool artifact files (kept for clarity/audit)
SF_OUT="$WORK_DIR/subfinder.txt"
FD_OUT="$WORK_DIR/findomain.txt"
AS_OUT="$WORK_DIR/assetfinder.txt"
# AM_OUT="$WORK_DIR/amass.txt"
CRT_OUT="$WORK_DIR/crtsh.txt"

SUBFILE="$WORK_DIR/subdomains.txt"
NORM_FILE="$WORK_DIR/subs_for_httpx.txt"
ALIVEFILE="$WORK_DIR/alive.txt"
LOGFILE="$WORK_DIR/subenum.log"
REPORT_JSON="$WORK_DIR/subenum_report.json"
REPORT_HTML="$WORK_DIR/subenum_report.html"

# -------------------------
# config defaults (can be overridden via config/config.yml using yq)
# -------------------------
THREADS=100
TIMEOUT=10
CONFIG_FILE="config/config.yml"

if command -v yq >/dev/null 2>&1 && [ -f "$CONFIG_FILE" ]; then
  THREADS=$(yq e ".subdomain.threads // $THREADS" "$CONFIG_FILE")
  TIMEOUT=$(yq e ".subdomain.timeout // $TIMEOUT" "$CONFIG_FILE")
fi

# prepare log header
printf "%s\n" "[$(date -Iseconds)] START $DOMAIN" >> "$LOGFILE"

# helper log (errors & tool stderr)
log_err() { printf "%s\n" "[$(date -Iseconds)] [ERR] $1" >> "$LOGFILE"; }
log_info() { printf "%s\n" "[$(date -Iseconds)] [INFO] $1" >> "$LOGFILE"; }

# helper to print fancy step header (stdout visible)
step() { printf "⚙️  [%s/%s] %s\n" "$1" "$2" "$3"; }
done_step() { printf "✅ [%s/%s] %s (found: %s)\n" "$1" "$2" "$3" "$4"; }

# tools presence check (logged only)
missing=()
for t in subfinder findomain assetfinder amass curl jq httpx dig; do
  if ! command -v "$t" >/dev/null 2>&1; then
    missing+=("$t")
  fi
done
[ "${#missing[@]}" -gt 0 ] && printf "%s\n" "[$(date -Iseconds)] [WARN] Missing tools: ${missing[*]}" >> "$LOGFILE"

# Fancy header (stdout)
echo "🚀 Starting Subdomain Enumeration for: $DOMAIN"
echo "⚙️ Output Directory: $WORK_DIR"
echo "-----------------------------------------------------"
echo "    Configuration: Threads=$THREADS | Timeout=$TIMEOUT"
[ "$FORCE" -eq 1 ] && echo "    ⚠️ Force mode: ON (will overwrite existing outputs)"
[ "$PROBE" -eq 0 ] && echo "    ⚠️ Probe disabled: --no-probe"
echo "-----------------------------------------------------"

# -------------------------
# cleanup on Ctrl+C (SIGINT)
# -------------------------
cleanup() {
  echo "⚠️ Interrupted! Merging partial results..."
  shopt -s nullglob
  files=( "$SF_OUT" "$FD_OUT" "$AS_OUT" "$AM_OUT" "$CRT_OUT" )
  any=0
  : > "$SUBFILE"
  for f in "${files[@]}"; do
    if [ -f "$f" ]; then
      any=1
      sed 's/^\*\.//; s/,$//' "$f" >> "$SUBFILE"
    fi
  done

  if [ "$any" -eq 1 ]; then
    sort -u "$SUBFILE" -o "$SUBFILE"
    echo "✅ Partial merge done. Subdomains saved to $SUBFILE"
  else
    echo "⚠️ No subdomains collected yet."
  fi

  # Normalize subdomains for httpx if probe enabled
  if [ "$PROBE" -eq 1 ] && command -v httpx >/dev/null 2>&1 && [ -s "$SUBFILE" ]; then
    sed -E 's|^(https?://)?([^/]+).*|https://\2|' "$SUBFILE" | sort -u > "$NORM_FILE"
    echo "⚙️ Running partial httpx probe..."
    if ! httpx -l "$NORM_FILE" -silent -no-color -threads "$THREADS" -timeout "$TIMEOUT" \
        -mc 200,301,302,403,401 -o "$ALIVEFILE" >> "$LOGFILE" 2>&1; then
      echo "⚠️ httpx failed on partial run"
      : > "$ALIVEFILE"
    fi
    ALIVECOUNT=$(wc -l < "$ALIVEFILE" 2>/dev/null || echo 0)
    echo "✅ Partial httpx done (alive: $ALIVECOUNT)"
  fi

  echo "⚠️ Exiting due to Ctrl+C."
  exit 1
}
trap cleanup SIGINT


# -------------------------
# Passive collection (5 steps shown but only run available tools)
# -------------------------
TOTAL_STEPS=5
CURRENT=1

if [ -f "$SUBFILE" ] && [ "$FORCE" -eq 0 ]; then
  # use existing file
  SUBCOUNT=$(wc -l < "$SUBFILE" 2>/dev/null || echo 0)
  echo "⚙️ [${CURRENT}/${TOTAL_STEPS}] Passive collection skipped (existing file)."
  printf "✅ [${CURRENT}/${TOTAL_STEPS}] Using existing subdomains (%s)\n" "$SUBCOUNT"
  CURRENT=$((CURRENT+1))
else
  # Subfinder
  if command -v subfinder >/dev/null 2>&1; then
    step "$CURRENT" "$TOTAL_STEPS" "Running Subfinder..."
    if ! subfinder -d "$DOMAIN" -silent -o "$SF_OUT" >> "$LOGFILE" 2>&1; then
      log_err "subfinder failed for $DOMAIN"
      : > "$SF_OUT"
    fi
    SF_COUNT=$(wc -l < "$SF_OUT" 2>/dev/null || echo 0)
    done_step "$CURRENT" "$TOTAL_STEPS" "Subfinder finished" "$SF_COUNT"
  else
    printf "%s\n" "[$(date -Iseconds)] [WARN] Subfinder not installed (skipped)" >> "$LOGFILE"
    printf "✅ [%s/%s] Subfinder skipped (not installed)\n" "$CURRENT" "$TOTAL_STEPS"
  fi
  CURRENT=$((CURRENT+1))

  # Findomain
  step "$CURRENT" "$TOTAL_STEPS" "Running Findomain..."
  if command -v findomain >/dev/null 2>&1; then
    if ! findomain -t "$DOMAIN" -q -u "$FD_OUT" >> "$LOGFILE" 2>&1; then
      log_err "findomain failed for $DOMAIN"
      : > "$FD_OUT"
    fi
    FD_COUNT=$(wc -l < "$FD_OUT" 2>/dev/null || echo 0)
    done_step "$CURRENT" "$TOTAL_STEPS" "Findomain finished" "$FD_COUNT"
  else
    printf "%s\n" "[$(date -Iseconds)] [WARN] Findomain not installed (skipped)" >> "$LOGFILE"
    printf "✅ [%s/%s] Findomain skipped (not installed)\n" "$CURRENT" "$TOTAL_STEPS"
  fi
  CURRENT=$((CURRENT+1))

  # Assetfinder
  step "$CURRENT" "$TOTAL_STEPS" "Running Assetfinder..."
  if command -v assetfinder >/dev/null 2>&1; then
    if ! assetfinder --subs-only "$DOMAIN" > "$AS_OUT" 2>>"$LOGFILE"; then
      log_err "assetfinder failed for $DOMAIN"
      : > "$AS_OUT"
    fi
    AS_COUNT=$(wc -l < "$AS_OUT" 2>/dev/null || echo 0)
    done_step "$CURRENT" "$TOTAL_STEPS" "Assetfinder finished" "$AS_COUNT"
  else
    printf "%s\n" "[$(date -Iseconds)] [WARN] Assetfinder not installed (skipped)" >> "$LOGFILE"
    printf "✅ [%s/%s] Assetfinder skipped (not installed)\n" "$CURRENT" "$TOTAL_STEPS"
  fi
  CURRENT=$((CURRENT+1))

  # to rerun amass remove first and last line of the block
  : <<'AMASS_BLOCK' ... AMASS_BLOCK 
  # Amass (passive)
  step "$CURRENT" "$TOTAL_STEPS" "Running Amass (passive)..."
  if command -v amass >/dev/null 2>&1; then
    if ! amass enum -passive -d "$DOMAIN" -o "$AM_OUT" >> "$LOGFILE" 2>&1; then
      log_err "amass failed for $DOMAIN"
      : > "$AM_OUT"
    fi
    AM_COUNT=$(wc -l < "$AM_OUT" 2>/dev/null || echo 0)
    done_step "$CURRENT" "$TOTAL_STEPS" "Amass finished" "$AM_COUNT"
  else
    printf "%s\n" "[$(date -Iseconds)] [WARN] Amass not installed (skipped)" >> "$LOGFILE"
    printf "✅ [%s/%s] Amass skipped (not installed)\n" "$CURRENT" "$TOTAL_STEPS"
  fi
  CURRENT=$((CURRENT+1))
AMASS_BLOCK

  # crt.sh
  step "$CURRENT" "$TOTAL_STEPS" "Querying crt.sh..."
  if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    if ! curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" 2>>"$LOGFILE" \
         | jq -r '.[].name_value' 2>>"$LOGFILE" \
         | sed 's/^\*\.//' | sort -u > "$CRT_OUT" 2>>"$LOGFILE"; then
      log_err "crt.sh query failed for $DOMAIN"
      : > "$CRT_OUT"
    fi
    CRT_COUNT=$(wc -l < "$CRT_OUT" 2>/dev/null || echo 0)
    done_step "$CURRENT" "$TOTAL_STEPS" "crt.sh finished" "$CRT_COUNT"
  else
    printf "%s\n" "[$(date -Iseconds)] [WARN] crt.sh query skipped (curl/jq missing)" >> "$LOGFILE"
    printf "✅ [%s/%s] crt.sh skipped (curl/jq missing)\n" "$CURRENT" "$TOTAL_STEPS"
  fi

  # merge & clean into final subdomains file add $AM_OUT
  echo "⚙️ Merging and cleaning results..."
  shopt -s nullglob
  files=( "$SF_OUT" "$FD_OUT" "$AS_OUT" "$CRT_OUT" )
  any=0
  : > "$WORK_DIR/merge_tmp.all"
  for f in "${files[@]}"; do
    if [ -f "$f" ]; then
      any=1
      sed 's/^\*\.//; s/,$//' "$f" >> "$WORK_DIR/merge_tmp.all"
    fi
  done

  if [ "$any" -eq 1 ]; then
    sort -u "$WORK_DIR/merge_tmp.all" | \
      grep -E "^[a-zA-Z0-9._-]+\\.$DOMAIN$" | \
      grep -v -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | \
      grep -v '^$' > "$SUBFILE"
    SUBCOUNT=$(wc -l < "$SUBFILE" 2>/dev/null || echo 0)
  else
    : > "$SUBFILE"
    SUBCOUNT=0
  fi

  # cleanup merge tmp (keep per-tool files)
  rm -f "$WORK_DIR/merge_tmp.all"
fi

# -------------------------
# Wildcard detection (logged)
# -------------------------
if command -v dig >/dev/null 2>&1 && [ -s "$SUBFILE" ]; then
  rnd="$(head /dev/urandom | tr -dc a-z0-9 | head -c8)"
  testhost="${rnd}.${DOMAIN}"
  if dig +short "$testhost" | grep -qE '.'; then
    printf "%s\n" "[$(date -Iseconds)] [WARN] Wildcard DNS likely (test $testhost resolved)" >> "$LOGFILE"
  fi
fi

# Normalize subdomains before probing (ensure https://host format)
sed -E 's|^(https?://)?([^/]+).*|https://\2|' "$SUBFILE" | sort -u > "$NORM_FILE"

# -------------------------
# Active probe (httpx) - silent output, using normalized list
# -------------------------
if [ "$PROBE" -eq 1 ] && command -v httpx >/dev/null 2>&1 && [ -s "$NORM_FILE" ]; then
  if [ -f "$ALIVEFILE" ] && [ "$FORCE" -eq 0 ]; then
    echo "⚙️ httpx probe skipped (existing alive file)"
  else
    echo "⚙️ Running httpx probe (silent)..."
    # Run httpx; redirect outputs to log for debugging
    if ! httpx -l "$NORM_FILE" -silent -no-color -threads "$THREADS" -timeout "$TIMEOUT" \
        -mc 200,301,302,403,401 -o "$ALIVEFILE" >> "$LOGFILE" 2>&1; then
      log_err "httpx failed for $DOMAIN"
      : > "$ALIVEFILE"
    fi

    # Count alive lines safely
    if [ -f "$ALIVEFILE" ] && [ -s "$ALIVEFILE" ]; then
      ALIVECOUNT=$(wc -l < "$ALIVEFILE" 2>/dev/null || echo 0)
    else
      ALIVECOUNT=0
    fi

    echo "✅ httpx probe finished (alive: $ALIVECOUNT)"
  fi
else
  if [ "$PROBE" -eq 0 ]; then
    echo "⚙️ Probe disabled by --no-probe"
  else
    printf "%s\n" "[$(date -Iseconds)] [WARN] httpx not installed or no subdomains to probe" >> "$LOGFILE"
    echo "⚙️ httpx not available; skipping probe"
  fi
fi

# -------------------------
# Reports (quiet write)
# -------------------------
TIMESTAMP="$(date -Iseconds)"
TOTAL_SUBS=$(wc -l < "$SUBFILE" 2>/dev/null || echo 0)
ALIVE_COUNT=$(wc -l < "$ALIVEFILE" 2>/dev/null || echo 0)

if command -v jq >/dev/null 2>&1; then
  jq -n --arg domain "$DOMAIN" --arg ts "$TIMESTAMP" --arg subfile "$SUBFILE" --arg alivefile "$ALIVEFILE" \
    --argjson total_subs "$TOTAL_SUBS" --argjson alive_hosts "$ALIVE_COUNT" \
    '{domain: $domain, timestamp: $ts, statistics:{total_subdomains:$total_subs, alive_hosts:$alive_hosts}, files:{subdomains:$subfile, alive:$alivefile}}' \
    > "$REPORT_JSON" 2>>"$LOGFILE" || log_err "jq failed writing JSON"
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$DOMAIN" "$TIMESTAMP" "$TOTAL_SUBS" "$ALIVE_COUNT" "$SUBFILE" "$ALIVEFILE" <<'PY' > "$REPORT_JSON" 2>>"$LOGFILE"
import sys, json
domain, ts, total_subs, alive_hosts, subfile, alivefile = sys.argv[1:]
print(json.dumps({
  "domain": domain,
  "timestamp": ts,
  "statistics": {"total_subdomains": int(total_subs), "alive_hosts": int(alive_hosts)},
  "files": {"subdomains": subfile, "alive": alivefile}
}, indent=2))
PY
else
  cat > "$REPORT_JSON" <<EOF
{"domain":"$DOMAIN","timestamp":"$TIMESTAMP","statistics":{"total_subdomains":$TOTAL_SUBS,"alive_hosts":$ALIVE_COUNT},"files":{"subdomains":"$SUBFILE","alive":"$ALIVEFILE"}}
EOF
fi

# HTML (quiet)
{
  echo "<html><head><meta charset='utf-8'><title>Subdomain Report - $DOMAIN</title></head><body>"
  echo "<h1>Subdomain Report - $DOMAIN</h1>"
  echo "<p>Generated: $TIMESTAMP</p>"
  echo "<ul><li>Total subdomains: $TOTAL_SUBS</li><li>Alive hosts: $ALIVE_COUNT</li></ul>"
  echo "<h2>Alive Hosts (first 200 lines)</h2><pre>"
  if [ -f "$ALIVEFILE" ]; then sed -n '1,200p' "$ALIVEFILE"; else echo "No alive hosts."; fi
  echo "</pre></body></html>"
} > "$REPORT_HTML" 2>>"$LOGFILE" || printf "%s\n" "[$(date -Iseconds)] [WARN] Failed writing HTML report" >> "$LOGFILE"

# -------------------------
# Final fancy summary (stdout)
# -------------------------
echo "-----------------------------------------------------"
echo "🎉 Finished Subdomain Enumeration for: $DOMAIN"
echo "-----------------------------------------------------"
echo "    → Total Subdomains: $TOTAL_SUBS"
echo "    → Alive Hosts: $ALIVE_COUNT"
echo ""
echo "💾 Results saved (relative): $WORK_DIR"
echo "📝 Log (errors/warnings): $LOGFILE"
echo "-----------------------------------------------------"

exit 0
