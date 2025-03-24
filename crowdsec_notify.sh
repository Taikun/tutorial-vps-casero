#!/bin/bash

# Ruta al binario de cscli
CSCLI="/usr/bin/cscli"
LAST_RUN_FILE="/var/lib/crowdsec/last_alert_time"
SEND_SCRIPT="/ruta/completa/send_telegram.sh"

# Si no existe, lo creamos
if [ ! -f "$LAST_RUN_FILE" ]; then
  date -d '5 minutes ago' +"%Y-%m-%dT%H:%M:%S" > "$LAST_RUN_FILE"
fi

LAST_RUN=$(cat "$LAST_RUN_FILE")
NOW=$(date +"%Y-%m-%dT%H:%M:%S")

# Calculate duration since last run in minutes (minimum 5 minutes)
DURATION="5m"

# Buscar alertas desde la última ejecución
ALERTS=$($CSCLI alerts list --since "${DURATION}" -o json)

# Actualizamos el timestamp
echo "$NOW" > "$LAST_RUN_FILE"

# Check if we have valid alerts (not null and not empty array)
if [ "$ALERTS" != "null" ] && [ -n "$ALERTS" ] && [ "$ALERTS" != "[]" ]; then
  echo "$ALERTS" | jq -r 'if type == "array" then .[] | select(.decisions != null and .decisions[0] != null) | "\U0001F6E1️ CrowdSec ha bloqueado una IP:\n\U0001F539 IP: \(.decisions[0].value)\n\U0001F539 Razón: \(.decisions[0].scenario)\n\U0001F539 Desde: \(.start_at)\n\U0001F539 Hasta: \(.decisions[0].until)" else empty end' | while read -r line; do
    if [ -n "$line" ]; then
      $SEND_SCRIPT "$line"
    fi
  done
fi
