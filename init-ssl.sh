#!/bin/bash
# ================================================================
#  init-ssl.sh — Bootstrap Let's Encrypt certificates
#
#  Usage:
#    CERTBOT_EMAIL=toseiyu@gmail.com ./init-ssl.sh kaetsukokusai.com www.kaetsukokusai.com
#
#  Prerequisites:
#    - DNS A records point to Elastic IP 52.198.225.111
#    - Docker & Docker Compose installed
# ================================================================
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <domain> [additional domains...]"
    echo "Example: $0 kaetsukokusai.com www.kaetsukokusai.com"
    exit 1
fi

PRIMARY_DOMAIN="$1"
ALL_DOMAINS="$*"

# Build the -d flags for certbot
DOMAIN_FLAGS=""
for d in $ALL_DOMAINS; do
    DOMAIN_FLAGS="$DOMAIN_FLAGS -d $d"
done

EMAIL="${CERTBOT_EMAIL:-}"
if [ -z "$EMAIL" ]; then
    read -rp "Enter email for Let's Encrypt notifications: " EMAIL
fi

echo "============================================"
echo " Domains : $ALL_DOMAINS"
echo " Email   : $EMAIL"
echo "============================================"

# ---- Step 1: Start services (entrypoint auto-detects no cert → HTTP-only) ----
echo "[1/3] Starting services in HTTP-only mode..."
docker compose up -d --build site-1 site-2 nginx

echo "Waiting for Nginx to become healthy..."
sleep 3

# ---- Step 2: Request certificate ----
echo "[2/3] Requesting certificate from Let's Encrypt..."
docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    $DOMAIN_FLAGS \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --force-renewal

# ---- Step 3: Restart Nginx (entrypoint auto-detects cert → HTTPS mode) ----
echo "[3/3] Restarting Nginx with HTTPS..."
docker compose restart nginx

echo ""
echo "=== Done! ==="
echo "Your site is live at https://$PRIMARY_DOMAIN"
echo ""
echo "Auto-renewal cron job:"
echo "  0 3 * * * /home/ec2-user/office-web-app/renew-ssl.sh >> /var/log/certbot-renew.log 2>&1"
