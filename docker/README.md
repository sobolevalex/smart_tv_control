# Home Assistant Docker Management on Jetson

## 1. Directory Structure
```
docker/
├── docker-compose.yml       # Home Assistant service specification
├── manage.sh                # Management script (start/stop/logs/autostart)
├── README.md                # This manual
└── config/                  # Home Assistant configuration directory
    ├── configuration.yaml   # Core configuration
    ├── automations.yaml     # Automations file (limits and TV lockouts)
    ├── scripts.yaml         # Home Assistant scripts
    └── scenes.yaml          # Home Assistant scenes
```

---

## 2. Using `manage.sh`

Run commands inside the `docker/` directory:
```bash
cd docker

# Start in background
./manage.sh start

# Check status
./manage.sh status

# Follow logs in real time
./manage.sh logs

# Restart container (e.g., after config updates)
./manage.sh restart

# Stop container
./manage.sh stop

# Enable autostart on Jetson boot (creates systemd unit)
./manage.sh autostart

# Disable systemd autostart
./manage.sh disable-autostart

# Pull latest image and update
./manage.sh update
```

---

## 3. Connecting to Existing Cloudflare Tunnel

Since `cloudflared` is already running in Docker on your Jetson:
1. Home Assistant runs in `network_mode: host` and listens on port `8123` on the host.
2. In **Cloudflare Zero Trust** -> **Networks** -> **Tunnels**:
   - Open your existing tunnel.
   - Under **Public Hostname**, add a subdomain (e.g., `ha.yourdomain.com`).
   - Service type: `HTTP`.
   - URL: `localhost:8123` (or `127.0.0.1:8123`).
3. Reverse Proxy settings are managed via Web UI (**Settings** -> **System** -> **Network**).
