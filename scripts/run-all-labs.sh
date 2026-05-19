#!/usr/bin/env bash
# Start every lab in the background. Each writes a PID file to /tmp.
# Stop them with stop-all-labs.sh (or `pkill -f 'spring-boot:run'`).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG_DIR="${ROOT}/.run-logs"
mkdir -p "${LOG_DIR}"

for lab in lab-1-baseline lab-2-sbom lab-3-mgmt-port lab-4-secured; do
    echo "→ Starting ${lab}"
    (
        cd "${ROOT}/labs/${lab}"
        nohup ./mvnw -q spring-boot:run >"${LOG_DIR}/${lab}.log" 2>&1 &
        echo $! >"${LOG_DIR}/${lab}.pid"
    )
done

echo
echo "All labs starting in the background. Logs: ${LOG_DIR}/"
echo "  lab-1: http://localhost:8081/hello"
echo "  lab-2: http://localhost:8082/actuator/sbom"
echo "  lab-3: http://localhost:9083/actuator/sbom"
echo "  lab-4: http://localhost:9084/actuator/sbom  (basic auth: admin:changeme)"
