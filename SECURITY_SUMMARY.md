# Security Review Summary and Recommendations

This document summarizes the findings of a security review of the homelab scripts and services repository and provides recommendations for improvement.

## 1. Hardcoded Secrets

**Issue:** Sensitive information like API tokens and chat IDs are hardcoded directly into shell scripts.

**Affected Files:**
-   `send_telegram.sh`: Contains hardcoded `BOT_TOKEN` and `CHAT_ID`.
-   `update-cloufare.sh`: Contains hardcoded `ZONE_ID` and `API_TOKEN`. (Note: `RECORD_NAME` is also hardcoded but is a placeholder for user configuration rather than a secret).

**Recommendation:**
-   **Remove hardcoded secrets from scripts.**
-   Instead, use environment variables to supply these values at runtime. For example, source them from a local file (added to `.gitignore`) or set them in the environment where the scripts are executed.
-   Alternatively, consider using a secrets management tool for more robust secret handling, especially if the number of secrets grows.

## 2. Script Permissions

**Issue:** Shell scripts (`.sh` files) in the repository do not have execute permissions by default. Their permissions are set to `rw-r--r--`.

**Affected Files:**
-   `crowdsec_notify.sh`
-   `docker-status.sh`
-   `instruccionesDockerCompose.sh`
-   `send_telegram.sh`
-   `update-cloufare.sh`

**Recommendation:**
-   This is primarily a usability issue rather than a direct vulnerability. Users will need to make the scripts executable before running them.
-   Instruct users to run `chmod +x <script_name>.sh` for each script they intend to use. This was already added to the main `README.md`.

## 3. External Calls

**Issue:** Verification of external network calls made by scripts.

**Affected Files:**
-   `send_telegram.sh`
-   `update-cloufare.sh`
-   `instruccionesDockerCompose.sh` (fetches Docker GPG key and package lists)

**Finding:**
-   All identified external calls use HTTPS.
-   The target URLs are official APIs (Telegram, Cloudflare) or official software distribution channels (Docker).
-   **No security issues were found with the external calls.**

## 4. Docker Configurations & `acme.json` Permissions

**Issues:** Potential security misconfigurations in Docker Compose files and associated host file permissions.

**Affected Files/Services:**
-   `traefik/docker-compose.yml`
-   `traefik/acme.json`
-   `traefik/authelia/` (host directory permissions)

**Recommendations:**

-   **Traefik Dashboard Port Exposure:**
    -   **Issue:** The Traefik service in `traefik/docker-compose.yml` exposes port `9000` (often used for the dashboard/API) to the host on all network interfaces via the `ports: - "9000:9000"` mapping. The comment suggests local access only, but the mapping itself doesn't enforce this.
    -   **Recommendation:** Review the necessity of exposing port `9000` directly from the Traefik container.
        -   If the dashboard needs to be accessible externally (even within the local network), ensure strong authentication is configured within Traefik for its API/dashboard.
        -   If it's intended for truly local machine access only, consider removing the port mapping and accessing it via `docker exec` or by exposing it only on `127.0.0.1` (e.g., `"127.0.0.1:9000:9000"`).
        -   Alternatively, use host-level firewall rules (e.g., `ufw`, `iptables`) to restrict access to port `9000` to specific IP addresses or local network ranges.

-   **`traefik/acme.json` Permissions:**
    -   **Issue:** The `traefik/acme.json` file, which stores SSL certificates including private keys, has permissions `rw-r--r--` (644). This allows group and world read access.
    -   **Recommendation:** Change the permissions of the `traefik/acme.json` file on the host to `600` (`chmod 600 traefik/acme.json`). This restricts read and write access to the owner only.

-   **Authelia Configuration Permissions:**
    -   **Issue:** The `traefik/authelia/` directory is mounted into the Authelia container. This directory on the host contains sensitive files like `users_database.yml` (user credentials) and `configuration.yml`. Their host-side permissions are critical.
    -   **Recommendation:** Ensure that `traefik/authelia/users_database.yml` and `traefik/authelia/configuration.yml` on the host have restrictive permissions. Ideally, they should only be readable/writable by the user managing the service (e.g., permissions `600`).

-   **General Docker Hardening:**
    -   **Image Users:** The current setup uses standard images that mostly follow good practices regarding user privileges (e.g., Nginx workers as non-root, Authelia as non-root). Traefik might run with more privileges due to Docker socket access.
    -   **Recommendation:** While current images are standard, if any custom Docker images are built as part of this project in the future, ensure they are configured to run as non-root users where possible by using the `USER` directive in their Dockerfiles.
    -   **Read-Only Volumes:** The use of `:ro` for configuration volumes (`traefik.yml`, `dynamic/`, `linktree/html`) and the Docker socket is a good practice and should be maintained.

This summary provides actionable steps to enhance the security posture of the homelab setup.
