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

# Buscar alertas desde la última ejecución
ALERTS=$($CSCLI alerts list --since "$LAST_RUN" -o json)

# Actualizamos el timestamp
echo "$NOW" > "$LAST_RUN_FILE"

# Si hay alertas, las mandamos
if [ "$ALERTS" != "[]" ]; then
  echo "$ALERTS" | jq -r '.[] | "🛡️ CrowdSec ha bloqueado una IP:\n🔹 IP: \(.decisions[0].value)\n🔹 Razón: \(.decisions[0].scenario)\n🔹 Desde: \(.start_at)\n🔹 Hasta: \(.decisions[0].until)"' | while read -r line; do
    $SEND_SCRIPT "$line"
  done
fi
