# Architecture

## Tech Stack
- Host: NVIDIA Jetson Xavier (ARM64, Linux)
- Engine: Home Assistant Core (`ghcr.io/home-assistant/home-assistant:stable`, `network_mode: host`)
- Ingress: Cloudflare Tunnel -> `http://127.0.0.1:8123` (reverse proxy)
- Integration: Samsung SmartThings (HTTPS webhook push)
- Notification/Control: Telegram Bot API

## Project Structure
```
.
├── .antigravityrules        # System constraints & standards
├── .gitignore               # Runtime, DB, secret exclusions
├── ARCHITECTURE.md          # Architecture & structure spec
├── README.md                # General documentation
└── docker/
    ├── docker-compose.yml   # Home Assistant container spec
    ├── manage.sh            # Lifecycle CLI (start/stop/restart/autostart)
    ├── README.md            # Docker operational guide
    └── config/
        ├── configuration.yaml # Core HA config (reverse proxy enabled)
        ├── automations.yaml   # Turn-off & lockout rules
        ├── scripts.yaml       # HA scripts
        └── scenes.yaml        # HA scenes
```

## Data Flow
1. TV state change -> SmartThings Cloud -> Webhook via Cloudflare Tunnel -> Home Assistant.
2. `history_stats` computes daily active seconds (resets `00:00:00`).
3. Automation checks `active_time >= input_number.limit`.
4. Trigger fires -> `media_player.turn_off` -> SmartThings Cloud -> TV.
5. TV turns on when limit exceeded -> immediate `media_player.turn_off`.
