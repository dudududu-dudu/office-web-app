#!/bin/sh
set -eu

echo "[deploy-hook] renewed domains: ${RENEWED_DOMAINS:-unknown}"

# Send HUP signal to Nginx to reload config & new certs without downtime
docker kill -s HUP office-nginx >/dev/null 2>&1 || true
