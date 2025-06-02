# Traefik Service

Traefik is a modern, open-source edge router, reverse proxy, and load balancer that makes deploying and managing microservices easy. It integrates seamlessly with various service discovery mechanisms like Docker, Kubernetes, and others, automatically discovering services and configuring routes. Traefik also excels at handling SSL/TLS certificate generation and renewal, primarily through Let's Encrypt.

This document provides a detailed overview of the Traefik configuration used in this homelab setup.

## Table of Contents

1.  [Core Concepts](#core-concepts)
    *   [Static Configuration](#static-configuration)
    *   [Dynamic Configuration](#dynamic-configuration)
2.  [Running the Service](#running-the-service)
3.  [Static Configuration (`traefik.yml`) Breakdown](#static-configuration-traefikyml-breakdown)
    *   [Global Settings](#global-settings)
    *   [EntryPoints](#entrypoints)
    *   [Providers](#providers)
    *   [API and Dashboard](#api-and-dashboard)
    *   [Logging](#logging)
    *   [Certificate Resolvers (Let's Encrypt)](#certificate-resolvers-lets-encrypt)
4.  [Dynamic Configuration (`dynamic/` directory)](#dynamic-configuration-dynamic-directory)
    *   [Concept and Structure](#concept-and-structure)
    *   [Defining Routers](#defining-routers)
    *   [Defining Services](#defining-services)
    *   [Defining Middleware](#defining-middleware)
    *   [Example: Adding a New Backend Service](#example-adding-a-new-backend-service)
5.  [Middleware Deep Dive](#middleware-deep-dive)
    *   [Purpose of Middleware](#purpose-of-middleware)
    *   [Common Middleware Examples](#common-middleware-examples)
        *   [Security Headers](#security-headers)
        *   [RedirectScheme (HTTP to HTTPS)](#redirectscheme-http-to-https)
        *   [Authentication (Basic/Digest)](#authentication-basicdigest)
        *   [IP Whitelisting](#ip-whitelisting)
        *   [Rate Limiting](#rate-limiting)
    *   [Defining and Applying Middleware](#defining-and-applying-middleware)
6.  [Authelia Integration In-Depth](#authelia-integration-in-depth)
    *   [Purpose of Authelia](#purpose-of-authelia)
    *   [Authelia Configuration (`authelia/configuration.yml`)](#authelia-configuration-autheliaconfigurationyml)
    *   [Traefik ForwardAuth Middleware for Authelia](#traefik-forwardauth-middleware-for-authelia)
    *   [Applying Authelia Protection](#applying-authelia-protection)
    *   [User Management (`authelia/users_database.yml`)](#user-management-autheliausers_databaseyml)
7.  [TLS/SSL Configuration Details](#tlsssl-configuration-details)
    *   [Role of Certificate Resolvers](#role-of-certificate-resolvers)
    *   [`acme.json` for Let's Encrypt Certificates](#acmejson-for-lets-encrypt-certificates)
    *   [Router TLS Configuration](#router-tls-configuration)
    *   [Using Custom Certificates (Briefly)](#using-custom-certificates-briefly)
8.  [Accessing Traefik](#accessing-traefik)

## Core Concepts

Traefik's configuration is divided into two main parts:

### Static Configuration
This configuration is defined when Traefik starts. It includes settings for entry points, providers, logging, API/dashboard, and certificate resolvers. The primary static configuration file in this setup is `traefik.yml`. Changes to static configuration usually require a Traefik restart.

### Dynamic Configuration
This configuration can be changed while Traefik is running and is typically used for defining how requests are handled (routers, services, middleware). Traefik can automatically detect changes to dynamic configuration (e.g., from files or Docker labels) and apply them without a restart. In this setup, the `dynamic/` directory is used for file-based dynamic configuration.

## Running the Service

To run the Traefik service and its associated components (like Authelia):

1.  **Navigate to the `traefik` directory:**
    ```bash
    cd path/to/your/homelab-scripts/traefik
    ```
2.  **Ensure you have a `.env` file or environment variables set up for secrets like `CF_API_TOKEN` (Cloudflare API Token for DNS challenge) if you are using it.**
3.  **Start the service using Docker Compose:**
    ```bash
    docker-compose up -d
    ```

## Static Configuration (`traefik.yml`) Breakdown

The `traefik.yml` file defines the foundational settings for Traefik.

### Global Settings
```yaml
global:
  checkNewVersion: true # Periodically checks for new Traefik versions
  sendAnonymousUsage: false # Set to true to help Traefik by sending anonymous usage statistics
```
-   `checkNewVersion`: Advisable to keep `true` to be aware of updates.
-   `sendAnonymousUsage`: Optional; set based on your privacy preference.

### EntryPoints
EntryPoints are the network entry points into Traefik (e.g., ports).
```yaml
entryPoints:
  web:
    address: ":80" # HTTP entry point on port 80
    http:
      redirections:
        entryPoint:
          to: websecure # Redirect all HTTP traffic to the 'websecure' (HTTPS) entry point
          scheme: https
  websecure:
    address: ":443" # HTTPS entry point on port 443
    http:
      tls:
        certResolver: letsencrypt # Use the 'letsencrypt' certificate resolver for HTTPS
# You might also have an entryPoint for the Traefik dashboard/API if you expose it on a different port
#  dashboard:
#    address: ":9000"
```
-   `web`: Standard HTTP port. Often configured to redirect to `websecure`.
-   `websecure`: Standard HTTPS port, typically with TLS enabled using a certificate resolver.

### Providers
Providers tell Traefik where to find routing configuration.
```yaml
providers:
  docker:
    exposedByDefault: false # Only expose containers that have the 'traefik.enable=true' label
    network: web # Specifies the default Docker network Traefik should use to connect to services
                 # Ensure this network is created and used by your backend containers
  file:
    directory: "/dynamic" # Path inside the Traefik container where dynamic configuration files are located
    watch: true # Traefik will automatically watch for changes in this directory
```
-   `docker`:
    -   `exposedByDefault: false`: A security best practice. You explicitly enable Traefik for containers using labels.
    -   `network`: Important for Traefik to connect to your application containers.
-   `file`:
    -   `directory`: Points to the directory mounted in `docker-compose.yml` (e.g., `./dynamic:/dynamic`).
    -   `watch: true`: Allows for hot-reloading of configuration.

### API and Dashboard
Controls access to Traefik's API and dashboard.
```yaml
api:
  dashboard: true # Enables the Traefik dashboard
  # insecure: true # !! DANGER ZONE !! Only use for local testing if dashboard is not exposed externally.
                   # For production, secure it with a router and authentication (see dynamic config example).
  # To secure the dashboard (recommended):
  # 1. Remove `insecure: true`
  # 2. Define a router in your dynamic configuration for the dashboard service.
  # Example in dynamic config:
  # http:
  #   routers:
  #     dashboard:
  #       rule: "Host(`traefik.yourdomain.com`)"
  #       service: "api@internal" # Special service name for the Traefik API/dashboard
  #       middlewares:
  #         - authelia-auth # Secure with Authelia or another auth middleware
  #       entryPoints:
  #         - websecure
  #       tls:
  #         certResolver: letsencrypt
```
-   `dashboard: true`: Enables the web UI.
-   `insecure: true`: **WARNING!** If set to `true`, the dashboard is accessible without authentication. This is **not recommended** if Traefik's API port is exposed externally. Prefer defining a secure router for the dashboard as shown in the commented example.

### Logging
Configures logging behavior.
```yaml
log:
  level: INFO # Log level (e.g., DEBUG, INFO, WARNING, ERROR)
  filePath: "/var/log/traefik/access.log" # Path to the access log file inside the container
  # format: json # Can be 'json' or 'common'
```
-   `level`: Adjust verbosity as needed. `DEBUG` is useful for troubleshooting.
-   `filePath`: Ensure the volume for logs is correctly mapped in `docker-compose.yml`.

### Certificate Resolvers (Let's Encrypt)
Defines how SSL/TLS certificates are obtained, especially from Let's Encrypt.
```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: "your-email@example.com" # Your email address for Let's Encrypt registration
      storage: "/acme.json" # Path to the file where certificates will be stored (inside the container)
      # caServer: "https://acme-staging-v02.api.letsencrypt.org/directory" # Uncomment for testing to avoid rate limits
      httpChallenge: # Preferred for most setups if port 80 is accessible
        entryPoint: web
      # dnsChallenge: # Use if port 80 is not accessible or for wildcard certificates
      #   provider: cloudflare # Example: Cloudflare
      #   delayBeforeCheck: 0
      #   # Add provider-specific options, e.g., API tokens via environment variables
      #   # resolvers:
      #   #  - "1.1.1.1:53"
      #   #  - "8.8.8.8:53"
```
-   `letsencrypt`: A friendly name for your resolver.
-   `email`: Important for Let's Encrypt notifications (e.g., expiry).
-   `storage`: Path to `acme.json` (volume mapped from host). **Permissions of this file on the host are critical (should be `600`).**
-   `caServer`: Use the staging server for testing to avoid hitting Let's Encrypt rate limits. Comment out for production.
-   `httpChallenge`: Validates domain ownership by serving a file over HTTP on port 80. Requires port 80 to be open to the internet.
-   `dnsChallenge`: Validates domain ownership by creating DNS records. Needed for wildcard certificates. Requires a compatible DNS provider and API credentials (often supplied via environment variables listed in `docker-compose.yml`).

## Dynamic Configuration (`dynamic/` directory)

### Concept and Structure
Dynamic configuration allows you to define routers, services, and middleware without restarting Traefik. Files in the `dynamic/` directory (specified by `providers.file.directory` in `traefik.yml`) are watched for changes.

It's good practice to organize dynamic configuration into logical files, e.g., `middlewares.yml`, `routers.yml`, or service-specific files like `service-one.yml`.

All dynamic configuration files typically start with an `http:` or `tcp:` key. For web services, you'll use `http:`.

### Defining Routers
Routers inspect incoming requests and decide which service should handle them based on rules (e.g., hostname, path).
```yaml
# Example: dynamic/routers.yml
http:
  routers:
    my-app-router:
      rule: "Host(`app.yourdomain.com`) && PathPrefix(`/api`)"
      service: "my-app-service" # Name of a service defined in dynamic config or from Docker
      entryPoints:
        - "websecure"
      middlewares:
        - "my-auth-middleware"
        - "security-headers"
      tls:
        certResolver: "letsencrypt"
        domains:
          - main: "app.yourdomain.com"
            sans:
              - "www.app.yourdomain.com"
```
-   `rule`: Defines when the router matches (e.g., `Host`, `PathPrefix`, `Method`).
-   `service`: The backend service to forward traffic to.
-   `entryPoints`: Which entry points (e.g., `websecure`) this router listens on.
-   `middlewares`: A list of middleware to apply.
-   `tls`: TLS configuration (see [TLS/SSL Configuration Details](#tlsssl-configuration-details)).

### Defining Services
Services define how Traefik reaches your backend applications.
```yaml
# Example: dynamic/services.yml
http:
  services:
    # Service pointing to a Docker container (usually discovered automatically if using Docker provider)
    # This is more for overriding or for non-Docker services.
    my-docker-app-service:
      loadBalancer:
        servers:
          - url: "http://<container_ip_or_name>:<container_port>" # e.g., http://myapp-container:8080
        # healthCheck: # Optional health check
        #   path: /health
        #   interval: "10s"
        #   timeout: "3s"

    # Service pointing to an external URL
    external-service:
      loadBalancer:
        servers:
          - url: "https://api.example.com/"
```
-   For Docker services managed by Traefik's Docker provider, you usually don't need to define services explicitly here unless you want to override settings or use features like health checks not available via labels.
-   `loadBalancer.servers`: List of backend servers.

### Defining Middleware
Middleware modifies requests or responses, or makes decisions based on the request (e.g., authentication).
```yaml
# Example: dynamic/middlewares.yml
http:
  middlewares:
    security-headers:
      headers:
        customFrameOptionsValue: "SAMEORIGIN"
        contentTypeNosniff: true
        browserXssFilter: true
        # Add more security headers here

    my-auth-middleware:
      basicAuth:
        users:
          - "user:$apr1$abcdefg$hijklmnop" # user:hashed_password (use htpasswd to generate)
```
-   See [Middleware Deep Dive](#middleware-deep-dive) for more examples.

### Example: Adding a New Backend Service
Let's say you have a Docker container `my-new-app` running on port `3000` within the `web` network, and you want to expose it at `newapp.yourdomain.com`.

1.  **Ensure `my-new-app` has Traefik labels (if using Docker provider primarily):**
    ```yaml
    # In your docker-compose.yml for my-new-app
    services:
      my-new-app:
        # ... other config ...
        labels:
          - "traefik.enable=true"
          - "traefik.http.routers.new-app-router.rule=Host(`newapp.yourdomain.com`)"
          - "traefik.http.routers.new-app-router.entrypoints=websecure"
          - "traefik.http.routers.new-app-router.service=new-app-service" # Can be same as router name
          - "traefik.http.services.new-app-service.loadbalancer.server.port=3000" # Port inside the container
          - "traefik.http.routers.new-app-router.tls.certresolver=letsencrypt"
          # - "traefik.http.routers.new-app-router.middlewares=authelia-auth@file" # If you want to protect it
    ```
    In this case, you might not need much in the `dynamic/` files for this specific service unless you're defining shared middleware.

2.  **Alternatively, using file-based dynamic configuration (e.g., if it's an external service or complex setup):**

    Create `dynamic/new-app.yml`:
    ```yaml
    http:
      routers:
        new-app-router:
          rule: "Host(`newapp.yourdomain.com`)"
          service: "new-app-service"
          entryPoints:
            - "websecure"
          tls:
            certResolver: "letsencrypt"
          # middlewares:
          #   - "authelia-auth@file" # Assuming authelia-auth is defined in middlewares.yml

      services:
        new-app-service:
          loadBalancer:
            servers:
              # If my-new-app is a Docker service in the 'web' network:
              - url: "http://my-new-app:3000"
              # If it's an external service:
              # - url: "http://external-ip:port"
    ```
    Traefik will automatically pick up this new file or the labels.

## Middleware Deep Dive

### Purpose of Middleware
Middleware components are attached to routers and can modify requests/responses or make decisions about forwarding requests. They are a powerful way to implement cross-cutting concerns like authentication, security headers, and redirects.

### Common Middleware Examples

#### Security Headers
Enhance security by adding headers like HSTS, X-Frame-Options, etc.
```yaml
# dynamic/middlewares.yml
http:
  middlewares:
    secHeaders:
      headers:
        customFrameOptionsValue: "SAMEORIGIN"
        contentTypeNosniff: true
        browserXssFilter: true
        forceSTSHeader: true
        stsSeconds: 31536000 # 1 year
        stsIncludeSubdomains: true
        stsPreload: true
        # Refer to Traefik documentation for a full list of available security headers
```

#### RedirectScheme (HTTP to HTTPS)
While often handled globally at the entryPoint level, you can also use middleware for specific redirection needs.
```yaml
# dynamic/middlewares.yml
http:
  middlewares:
    redirectToHTTPS:
      redirectScheme:
        scheme: https
        permanent: true
```
(Note: The global redirection in `entryPoints` is usually sufficient for HTTP to HTTPS.)

#### Authentication (Basic/Digest)
Simple authentication methods. For robust SSO, Authelia is preferred.
```yaml
# dynamic/middlewares.yml
http:
  middlewares:
    simpleAuth:
      basicAuth:
        users:
          - "admin:$apr1$yourgeneratedhash$anotherhashpart" # Use htpasswd to generate this
        # usersFile: "/path/to/.htpasswd" # Alternative: use a users file
    # digestAuth is also available but less common
```

#### IP Whitelisting
Restrict access to services based on client IP addresses.
```yaml
# dynamic/middlewares.yml
http:
  middlewares:
    localOnly:
      ipWhiteList:
        sourceRange:
          - "127.0.0.1/32"
          - "192.168.1.0/24" # Example local network
```

#### Rate Limiting
Protect services from being overwhelmed by too many requests.
```yaml
# dynamic/middlewares.yml
http:
  middlewares:
    appRateLimit:
      rateLimit:
        average: 100 # Requests per period
        period: "1m" # Period (e.g., 1 minute)
        burst: 50    # Max number of requests allowed in a burst
```

### Defining and Applying Middleware
1.  **Define** middleware in a YAML file within your dynamic configuration directory (e.g., `dynamic/middlewares.yml`).
2.  **Apply** middleware to a router by adding its name (e.g., `middlewareName@file`) to the `middlewares` list in the router's configuration. The `@file` suffix indicates it's defined in the file provider's configuration.

```yaml
# dynamic/my-app-router.yml
http:
  routers:
    my-app:
      rule: "Host(`my-app.yourdomain.com`)"
      service: "my-app-service"
      entryPoints: ["websecure"]
      tls:
        certResolver: "letsencrypt"
      middlewares:
        - "secHeaders@file"         # Defined in middlewares.yml
        - "localOnly@file"        # Defined in middlewares.yml
        # - "authelia-auth@file"  # If using Authelia
```

## Authelia Integration In-Depth

### Purpose of Authelia
Authelia is an open-source authentication and authorization server providing Single Sign-On (SSO) and Two-Factor Authentication (2FA). It protects your applications by requiring users to authenticate before Traefik forwards requests to them.

### Authelia Configuration (`authelia/configuration.yml`)
This file, located at `traefik/authelia/configuration.yml` on the host, is central to Authelia's behavior. Key sections relevant to Traefik integration include:
-   `jwt_secret`: A long, random string used to sign JWTs. Must be kept secret.
-   `default_redirection_url`: Where users are redirected if they try to access Authelia directly (e.g., `https://auth.yourdomain.com`).
-   `session`: Configures session cookies (name, secret, expiration).
-   `authentication_backend`: Defines how users are authenticated (e.g., file-based, LDAP). For this setup, it's typically file-based using `users_database.yml`.
-   `access_control`: Defines rules for which requests are allowed, denied, or require authentication.
    -   `default_policy`: Can be `deny` (recommended) or `two_factor`.
    -   `rules`: Define per-domain or per-path policies. For example, allow unauthenticated access to Authelia's own portal (`auth.yourdomain.com`) but require authentication for other services.
    ```yaml
    # Example rule in authelia/configuration.yml
    access_control:
      default_policy: deny
      rules:
        - domain: "auth.yourdomain.com" # Authelia's own portal
          policy: bypass
        - domain: "*.yourdomain.com"   # Protect all other subdomains
          policy: two_factor           # Or 'one_factor'
          subject: "group:admins"      # Optional: restrict to specific user groups
    ```

### Traefik ForwardAuth Middleware for Authelia
Traefik integrates with Authelia using its `forwardAuth` middleware. This middleware sends incoming requests to Authelia for an authentication decision.

Define the `forwardAuth` middleware in your Traefik dynamic configuration (e.g., `dynamic/middlewares.yml`):
```yaml
# dynamic/middlewares.yml
http:
  middlewares:
    authelia-auth: # Name this middleware
      forwardAuth:
        address: "http://authelia:9091/api/verify?rd=https://auth.yourdomain.com/" # Authelia's internal URL
        trustForwardHeader: true
        authResponseHeaders:
          - "Remote-User"
          - "Remote-Groups"
          - "Remote-Name"
          - "Remote-Email"
```
-   `address`: Points to Authelia's internal service name and port, followed by the API endpoint and a redirection URL (`rd`) for login.
-   `trustForwardHeader`: Important for Authelia to correctly identify the client IP.
-   `authResponseHeaders`: Headers that Authelia will send back to Traefik upon successful authentication, which can then be passed to backend applications.

### Applying Authelia Protection
To protect a service with Authelia, add the `authelia-auth@file` middleware to its router definition:
```yaml
# dynamic/protected-service-router.yml
http:
  routers:
    protected-app:
      rule: "Host(`protected.yourdomain.com`)"
      service: "my-protected-app-service"
      entryPoints: ["websecure"]
      tls:
        certResolver: "letsencrypt"
      middlewares:
        - "authelia-auth@file" # Apply the Authelia forwardAuth middleware
        - "secHeaders@file"    # Good to also include security headers
```

### User Management (`authelia/users_database.yml`)
Located at `traefik/authelia/users_database.yml` on the host, this file stores user definitions if you are using the file-based authentication backend.
```yaml
users:
  yourusername:
    displayname: "Your Name"
    password: "$argon2id$v=19$m=65536,t=3,p=4$yourhashhere$anotherhashpart" # Hashed password
    email: your-email@example.com
    groups:
      - admins
      - dev
```
-   **Passwords must be hashed.** Authelia provides commands to generate password hashes. Do not store plaintext passwords here.
-   Manage this file carefully as it contains user credentials.

## TLS/SSL Configuration Details

### Role of Certificate Resolvers
As defined in `traefik.yml` under `certificatesResolvers`, these components are responsible for obtaining and renewing SSL/TLS certificates. The `letsencrypt` resolver is commonly used for automatic certificate management with Let's Encrypt.

### `acme.json` for Let's Encrypt Certificates
-   **Purpose**: When Traefik successfully obtains certificates from Let's Encrypt (or another ACME CA), it stores them, including the private keys, in the file specified by `certificatesResolvers.letsencrypt.acme.storage` (e.g., `/acme.json` inside the container).
-   **Permissions**: This file is critical. **On the host machine, its permissions MUST be set to `600` (`-rw-------`)** to prevent unauthorized access to your private keys. The `docker-compose.yml` maps a host file (e.g., `./acme.json`) to `/acme.json` in the container.
-   **Backup**: Regularly back up your `acme.json` file. Losing it means losing your current certificates, and you'll need to request new ones (potentially hitting rate limits).

### Router TLS Configuration
To enable HTTPS for a specific router, you configure its `tls` section in the dynamic configuration:
```yaml
# In a dynamic configuration file (e.g., for a specific router)
http:
  routers:
    my-secure-app:
      # ... rule, service, entryPoints ...
      tls:
        certResolver: letsencrypt # Specifies which resolver to use (from traefik.yml)
        domains:
          - main: "yourdomain.com" # Primary domain for the certificate
            sans: # Subject Alternative Names (additional domains for the same cert)
              - "www.yourdomain.com"
              - "api.yourdomain.com"
        # options: "default" # Optional: Refer to named TLS options defined in dynamic config for advanced settings
                           # (e.g., cipher suites, min TLS version)
```
-   `certResolver`: Must match a resolver defined in `traefik.yml`.
-   `domains`: Specifies the main domain and any Subject Alternative Names (SANs) to be included in the certificate. Traefik will attempt to obtain a certificate covering all listed domains.

### Using Custom Certificates (Briefly)
If you have your own certificates (e.g., from a private CA or purchased), you can configure Traefik to use them. This is typically done by defining a `tls.stores` section in the dynamic configuration and providing paths to your certificate and key files.
```yaml
# dynamic/custom-tls.yml (Example - refer to Traefik docs for specifics)
# tls:
#   stores:
#     default:
#       defaultCertificate:
#         certFile: /path/to/custom.crt # Path inside the Traefik container
#         keyFile: /path/to/custom.key  # Path inside the Traefik container
#   certificates:
#     - certFile: /path/to/another.crt
#       keyFile: /path/to/another.key
#       stores:
#         - default
```
You would then map these certificate files into the Traefik container using volumes in `docker-compose.yml`. For most homelab uses with public-facing services, Let's Encrypt via `certificatesResolvers` is more convenient.

## Accessing Traefik

-   **Traefik Dashboard**: If enabled and configured with a router (recommended for security), the dashboard provides a web UI to monitor Traefik's status, routers, services, and middlewares. Access it via the hostname you defined (e.g., `https://traefik.yourdomain.com`). If using `insecure: true` (not recommended for external exposure), it might be on a specific port like `9000` or `8080` as defined in `traefik.yml` or `docker-compose.yml`.
-   **Service Routing**: Traefik's primary role is to route traffic to your backend services. These services will be accessible via the hostnames and paths defined in your router rules, typically over HTTPS on port 443.

This detailed guide should help in understanding and configuring Traefik for your homelab. Remember to consult the [official Traefik documentation](https://doc.traefik.io/traefik/) for the most current and comprehensive information.
