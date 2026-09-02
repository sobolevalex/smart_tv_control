#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SERVICE_NAME="homeassistant"
SYSTEMD_SERVICE="smart-tv-ha.service"

check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Error: docker is not installed or not in PATH."
        exit 1
    fi
}

start() {
    echo "==> Starting Home Assistant..."
    docker compose up -d
    echo "==> Done. Checking status:"
    docker compose ps
}

stop() {
    echo "==> Stopping Home Assistant..."
    docker compose down
    echo "==> Stopped."
}

restart() {
    echo "==> Restarting Home Assistant..."
    docker compose restart
    echo "==> Done."
}

status() {
    echo "==> Container status:"
    docker compose ps
}

logs() {
    echo "==> Streaming logs (Press Ctrl+C to exit):"
    docker compose logs -f --tail=100
}

update() {
    echo "==> Updating Home Assistant image..."
    docker compose pull
    docker compose up -d
    echo "==> Update complete."
}

enable_autostart() {
    echo "==> Configuring systemd autostart on boot..."
    SERVICE_FILE="/etc/systemd/system/${SYSTEMD_SERVICE}"

    cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=Smart TV Home Assistant Docker Stack
After=docker.service network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${SCRIPT_DIR}
ExecStart=$(which docker) compose up -d
ExecStop=$(which docker) compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable "$SYSTEMD_SERVICE"
    echo "==> Service ${SYSTEMD_SERVICE} enabled for system startup."
}

disable_autostart() {
    echo "==> Disabling autostart..."
    if sudo systemctl is-enabled "$SYSTEMD_SERVICE" &> /dev/null; then
        sudo systemctl disable "$SYSTEMD_SERVICE"
        sudo rm -f "/etc/systemd/system/${SYSTEMD_SERVICE}"
        sudo systemctl daemon-reload
        echo "==> Autostart disabled."
    else
        echo "==> Service ${SYSTEMD_SERVICE} is not enabled."
    fi
}

check_docker

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    update)
        update
        ;;
    autostart)
        enable_autostart
        ;;
    disable-autostart)
        disable_autostart
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|update|autostart|disable-autostart}"
        echo ""
        echo "Commands:"
        echo "  start              - Start Home Assistant in background"
        echo "  stop               - Stop Home Assistant"
        echo "  restart            - Restart container"
        echo "  status             - Show container status"
        echo "  logs               - Follow logs in real time"
        echo "  update             - Pull latest image and recreate container"
        echo "  autostart          - Enable autostart on Jetson boot (systemd)"
        echo "  disable-autostart  - Disable systemd autostart"
        exit 1
        ;;
esac
