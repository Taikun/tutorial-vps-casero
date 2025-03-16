#!/bin/bash

BASE_DIR="/opt/docker"

for folder in "$BASE_DIR"/*; do
    if [[ -f "$folder/docker-compose.yml" ]]; then
        echo "=== $(basename "$folder") ==="
        (cd "$folder" && docker compose ps)
        echo ""
    fi
done
