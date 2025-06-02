# Traefik Service

Traefik is a modern reverse proxy and load balancer that makes deploying microservices easy. It integrates seamlessly with Docker and other orchestrators, automatically discovering services and configuring routes. It also handles SSL certificate generation and renewal (e.g., via Let's Encrypt).

## Configuration

Traefik's main configuration is typically done through the following files:

-   **`traefik.yml`**: This is the static configuration file for Traefik. It defines entry points (like HTTP and HTTPS), providers (like Docker), and general settings. You might configure API access, logging, and dashboard settings here.
-   **Files in `dynamic/` directory**: This directory holds dynamic configuration files, often for defining middlewares (like authentication, headers, redirects) and routers. Traefik can monitor these files for changes and update its configuration without a restart.

### Authentication with Authelia

This Traefik setup includes Authelia, an authentication and authorization server.
-   **`authelia/configuration.yml`**: This is the main configuration file for Authelia. It defines how Authelia behaves, including identity providers, default policies, and session settings.
-   **`authelia/users_database.yml`**: This file stores user credentials (usernames, hashed passwords, email addresses, and display names) for Authelia. **Remember to use strong, unique passwords and secure this file appropriately.**

## Running the Service

To run the Traefik service:

1.  **Navigate to the `traefik` directory:**
    ```bash
    cd path/to/your/homelab-scripts/traefik
    ```
2.  **Start the service using Docker Compose:**
    ```bash
    docker-compose up -d
    ```

## Accessing Traefik

-   **Traefik Dashboard**: Traefik provides a web dashboard to monitor its status, routers, services, and middlewares. The dashboard is typically accessible on port `8080`, but this can be configured in the `traefik.yml` file (look for the `[api]` or `[dashboard]` section).
-   **Service Routing**: Traefik's primary role is to route traffic to your other services based on rules you define (e.g., hostnames, paths). These services will be accessible via the ports and domains you configure through Traefik.

## SSL Certificates (`acme.json`)

The `acme.json` file is crucial for HTTPS. Traefik uses this file to store the SSL certificates it obtains from ACME providers like Let's Encrypt.
-   **Permissions**: Ensure this file has restrictive permissions (e.g., `600`) as it contains your private keys.
-   **Backup**: It's highly recommended to back up this file regularly. Losing it means you'll lose your SSL certificates and will need to request new ones, potentially hitting rate limits.
-   **Volume Mapping**: This file is typically volume-mapped into the Traefik container to persist certificates across container restarts.
