# 🏡 ThinClient Infrastructure Setup (Docker, Nginx Proxy Manager & AdGuard)

This repository contains the configuration to build a secure, portable, and centralized infrastructure for your home services (Home Assistant, Nextcloud, etc.) on a ThinClient or Mini-PC.

The setup utilizes **Docker Compose** and separates the infrastructure (`docker-compose.yml`) from secrets (`.env`) and data (Volumes) for maximum security and easy migration.

---

## 🔒 Security and Portability Concept

### 1. Files and Their Function

| File/Folder | Purpose | Storage (Git) | Security Note |
| :--- | :--- | :--- | :--- |
| `docker-compose.yml` | The blueprint for all containers (NPM, HA, AdGuard). | **YES (Committed)** | Contains no plain passwords. |
| `.env` | **All** passwords and tokens as environment variables. | **NO (Ignored)** | **Critical.** Store locally and encrypt for backup. |
| `setup_thinclient.sh` | Script to install Docker and configure the host system. | **YES** | |
| `.gitignore` | Excludes all Volumes and the `.env` file from Git. | **YES** | |
| `[VOLUMES]/` (e.g., `npm/`, `db/`) | Persistent data (databases, certificates, logs). | **NO (Ignored)** | **Critical.** Must be compressed/migrated via external drive. |

### 2. The Role of the Static IP Address

The ThinClient **must** retain the **same static IP address** (e.g., `192.168.1.10`) for the system to function. This IP is permanently mapped in three critical locations:

1.  **Router Port Forwarding:** Directs external traffic (Ports 80/443) to the ThinClient.
2.  **AdGuard Home:** The IP address where all client devices look for DNS resolution.
3.  **AdGuard DNS Rewrites:** The target IP for all internal domains (`homeassistant.lan`).

---

## 🛠️ Step 1: Installation and Preparation (New Device)

Execute these steps on your new ThinClient/Mini-PC (e.g., running Ubuntu Server).

1.  **Clone the Repository and Create Folder:**
    ```bash
    # Create the target directory and navigate to it (using the standard /opt location)
    sudo mkdir -p /opt/thinClient
    cd /opt/thinClient
    # Clone your repository
    sudo git clone [YOUR_REPO_URL] .
    ```

2.  **Run the Setup Script:**
    This script installs Docker, Docker Compose, and sets necessary permissions.
    ```bash
    sudo chmod +x setup_thinclient.sh
    sudo ./setup_thinclient.sh
    ```
    *(Note: You may need to log out/log back in or reboot after installation for the Docker group permissions to take effect.)*

3.  **Assign Static IP:**
    Configure the operating system (e.g., via Netplan) to ensure the ThinClient has the **fixed static IP address** you intend to use for your services (e.g., `192.168.1.10`).

4.  **Create Secrets File:**
    Create the local `.env` file and populate the variables with your actual passwords. **Do not commit this file to Git!**

    ```bash
    # Example .env content:
    MYSQL_ROOT_PASSWORD='Your_secure_ROOT_Password'
    MYSQL_DATABASE='npm_data'
    MYSQL_USER='npm_user'
    MYSQL_PASSWORD='Your_secure_NPM_Password'
    ```

---

## 🚀 Step 2: Service Deployment and Configuration

### 2.1 Start the Infrastructure

Start all core containers (NPM, DB, AdGuard, HA, Portainer). Docker Compose will create the necessary **`proxy_net_global`** network.

```bash
docker compose up -d
```

### 2.2 Initial Service Login and Setup

*   **Portainer (Manager):** Access at `https://thinclient_ip:9443`. Set the initial admin password.
*   **NPM (Proxy):** Access at `http://thinclient_ip:81`. Log in with the default credentials (`admin@example.com` / `changeme`) and change them immediately.
*   **AdGuard Home:** Access at `http://thinclient_ip:3000` and complete the initial setup (specify listening interfaces and set admin credentials).

### 2.3 Home Assistant Proxy Security (Crucial)

To prevent "400 Bad Request" errors, you must allow the Docker internal network range in Home Assistant, as the request comes from the Nginx container's IP, not the client's.

Edit the `configuration.yaml` in your Home Assistant volume folder (`./homeassistant/config`):

```yaml
http:
  # Enables reading the true client IP from the X-Forwarded-For header
  use_x_forwarded_for: true
  
  # The trusted IP range for all standard Docker Bridge networks (highly recommended)
  trusted_proxies:
    - 172.16.0.0/12 
```

### 2.4 Name Resolution and Routing

*   **NPM Hosts Setup:** Go to Nginx Proxy Manager (Port 81) and create the Proxy Hosts, routing traffic internally by Container Name:
    *   *Example HA:* Domain `homeassistant.lan` → Forward Hostname `homeassistant` → Port `8123`
    *   *Example AdGuard:* Domain `adguard.lan` → Forward Hostname `adguardhome` → Port `3000`

*   **AdGuard DNS Rewrites:** Go to the AdGuard Home interface under **Filters → DNS Rewrites**. Enter all internal domains to point to the static IP of your ThinClient.
    *   *Example:* Domain: `homeassistant.lan` → IP: `192.168.1.10`

---

## 🔄 Step 3: Migration and Backup (Disaster Recovery)

This process is used for moving to new hardware or restoring from a system failure.

1.  **Secure Volumes:** On the old ThinClient, compress all ignored volume folders and the `.env` file:
    ```bash
    cd /opt/thinClient/
    zip -r volumes_backup.zip npm/ db/ portainer/ adguardhome/ homeassistant/ .env
    ```

2.  **Transfer Data:** Copy the `volumes_backup.zip` to a secure external drive (USB stick, etc.).

3.  **New ThinClient Setup:** Complete **Step 1** on the new hardware (Clone, run script, set IP).

4.  **Restore Data:** Copy and unzip the file into the repo directory on the new ThinClient.
    ```bash
    unzip volumes_backup.zip
    ```

5.  **Start:** Run `docker compose up -d`. The system will resume with the exact state of the old ThinClient.

---

## 📚 Appendix: Managing Separate Backend Projects

To manage development or small backend projects without cluttering the main `docker-compose.yml`, use the Global Network as external.

**Global Network Declaration (already in the main file):**
```yaml
networks:
  proxy_net_global:
    driver: bridge
    name: proxy_net_global
```

**Separate `docker-compose.yml` for a Project (e.g., `my-project/`):**
```yaml
version: '3.7'
services:
  my_private_backend: # This service name is used in NPM
    image: 'my-backend-app:latest'
    # ... project-specific configuration ...
    networks:
      - proxy_net_global

networks:
  proxy_net_global:
    external: true # Import the existing network
```

**Start:** Start the project independently using `docker compose up -d` inside the project folder. It will be immediately reachable by the Nginx Proxy Manager.
