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

## Quick start (Linux)

1. Download **[gdrive-backup-utility.tar.gz](gdrive-backup-utility.tar.gz)** and extract it:
   ```bash
   mkdir gdrive-backup && tar -xzf gdrive-backup-utility.tar.gz -C gdrive-backup && cd gdrive-backup
   ```
   *(Cloned this repo? Just run `make setup` — see `make help` for all commands. Later, `make update` fetches the newest version and upgrades in place, keeping your `.env` and credentials.)*
2. Create your config and Google credentials (full walkthrough in `doc/`):
   ```bash
   cp .env.example .env && nano .env      # folder ID, source dirs, schedule
   # put your Google OAuth credentials.json + token.json in ./cred/
   # (doc/HOW_TO_DOWNLOAD_CREDENTIALS.md + doc/HOW_TO_GET_TOKEN.md)
   ```
3. Test once in the foreground, then install the service:
   ```bash
   ./run.sh          # watch the first backup happen
   ./install.sh      # register systemd service
   ./start.sh        # done — backups now run on your schedule
   ```

## Free vs Pro

The free version is fully functional for file backups — forever. Pro adds what you need to trust it unattended.

| | Free | Pro |
|---|:---:|:---:|
| File/folder backup to Google Drive | ✅ | ✅ |
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

**Windows/macOS?**  Linux x86-64 today. Open an issue if you want another platform — demand drives the roadmap.

## Support & license

- 🐛 Bugs and questions: open a GitHub issue
- 📧 Pro / licensing support: [mtechltd2021@gmail.com](mailto:mtechltd2021@gmail.com)
- 📄 Use of the packaged software is governed by the included [EULA.md](EULA.md) (Pro features require an active subscription)
