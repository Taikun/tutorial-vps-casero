# Homelab Scripts and Services

This repository contains a collection of shell scripts and service configurations for a homelab environment.

## Shell Scripts

- `crowdsec_notify.sh`: Monitors CrowdSec alerts and sends notifications via Telegram. Requires `jq`.
- `docker-status.sh`: Checks the status of Docker containers and sends a notification if any are down.
- `instruccionesDockerCompose.sh`: Provides instructions for managing Docker Compose services.
- `send_telegram.sh`: A utility script to send messages via Telegram.
- `update-cloufare.sh`: Updates Cloudflare DNS records. Requires `jq`.

## Services

- **Linktree**: A simple, self-hosted Linktree alternative. It allows you to create a single page with multiple links.
- **Traefik**: A modern reverse proxy and load balancer that makes deploying microservices easy. It integrates with Docker and handles SSL certificate generation and renewal automatically.

## Usage

To use the shell scripts, you first need to make them executable:

```bash
chmod +x script_name.sh
```

Then, you can run them directly:

```bash
./script_name.sh
```

Some scripts may require configuration, such as API tokens or chat IDs. Please refer to the individual script files for more details.

## Prerequisites

- **jq**: The `crowdsec_notify.sh` and `update-cloufare.sh` scripts require `jq` to be installed. You can install it using your system's package manager (e.g., `sudo apt-get install jq` on Debian/Ubuntu).
- **Docker and Docker Compose**: The `linktree` and `traefik` services require Docker and Docker Compose to be installed. Please refer to the official Docker documentation for installation instructions.
