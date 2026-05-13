# Discord Updater

A dead-simple bash script to install and update Discord on Linux via the official tarball.
No Flatpaks, no Snaps, no nonsense.

## Requirements

- `curl`
- `jq`
- `sudo` privileges

## Usage

```bash
git clone https://github.com/siriiuss/stfu-and-update-discord.sh.git
chmod +x update-discord.sh
./update-discord.sh
```

## Options

| Flag | Description |
|------|-------------|
| *(none)* | Install or update Discord |
| `--help` | Show help message |
| `--uninstall` | Uninstall Discord |
| `--auto` | Set up automatic update checks via cron (daily or weekly) |

## What it does

- If Discord is **not installed**, prompts you to install it
  - Asks which channel to install: `stable`, `canary`, or `ptb`
  - Optionally adds Discord to your applications menu
- If Discord is **already installed**, checks for updates and updates if a newer version is available
  - Automatically detects the installed channel from `build_info.json`
  - Creates a backup of the current installation before updating
  - Restarts Discord automatically if it was running

## Install paths

| Channel | Path |
|---------|------|
| Stable  | `/opt/Discord` |
| Canary  | `/opt/DiscordCanary` |
| PTB     | `/opt/DiscordPTB` |

## Notes

- Tested on Linux (tar.gz install method)
- Does not support Flatpak or Snap installations
- Backups are stored at `/opt/Discord.bak` (or equivalent for other channels)
- User data is kept at `~/.config/discord` unless explicitly removed during uninstall
