#!/bin/sh
set -e

CERT_DIR="/etc/letsencrypt/live"
HTTPS_CONF="/etc/nginx/conf.d/site-https.conf"
HTTP_CONF="/etc/nginx/conf.d/site-http.conf"
HTTP_ONLY_TPL="/etc/nginx/templates/site-http-only.conf.tpl"
HTTP_REDIRECT_TPL="/etc/nginx/templates/site-http.conf.tpl"

# Find the first domain directory under /etc/letsencrypt/live/
DOMAIN_DIR=$(find "$CERT_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)

if [ -n "$DOMAIN_DIR" ] && [ -f "$DOMAIN_DIR/fullchain.pem" ]; then
    echo "[entrypoint] SSL certificate found at $DOMAIN_DIR — enabling HTTPS"
    cp /etc/nginx/templates/site-http.conf.tpl  "$HTTP_CONF"
    cp /etc/nginx/templates/site-https.conf.tpl "$HTTPS_CONF"
else
    echo "[entrypoint] No SSL certificate found — HTTP-only mode"
    cp /etc/nginx/templates/site-http-only.conf.tpl "$HTTP_CONF"
    rm -f "$HTTPS_CONF"
fi

exec "$@"
