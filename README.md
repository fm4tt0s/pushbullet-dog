# pushbullet-dog
An xbar plugin that watches for Pushbullet file pushes sent to a specific device and automatically opens them in your browser — restoring the workflow that broke when Pushbullet's Chrome extension stopped working after the Manifest V3 update.

---

## How it works

Every 12 hours, the plugin:

1. Queries the Pushbullet API for pushes from the last 24 hours
2. Filters pushes targeting a specific device
3. Opens any unseen file URLs in the default browser
4. Tracks seen pushes to avoid opening duplicates on future runs
5. Displays a menu bar count of new pushes found in the current run

---

## Requirements

- [xbar](https://xbarapp.com/) installed
- [jq](https://stedolan.github.io/jq/) installed (`brew install jq`)
- Python 3 (included with macOS)
- A [Pushbullet](https://www.pushbullet.com/) account and API access token

---

## Setup

**1. Clone or download the script into your xbar plugins directory:**

```bash
# default xbar plugins directory
cp 001-pushbullet-dog.12h.sh ~/Library/Application\ Support/xbar/plugins/
chmod +x ~/Library/Application\ Support/xbar/plugins/001-pushbullet-dog.12h.sh
```

**2. Edit the config section at the top of the script:**

```bash
# your Pushbullet API token
# get it at: https://www.pushbullet.com/#settings/account
_token="YOUR_ACCESS_TOKEN_HERE"

# the `iden` of the target device (the one that should receive the pushes)
# get it by running:
#   curl -s --header 'Access-Token: YOUR_TOKEN' https://api.pushbullet.com/v2/devices | jq '.devices[] | {iden, nickname}'
_targetiden="YOUR_DEVICE_IDEN_HERE"
```

**3. Refresh xbar** — the plugin will appear in your menu bar.

---

## Finding your device `iden`

```bash
curl -s --header 'Access-Token: YOUR_TOKEN' \
  https://api.pushbullet.com/v2/devices \
  | jq '.devices[] | {iden, nickname}'
```

---

## Files created by the plugin

| File | Purpose |
|------|---------|
| `<plugin-dir>/001-pushbullet-dog.seen.off` | Persistent log of seen push idens and URLs — prevents duplicate opens across runs |
| `/tmp/001-pushbullet-dog.temp.off` | Ephemeral list of new URLs found in the current run — used to build the menu |

> The `.off` extension prevents xbar from treating these as plugins.

---

## Menu bar reference

| State | Appearance |
|-------|-----------|
| New pushes found | ➡️ `N` in red |
| Nothing new | ➡️ `0` in gray |
| API error | ⚠️ with error detail in dropdown |

Clicking any item in the dropdown opens the corresponding file in your browser.

---

## Notes

- The plugin runs every **12 hours** (controlled by the filename `*.12h.sh`). Change it to `*.5m.sh`, `*.1h.sh`, etc. to adjust the refresh rate — but keep `_pushage` in sync to cover the interval. 
- Pushbullet's API has **rate limits**; the 24h lookback window is intentional to stay within them (500 requests/month)
- The seen-pushes file grows indefinitely. Prune it manually if needed, or add a cron to trim old entries.
