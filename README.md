# Google Drive Backup Utility

Google Drive Backup Utility helps you take backups of your **databases** and **file storage** and push them to your own **Google Drive**. For more visit: <https://gumroad.com/products/google-drive-backup-utility>

> 🎉 **Launch offer:** **50% off** for early birds with code **`27675BP`** (first 50 purchases) · **30% off** with code **`4KOP5N0`** (first 100 purchases).

**Set-and-forget — one binary, one config file, five minutes.** No cloud middleman, no per-GB fees, no agent phoning home. Your data goes straight from your server into a Google Drive folder you own.

```
┌──────────────┐   compress    ┌─────────────┐   upload    ┌──────────────┐
│ /var/www ... │──────────────▶│ .tar.gz/.zip│────────────▶│ Google Drive │
│ MySQL / PG   │   (+ encrypt) │   archives  │  (tagged)   │  your folder │
└──────────────┘               └─────────────┘             └──────────────┘
        ▲                nightly schedule + retention + failure alerts
```

## Why this instead of a cron script?

- **It never loses a backup silently.** Failed uploads are kept locally and retried on the next run; every failure can ping you on Telegram, Discord/Slack, or email.
- **It cleans up after itself — safely.** Retention only ever deletes files *this tool* uploaded (they're tagged on Drive), never anything else in the folder.
- **Restore is one command.** `--list-backups` and `--restore <name>` bring a backup (decrypted, if encrypted) back to your server.
- **Runs as a proper service.** Installs a systemd unit with auto-restart; survives reboots.

## Quick start — Desktop (easiest)

1. Download the package for your OS — **Linux/macOS:** [gdrive-backup-utility.tar.gz](gdrive-backup-utility.tar.gz) · **Windows:** [gdrive-backup-utility-windows.zip](gdrive-backup-utility-windows.zip) (extract and run `gdrive-backup-utility.exe`). On Linux:
   ```bash
   mkdir gdrive-backup && tar -xzf gdrive-backup-utility.tar.gz -C gdrive-backup && cd gdrive-backup
   ./gdrive-backup-utility
   ```
2. **The control panel opens automatically** (a default `.env` is created on first run). From the window:
   - **⚙ Settings…** — set your Drive folder ID, the folders to back up, and the schedule
   - **Authorize Google Drive…** — pick your downloaded `credentials.json`, sign in in the browser, and the token is saved automatically (never needed again)
   - **▶ Backup now** — trigger an instant backup and watch it in the live log
3. Decide how it keeps running:
   - **Install background service** — backups run unattended even after you close the window (asks for your system password / admin approval)
   - or just click **Start scheduler** and leave the window open
4. **Make it a clickable app** (optional, once — then you never open a terminal again):
   - **Linux:** `./create-launcher.sh` — adds *Google Drive Backup Utility* to your applications menu and Desktop
   - **Windows:** double-click `gdrive-backup-utility.exe` directly (the console stays hidden), or run `create-shortcut.ps1` for Desktop/Start Menu shortcuts
   - **macOS:** double-click the included **GoogleDriveBackupUtility.app**

## Quick start — Server (headless)

1. Extract as above (*cloned this repo? `make setup`; later `make update` upgrades in place, keeping your `.env` and credentials*).
2. Configure by hand: `cp .env.example .env && nano .env`, put `credentials.json` + `token.json` in `./cred/` (generate the token on a laptop — `doc/HOW_TO_GET_TOKEN.md`).
3. Run and install:
   ```bash
   ./run.sh          # watch the first backup happen
   ./install.sh      # register systemd service
   ./start.sh        # done — backups now run on your schedule
   ```

## Two ways to run — UI or terminal, your choice

**Both interfaces drive the exact same app and the same `.env` file** — you can set up in the UI and run headless on a server, or the other way round, and switch anytime.

| You want | Run |
|---|---|
| The graphical control panel | `./gdrive-backup-utility` on a desktop (opens automatically) — or force it with `--ui` |
| The terminal daemon (foreground) | `./gdrive-backup-utility --headless` (or `./run.sh`) |
| Unattended background service | `./install.sh` + `./start.sh` (Linux) · `install-service.sh` (macOS) · `install-service.ps1` as admin (Windows) |
| Instant backup | UI: **▶ Backup now** button (terminal mode runs on schedule only) |
| List backups on Drive (Pro) | `./gdrive-backup-utility --list-backups` |
| Restore a backup (Pro) | `./gdrive-backup-utility --restore <name> [--restore-dest DIR]` — also in the UI via **Backups on Drive…** |
| Stop the background service | `./stop.sh` (Linux) · `uninstall-service.sh` (macOS) · `stop-service.ps1` (Windows) — or the UI's service **Stop** button |

Notes:
- On a machine with no display (SSH/VPS), running with no flags starts the terminal daemon automatically — the UI only opens where a desktop exists.
- The service installers always run the app with `--headless`, so an installed service never pops up a window.
- Everything the UI writes (settings, license key, Google token) lands in `.env` and `cred/` — the same files the terminal mode reads.

## Free vs Pro

The free version is fully functional for file backups — forever. Pro adds what you need to trust it unattended.

| | Free | Pro |
|---|:---:|:---:|
| File/folder backup to Google Drive | ✅ | ✅ |
| Storage destinations: Drive, **email**, **scp**, **Dropbox**, **OneDrive** | ✅ one at a time | ✅ several simultaneously |
| Compression (zip / tar.gz) | ✅ | ✅ |
| Daily & cron scheduling | ✅ | ✅ |
| Runs as systemd service | ✅ | ✅ |
| **Database backup** (MySQL, MariaDB, PostgreSQL) | — | ✅ |
| **Client-side AES-256 encryption** before upload | — | ✅ |
| **Failure alerts** (Telegram, Discord/Slack, Email) | — | ✅ |
| **One-command restore** (`--restore`, `--list-backups`) | — | ✅ |
| **Retention policy** (auto-delete old backups, safely) | — | ✅ |
| Support | GitHub issues | Priority email |

👉 **[Get a Pro license](https://gumroad.com/products/google-drive-backup-utility)** — pay what you want from **$5 every 2 years**. You'll receive a license key; paste it into `.env` as `LICENSE_KEY=` and restart. That's the whole upgrade. Don't forget the launch codes: **`27675BP`** (50% off, first 50) or **`4KOP5N0`** (30% off, first 100).

## ⚠️ Required configuration — the service will not run without these

Set these in `.env` before the first start (everything else is optional):

| Key | Set it to |
|---|---|
| `GDRIVE_FOLDER_ID` | The ID of your Drive folder — the part after `folders/` in its URL |
| `SOURCE_DIRECTORY` | Comma-separated paths to back up, e.g. `/var/www,/etc` — **paths must exist or startup fails** |
| `FILE_BACKUP_ENABLE` | `true` — nothing is backed up while this is `false` |
| `COMPRESS_ENABLE` | `true` — uploads are compressed archives |
| `SCHEDULE_TYPE` + `SCHEDULE_TIME` | `daily` + `HH:MM` (24h) — or `cron` + a 7-field `SCHEDULE_CRON` |

**Plus two credential files** (not env keys — see `cred/README.md` and `doc/`):

- `cred/credentials.json` — your Google OAuth client, required before the first run
- `cred/token.json` — created during first-run authorization (generate on a laptop for headless servers)

## Configuration at a glance

Everything lives in one `.env` file:

```ini
GDRIVE_FOLDER_ID=...            # the Drive folder that receives backups
SOURCE_DIRECTORY=/var/www,/etc  # comma-separated paths to back up
SCHEDULE_TYPE=daily             # or 'cron' with a 7-field pattern
SCHEDULE_TIME=00:30
COMPRESS_ENABLE=true
ENCRYPTION_ENABLE=true          # Pro: AES-256, passphrase never leaves your server
RETENTION_ENABLE=true           # Pro: delete backups older than RETENTION_DAYS
NOTIFY_ENABLE=true              # Pro: Telegram / webhook / SMTP on failure
DB_BACKUP_ENABLE=true           # Pro: databases listed in cred/db_backup_info.json
```

## Restoring (Pro)

```bash
./gdrive-backup-utility --list-backups
./gdrive-backup-utility --restore www_20260719_003000.tar.gz.enc --restore-dest /tmp/restore
# encrypted backups are decrypted automatically with your passphrase
```

## FAQ

**Is my data safe in transit and at rest?**  Uploads use Google's TLS APIs with the minimal `drive.file` scope (the app can only see files it created). With Pro encryption enabled, archives are AES-256-GCM encrypted *before* they leave your server — Google only ever stores ciphertext. Lose the passphrase, lose the backups: store it somewhere safe.

**Does it work headless (VPS without a browser)?**  Yes — generate `token.json` once on your laptop (see `doc/HOW_TO_GET_TOKEN.md`), copy it to the server, never touch a browser again.

**What happens if an upload fails mid-run?**  The archive stays on disk, the next scheduled run retries it, and (Pro) you get an alert.

**Windows/macOS?**  Yes — release packages are built for Linux x86-64/ARM64, Windows x86-64, and macOS (Apple Silicon). Windows packages include a Scheduled-Task service installer (`install-service.ps1`, run as administrator — Windows shows its own approval prompt), macOS packages a launchd agent (`install-service.sh`, no admin needed). The UI works on all three.

**Do I have to use the UI?**  No. UI and terminal are fully interchangeable — see "Two ways to run" above. Servers without a display automatically get the terminal daemon.

## Support & license

- 🐛 Bugs and questions: open a GitHub issue
- 📧 Pro / licensing support: [mtechltd2021@gmail.com](mailto:mtechltd2021@gmail.com)
- 📄 Use of the packaged software is governed by the included [EULA.md](EULA.md) (Pro features require an active subscription)
