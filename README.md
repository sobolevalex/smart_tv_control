# Samsung Smart TV Parental Control (Jetson Xavier + Home Assistant)

Documentation and setup roadmap for monitoring and limiting Samsung Smart TV watch time using Home Assistant in Docker, Cloudflare Tunnel, and Telegram.

---

## 1. Architecture

```
[ Samsung Smart TV ]
        ↕ (WiFi / SmartThings Cloud)
[ Samsung SmartThings API ]
        │
        ▼ (Instant Webhook HTTPS push)
[ Cloudflare Edge ] (Your custom domain)
        │
        ▼ (Secure Cloudflare Tunnel)
[ Jetson Xavier: cloudflared ]
        │ (Local HTTP)
        ▼
[ Jetson Xavier: Home Assistant ]
        ├── history_stats Sensor (Daily runtime sum, resets at 00:00)
        ├── Limit Variable (input_number, e.g. 120 mins)
        ├── Automation 1: Auto turn-off when daily limit reached
        ├── Automation 2: Turn-off block if powered on after limit reached
        └── Telegram Integration (Alerts + commands: /status, /tv_off, /tv_on)
```

---

## 2. Roadmap

### Step 1. Docker Setup on Jetson Xavier
- Manage container stack via `./docker/manage.sh`.
- Service `homeassistant` uses `ghcr.io/home-assistant/home-assistant:stable` in `network_mode: host`.

### Step 2. Initial Home Assistant Configuration
- Start container: `./docker/manage.sh start`.
- Open `http://<JETSON_IP>:8123` and create an admin user.
- Reverse proxy support is configured via UI (**Settings** -> **System** -> **Network**).

### Step 3. Cloudflare Tunnel Routing
- In Cloudflare Zero Trust dashboard (Networks -> Tunnels), route a subdomain (e.g., `ha.yourdomain.com`) to `http://localhost:8123`.
- Verify external HTTPS access.
- Set `external_url: https://ha.yourdomain.com` in Home Assistant settings.

### Step 4. Samsung SmartThings Integration
- Generate Personal Access Token (PAT) at [account.smartthings.com/tokens](https://account.smartthings.com/tokens).
- In Home Assistant, add integration: **Settings -> Devices & Services -> Add Integration -> SmartThings**.
- Enter PAT; Home Assistant registers the webhook with SmartThings Cloud.
- Verify real-time status updates (`on` / `off`) when toggling the TV via physical remote.

### Step 5. Watch Time Tracking & Limit Enforcement
1. **`history_stats` Sensor**:
   - Tracks duration of `on` state for the TV.
   - Calculation window: from `00:00:00` today to current time (resets automatically at midnight).
2. **Limit Input (`input_number`)**:
   - Adjustable daily limit slider (e.g., 30 to 300 minutes, default 120) accessible on the dashboard.
3. **Turn-Off Automation**:
   - Trigger: runtime sensor reaches daily limit.
   - Action: call `media_player.turn_off` + send Telegram alert.
4. **Enforcement / Lockout Automation**:
   - Trigger: TV state turns `on`.
   - Condition: today's watch time >= daily limit.
   - Action: immediate `turn_off` + Telegram warning ("Attempted to turn on TV after limit reached").

### Step 6. Telegram Bot Integration
- Create bot via `@BotFather` and retrieve token.
- Add `telegram_bot` in Home Assistant.
- Configure bot commands:
  - `/status` — TV power state, minutes watched today, remaining limit.
  - `/tv_off` — force turn off.
  - `/tv_on` — turn on.
  - `/add_time 30` (optional) — add extra time to today's limit.

### Step 7. Parental Control Dashboard
- Add Home Assistant dashboard cards:
  - TV power status toggle.
  - Gauge / progress bar showing consumed vs allowed time.
  - Limit slider and emergency off button.
