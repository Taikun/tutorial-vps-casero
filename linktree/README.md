# Linktree Service

This service provides a simple, self-hostable Linktree alternative. It allows you to create a single page that displays a list of your important links.

## Customization

To customize the links displayed on the page, you need to edit the `html/indext.html` file within this directory. You can add, remove, or modify the links in the HTML structure to suit your needs.

## Running the Service

To run the Linktree service:

1.  **Navigate to the `linktree` directory:**
    ```bash
    cd path/to/your/homelab-scripts/linktree
    ```
2.  **Start the service using Docker Compose:**
    ```bash
    docker-compose up -d
    ```

## Accessing the Service

Once the service is running, it will be available at `http://<server_ip>:8080` by default. The port can be changed by modifying the `ports` section in the `docker-compose.yml` file.
For example, if your server's IP address is `192.168.1.100`, you would access the Linktree page at `http://192.168.1.100:8080`.
