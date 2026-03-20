#!/bin/bash
# ================================================================
#  renew-ssl.sh — Check & renew Let's Encrypt certificates
#
#  Features:
#    - Pre-check: detect cert expiry via openssl (live HTTPS probe)
#    - Fallback: read cert file from Docker volume if HTTPS unreachable
#    - Auto-renew when remaining days <= threshold
#    - Post-renew: reload Nginx, verify new cert
#    - Alert: optional webhook on failure
#
#  Crontab (daily 3:00 AM):
#    0 3 * * * /path/to/renew-ssl.sh >> /var/log/certbot-renew.log 2>&1
#
#  Environment variables (optional):
#    DOMAIN          — domain to check (default: read from Nginx config)
#    RENEW_THRESHOLD — days before expiry to trigger renewal (default: 30)
#    ALERT_WEBHOOK   — URL to POST alert on failure (Slack/DingTalk/etc.)
# ================================================================
set -euo pipefail

cd "$(dirname "$0")"

# ---- Configuration ----
RENEW_THRESHOLD="${RENEW_THRESHOLD:-30}"
ALERT_WEBHOOK="${ALERT_WEBHOOK:-}"
LOG_PREFIX="[certbot-renew]"

# Auto-detect domain from Nginx config if not set
if [ -z "${DOMAIN:-}" ]; then
    DOMAIN=$(grep -m1 'server_name' nginx/confi.d/site-https.conf \
        | awk '{print $2}' | tr -d ';')
fi

log()  { echo "$LOG_PREFIX [$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
warn() { log "WARN: $*"; }
fail() { log "ERROR: $*"; send_alert "$*"; exit 1; }

send_alert() {
    [ -z "$ALERT_WEBHOOK" ] && return 0
    local msg="$LOG_PREFIX $DOMAIN — $1"
    curl -sf -X POST "$ALERT_WEBHOOK" \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"$msg\"}" >/dev/null 2>&1 || warn "Alert webhook failed"
}

# ---- Step 1: Check certificate expiry ----
get_expiry_days() {
    local days=-1

    # Method 1: Live HTTPS probe (most accurate — tests what clients actually see)
    if expiry_date=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2); then
        if [ -n "$expiry_date" ]; then
            expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null) || true
            now_epoch=$(date +%s)
            if [ -n "${expiry_epoch:-}" ]; then
                days=$(( (expiry_epoch - now_epoch) / 86400 ))
                log "Method: HTTPS probe | Expiry: $expiry_date | Remaining: ${days}d"
                echo "$days"
                return 0
            fi
        fi
    fi

    # Method 2: Read cert file from Docker volume
    if cert_text=$(docker compose exec -T nginx cat /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem 2>/dev/null); then
        if expiry_date=$(echo "$cert_text" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2); then
            expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null) || true
            now_epoch=$(date +%s)
            if [ -n "${expiry_epoch:-}" ]; then
                days=$(( (expiry_epoch - now_epoch) / 86400 ))
                log "Method: cert file  | Expiry: $expiry_date | Remaining: ${days}d"
                echo "$days"
                return 0
            fi
        fi
    fi

    warn "Cannot determine certificate expiry, will attempt renewal anyway"
    echo "$days"
}

# ---- Step 2: Decide whether to renew ----
log "========== Certificate renewal check start =========="
log "Domain: $DOMAIN | Threshold: ${RENEW_THRESHOLD}d"

remaining=$(get_expiry_days)

if [ "$remaining" -ge 0 ] && [ "$remaining" -gt "$RENEW_THRESHOLD" ]; then
    log "Certificate still valid for ${remaining}d (> ${RENEW_THRESHOLD}d threshold). No action needed."
    exit 0
fi

if [ "$remaining" -ge 0 ]; then
    log "Certificate expires in ${remaining}d (<= ${RENEW_THRESHOLD}d threshold). Renewing..."
else
    log "Expiry unknown. Attempting renewal..."
fi

# ---- Step 3: Renew ----
MAX_RETRIES=3
for attempt in $(seq 1 $MAX_RETRIES); do
    log "Renewal attempt $attempt/$MAX_RETRIES..."
    if docker compose run --rm certbot renew --quiet; then
        log "Certbot renewal succeeded."
        break
    fi
    if [ "$attempt" -eq "$MAX_RETRIES" ]; then
        fail "Renewal failed after $MAX_RETRIES attempts"
    fi
    sleep 10
done

# ---- Step 4: Reload Nginx ----
log "Reloading Nginx..."
docker kill -s HUP office-nginx >/dev/null 2>&1 || warn "Nginx HUP signal failed"
sleep 2

# ---- Step 5: Post-renewal verification ----
log "Verifying new certificate..."
new_remaining=$(get_expiry_days)

if [ "$new_remaining" -gt "$RENEW_THRESHOLD" ]; then
    log "Verification passed. New cert valid for ${new_remaining}d."
else
    fail "Verification failed. Cert still shows ${new_remaining}d remaining after renewal."
fi

log "========== Certificate renewal check complete =========="
