#!/usr/bin/env bash
# Pull the SBOM from a running lab-4 instance and pipe it through Trivy.
#
# Assumes lab-4-secured is running on its default ports (8084 app / 9084 mgmt)
# and the default ACTUATOR_PASSWORD ("changeme") is in effect.

set -euo pipefail

MGMT_HOST="${MGMT_HOST:-localhost}"
MGMT_PORT="${MGMT_PORT:-9084}"
ACTUATOR_USER="${ACTUATOR_USER:-admin}"
ACTUATOR_PASSWORD="${ACTUATOR_PASSWORD:-changeme}"

URL="http://${MGMT_HOST}:${MGMT_PORT}/actuator/sbom/application"

for tool in http trivy; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: '$tool' is not installed or not on PATH." >&2
        echo "       Install: HTTPie -> https://httpie.io   Trivy -> https://trivy.dev" >&2
        exit 1
    fi
done

echo "→ Fetching SBOM from ${URL}"
echo "→ Scanning with: $(trivy --version | head -n1)"
echo

# Explicit GET because HTTPie defaults to POST when -a (auth) is set.
http --check-status --print=b \
     -a "${ACTUATOR_USER}:${ACTUATOR_PASSWORD}" \
     GET "${URL}" \
  | trivy sbom -
