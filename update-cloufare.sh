#!/bin/bash

ZONE_ID="youtZoneID"
API_TOKEN="yourAPI_TOKEN"
RECORD_NAME="yourDomain"
IP=$(curl -s https://ifconfig.me)

# Obtenemos el ID del registro DNS actual
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD_NAME" \
     -H "Authorization: Bearer $API_TOKEN" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')
echo $RECORD_ID

# Actualizamos el registro A con la IP actual
curl -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
     -H "Authorization: Bearer $API_TOKEN" \
     -H "Content-Type: application/json" \
     --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$IP\",\"ttl\":120}"
