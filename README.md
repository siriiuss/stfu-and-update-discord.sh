# Discord Updater

A dead-simple bash script to install and update Discord on Linux via the official tarball. No Flatpaks, no Snaps, no nonsense.

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

## What it does

- If Discord is **not installed**, it downloads and installs the latest version to `/opt/Discord`
- If Discord is **already installed**, it checks for updates and updates if a newer version is available
- Optionally adds Discord to your applications menu

## Notes

- Installs Discord to `/opt/Discord`
- Tested on Linux (tar.gz install method)
