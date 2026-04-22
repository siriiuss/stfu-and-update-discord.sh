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
sudo ./update-discord.sh
```
 
## What it does
 
- If Discord is **not installed**, prompts you to install it
  - Asks which channel to install: `stable`, `canary`, or `ptb`
  - Optionally adds Discord to your applications menu
- If Discord is **already installed**, checks for updates and updates if a newer version is available
  - Automatically detects the installed channel from `build_info.json`
## Install paths
 
| Channel | Path |
|---------|------|
| Stable  | `/opt/Discord` |
| Canary  | `/opt/DiscordCanary` |
| PTB     | `/opt/DiscordPTB` |
 
## Notes
 
- Tested on Linux (tar.gz install method)
