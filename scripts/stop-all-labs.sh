#!/usr/bin/env bash
# Stop labs started by run-all-labs.sh.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="${ROOT}/.run-logs"

if [ ! -d "${LOG_DIR}" ]; then
    echo "No PID directory at ${LOG_DIR}. Nothing to stop."
    exit 0
fi

for pidfile in "${LOG_DIR}"/*.pid; do
    [ -f "$pidfile" ] || continue
    pid=$(cat "$pidfile")
    name=$(basename "$pidfile" .pid)
    if kill -0 "$pid" 2>/dev/null; then
        echo "→ Stopping ${name} (pid ${pid})"
        kill "$pid"
    else
        echo "→ ${name} (pid ${pid}) was not running"
    fi
    rm -f "$pidfile"
done
