#!/usr/bin/env bash
# preflight.sh — run before the talk. Verifies the toolchain, ports, builds,
# smoke-tests each lab, and warms the Trivy DB. Idempotent; safe to re-run.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

FAILED=0
WARNED=0

ok()      { printf "  ${GREEN}✓${NC} %s\n" "$*"; }
warn()    { printf "  ${YELLOW}!${NC} %s\n" "$*"; WARNED=1; }
fail()    { printf "  ${RED}✗${NC} %s\n" "$*"; FAILED=1; }
section() { printf "\n${BOLD}▶ %s${NC}\n" "$*"; }

# ─────────────────────────────────────────────────────────────────────────
section "1/5  Toolchain"

if command -v java >/dev/null 2>&1; then
    JAVA_LINE=$(java -version 2>&1 | head -n1)
    JAVA_MAJOR=$(java -version 2>&1 | head -n1 | sed -E 's/.*"([0-9]+).*/\1/')
    if [ "${JAVA_MAJOR:-0}" -ge 25 ]; then
        ok  "java   ${JAVA_LINE}"
    elif [ "${JAVA_MAJOR:-0}" -ge 18 ]; then
        warn "java   ${JAVA_LINE} (labs target 25; jwebserver is fine)"
    else
        fail "java   ${JAVA_LINE} (need JDK 25; labs will fail to build)"
    fi
else
    fail "java not on PATH"
fi

if command -v jwebserver >/dev/null 2>&1; then
    ok "jwebserver  $(jwebserver --version 2>&1 | head -n1)"
else
    fail "jwebserver not on PATH (bundled with JDK 18+)"
fi

if command -v http >/dev/null 2>&1; then
    ok "http (HTTPie)  $(http --version 2>&1)"
else
    fail "http (HTTPie) not on PATH — 'brew install httpie' / 'apt install httpie'"
fi

if command -v trivy >/dev/null 2>&1; then
    ok "trivy  $(trivy --version 2>&1 | head -n1)"
else
    fail "trivy not on PATH — see https://trivy.dev"
fi

if command -v jq >/dev/null 2>&1; then
    ok "jq     $(jq --version)"
else
    warn "jq not on PATH — a few demo one-liners pipe through jq"
fi

if [ "$FAILED" = "1" ]; then
    printf "\n${RED}Toolchain check failed. Install missing tools and re-run.${NC}\n"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────
section "2/5  Port availability"

PORTS=(8000 8081 8082 8083 8084 9083 9084)
PORT_BLOCKED=0
for p in "${PORTS[@]}"; do
    if lsof -i ":$p" -sTCP:LISTEN -P -n -t >/dev/null 2>&1; then
        pid=$(lsof -i ":$p" -sTCP:LISTEN -P -n -t | head -n1)
        cmd=$(ps -p "$pid" -o comm= 2>/dev/null || echo "?")
        fail "port $p in use (pid $pid: $cmd)"
        PORT_BLOCKED=1
    else
        ok "port $p free"
    fi
done

if [ "$PORT_BLOCKED" = "1" ]; then
    printf "\n${RED}One or more ports are in use. Try:${NC}\n"
    printf "    ./scripts/stop-all-labs.sh\n"
    printf "    pkill -f 'spring-boot:run'\n"
    printf "    pkill -f 'lab-.-.*\\.jar'\n"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────
section "3/5  Package each lab"

LABS=(lab-1-baseline lab-2-sbom lab-3-mgmt-port lab-4-secured)
for name in "${LABS[@]}"; do
    log="/tmp/preflight-${name}-build.log"
    if (cd "labs/$name" && ./mvnw -q -DskipTests package > "$log" 2>&1); then
        jar=$(ls "labs/$name/target/${name}-"*.jar 2>/dev/null | grep -v "\.original" | head -n1)
        if [ -n "$jar" ]; then
            ok "$name  → $(basename "$jar") ($(du -h "$jar" | cut -f1))"
        else
            fail "$name  build succeeded but no jar found"
        fi
    else
        fail "$name  build failed (see $log)"
    fi
done

if [ "$FAILED" = "1" ]; then
    printf "\n${RED}Build failed. Fix before continuing.${NC}\n"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────
section "4/5  Smoke-test each lab"

wait_for_port() {
    local port=$1 max=${2:-40}
    for ((i=1; i<=max; i++)); do
        if (echo > "/dev/tcp/localhost/$port") >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    return 1
}

smoke_test() {
    local name=$1 probe_port=$2 probe_path=$3 auth=${4:-}
    local jar
    jar=$(ls "labs/$name/target/${name}-"*.jar | grep -v "\.original" | head -n1)
    local log="/tmp/preflight-${name}-run.log"
    local pidfile="/tmp/preflight-${name}.pid"

    (cd "labs/$name" && nohup java -jar "$(basename "$jar")" > "$log" 2>&1 &
     echo $! > "$pidfile")
    local pid; pid=$(cat "$pidfile")

    if ! wait_for_port "$probe_port" 40; then
        fail "$name  port $probe_port never opened (see $log)"
        kill "$pid" 2>/dev/null
        rm -f "$pidfile"
        return
    fi

    local status
    if [ -n "$auth" ]; then
        status=$(http -h -a "$auth" GET "localhost:$probe_port/$probe_path" 2>/dev/null \
                 | head -n1 | awk '{print $2}')
    else
        status=$(http -h GET "localhost:$probe_port/$probe_path" 2>/dev/null \
                 | head -n1 | awk '{print $2}')
    fi

    if [ "$status" = "200" ]; then
        ok "$name  GET :$probe_port/$probe_path → 200"
    else
        fail "$name  GET :$probe_port/$probe_path → ${status:-no-response}"
    fi

    kill "$pid" 2>/dev/null
    # Wait briefly for port release so the next lab can bind cleanly.
    for ((i=1; i<=10; i++)); do
        lsof -i ":$probe_port" -sTCP:LISTEN -P -n -t >/dev/null 2>&1 || break
        sleep 1
    done
    rm -f "$pidfile"
}

smoke_test lab-1-baseline   8081  hello
smoke_test lab-2-sbom       8082  actuator/sbom
smoke_test lab-3-mgmt-port  9083  actuator/sbom
smoke_test lab-4-secured    9084  actuator/sbom  admin:changeme

# ─────────────────────────────────────────────────────────────────────────
section "5/5  Pre-warm Trivy vulnerability database"

if trivy --cache-dir "${HOME}/.cache/trivy" image --download-db-only \
        > /tmp/preflight-trivy.log 2>&1; then
    ok "trivy DB downloaded (cached at ~/.cache/trivy)"
else
    warn "trivy DB pre-download had issues (see /tmp/preflight-trivy.log)"
fi

# ─────────────────────────────────────────────────────────────────────────
echo
if [ "$FAILED" = "0" ]; then
    if [ "$WARNED" = "0" ]; then
        printf "${GREEN}${BOLD}✓ All preflight checks passed. Cleared for takeoff.${NC}\n"
    else
        printf "${YELLOW}${BOLD}✓ Preflight passed with warnings (see above).${NC}\n"
    fi
    echo
    echo "Next steps:"
    echo "  Start the deck:  jwebserver -d \"$ROOT/docs\" -p 8000"
    echo "  Run a lab:       cd labs/lab-N-... && ./mvnw spring-boot:run"
    echo "  Run all labs:    ./scripts/run-all-labs.sh"
    echo "  Stop all labs:   ./scripts/stop-all-labs.sh"
    exit 0
else
    printf "${RED}${BOLD}✗ Preflight failed. Fix the items above before going live.${NC}\n"
    exit 1
fi
