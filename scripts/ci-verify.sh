#!/usr/bin/env bash
# ci-verify.sh — full end-to-end verification of the demo. Expects java,
# http (HTTPie), trivy, jq, and jwebserver on PATH. Used both locally and
# by .github/workflows/verify.yml.
#
# Three phases:
#   1. preflight.sh           — toolchain, ports, builds, smoke-tests, Trivy DB
#   2. Trivy roundtrip        — start lab-4, scan its SBOM, capture output
#   3. Docs serve probe       — jwebserver + http probe of every slide file
#
# Exits 0 on full success, non-zero if any phase fails.
# Trivy CVE findings are captured to trivy-scan.txt but never fail the run.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'
section() { printf "\n${BOLD}▶ %s${NC}\n" "$*"; }
ok()      { printf "  ${GREEN}✓${NC} %s\n" "$*"; }
die()     { printf "  ${RED}✗${NC} %s\n" "$*"; exit 1; }

# Background processes started here get killed on any exit path.
LAB4_PID=""
JWEB_PID=""
cleanup() {
    [ -n "$LAB4_PID" ] && kill "$LAB4_PID" 2>/dev/null || true
    [ -n "$JWEB_PID" ] && kill "$JWEB_PID" 2>/dev/null || true
}
trap cleanup EXIT

wait_for_port() {
    local port=$1 max=${2:-40}
    for ((i=1; i<=max; i++)); do
        (echo > "/dev/tcp/localhost/$port") >/dev/null 2>&1 && return 0
        sleep 1
    done
    return 1
}

# ─────────────────────────────────────────────────────────────────────────
section "Phase 1/3  Preflight"

./scripts/preflight.sh
ok "preflight passed"

# ─────────────────────────────────────────────────────────────────────────
section "Phase 2/3  Trivy roundtrip against lab-4"

LAB4_JAR=$(ls "$ROOT"/labs/lab-4-secured/target/lab-4-secured-*.jar | grep -v "\.original" | head -n1)
[ -n "$LAB4_JAR" ] || die "lab-4-secured jar not found — preflight should have built it"

nohup java -jar "$LAB4_JAR" > /tmp/ci-lab4.log 2>&1 &
LAB4_PID=$!

wait_for_port 9084 60 || { tail -n 30 /tmp/ci-lab4.log; die "lab-4 management port 9084 never opened"; }
ok "lab-4 listening on :9084 (pid $LAB4_PID)"

# Capture full Trivy output. The script exits non-zero on HTTP failure,
# but Trivy itself does not flag CVE findings as errors (no --exit-code).
set +e
./scripts/scan-with-trivy.sh > trivy-scan.txt 2>&1
SCAN_RC=$?
set -e

if [ "$SCAN_RC" -ne 0 ]; then
    echo "--- trivy-scan.txt (last 50 lines) ---"
    tail -n 50 trivy-scan.txt
    die "scan-with-trivy.sh exited $SCAN_RC"
fi
ok "scan-with-trivy.sh completed ($(wc -l < trivy-scan.txt) lines captured)"

kill "$LAB4_PID" 2>/dev/null || true
LAB4_PID=""
# Wait briefly for port release so a re-run doesn't conflict.
for ((i=1; i<=10; i++)); do
    (echo > /dev/tcp/localhost/9084) >/dev/null 2>&1 || break
    sleep 1
done

# ─────────────────────────────────────────────────────────────────────────
section "Phase 3/3  Docs serve probe"

jwebserver -d "$(pwd)/docs" -p 8765 > /tmp/ci-jweb.log 2>&1 &
JWEB_PID=$!
wait_for_port 8765 15 || die "jwebserver never started"

FAILED=0
for f in index.html intro.md lab1.md lab2.md lab3.md lab4.md trivy.md outro.md; do
    status=$(http -h GET "localhost:8765/$f" 2>/dev/null | head -n1 | awk '{print $2}')
    if [ "$status" = "200" ]; then
        ok "docs/$f → 200"
    else
        printf "  ${RED}✗${NC} docs/$f → ${status:-no-response}\n"
        FAILED=1
    fi
done

kill "$JWEB_PID" 2>/dev/null || true
JWEB_PID=""

[ "$FAILED" = "0" ] || die "one or more docs assets did not respond 200"

# ─────────────────────────────────────────────────────────────────────────
echo
printf "${GREEN}${BOLD}✓ ci-verify: presentation is healthy.${NC}\n"
echo "  Trivy scan output: $ROOT/trivy-scan.txt"
