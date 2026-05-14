#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${YELLOW}$1${NC}"; }
success() { echo -e "${GREEN}$1${NC}"; }
error()   { echo -e "${RED}$1${NC}"; }

show_help() {
    echo "Usage: sudo ./update-discord.sh [OPTION]"
    echo ""
    echo "Options:"
    echo "  --help        Show this help message"
    echo "  --uninstall   Uninstall Discord"
    echo "  --auto        Check for updates automatically on a schedule (uses cron)"
    echo ""
    echo "Without options: installs or updates Discord"
}

if [ "$EUID" -ne 0 ]; then
    echo "Use with sudo"
    show_help
    exit
fi

BUILD_FILE=""
TEMP_FILE="/tmp/discord.tar.gz"
TARGET_DIR="/opt"

find_build_file() {
    if [ -f "/opt/Discord/build_info.json" ]; then
        BUILD_FILE="/opt/Discord/build_info.json"
    elif [ -f "/opt/DiscordCanary/build_info.json" ]; then
        BUILD_FILE="/opt/DiscordCanary/build_info.json"
    elif [ -f "/opt/DiscordPTB/build_info.json" ]; then
        BUILD_FILE="/opt/DiscordPTB/build_info.json"
    fi
}

uninstall() {
    find_build_file
    if [ -z "$BUILD_FILE" ]; then
        error "Discord is not installed."
        exit 1
    fi
    RELEASE_CHANNEL=$(jq -r '.releaseChannel' "$BUILD_FILE")
    case "$RELEASE_CHANNEL" in
        stable)  INSTALL_DIR="/opt/Discord" ;;
        canary)  INSTALL_DIR="/opt/DiscordCanary" ;;
        ptb)     INSTALL_DIR="/opt/DiscordPTB" ;;
    esac
    read -p "Are you sure you want to uninstall Discord ($RELEASE_CHANNEL)? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        sudo rm -rf "$INSTALL_DIR"
        sudo rm -f "/usr/share/applications/discord-${RELEASE_CHANNEL}.desktop"
        read -p "Remove user data as well? (~/.config/discord) (y/n): " data_choice
        if [[ "$data_choice" == "y" || "$data_choice" == "Y" ]]; then
            rm -rf ~/.config/discord
            success "Discord and user data have been removed."
        else
            success "Discord has been uninstalled. User data kept at ~/.config/discord"
        fi
    else
        info "Uninstall cancelled."
    fi
    exit 0
}

setup_auto() {
    read -p "How often should it check for updates? (daily | weekly): " period
    if [[ "$period" == "daily" ]]; then
        CRON_SCHEDULE="0 9 * * *"
    elif [[ "$period" == "weekly" ]]; then
        CRON_SCHEDULE="0 9 * * 1"
    else
        error "Invalid option. Choose: daily or weekly"
        exit 1
    fi
    SCRIPT_PATH=$(realpath "$0")
    (crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH"; echo "$CRON_SCHEDULE sudo $SCRIPT_PATH") | crontab -
    success "Auto-update scheduled ($period)."
    exit 0
}

case "$1" in
    --help)      show_help; exit 0 ;;
    --uninstall) uninstall ;;
    --auto)      setup_auto ;;
esac

if ! command -v jq &> /dev/null; then
    error "Error: 'jq' is required but not installed."
    exit 1
fi

info "Gathering latest version information..."

find_build_file

if [ ! -f "$BUILD_FILE" ]; then
    error "Error: Discord is not installed or build_info.json not found."
    echo "If you didn't install Discord before press y to install, otherwise press n to exit."
    read -p "Do you want to install Discord? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        read -p "Select channel (stable | canary | ptb): " channel
        if [[ "$channel" != "stable" && "$channel" != "canary" && "$channel" != "ptb" ]]; then
            error "Invalid channel. Choose: stable, canary or ptb"
            exit 1
        fi
        case "$channel" in
            stable)  INSTALL_DIR="/opt/Discord";       APP_NAME="Discord";        EXEC="discord" ;;
            canary)  INSTALL_DIR="/opt/DiscordCanary"; APP_NAME="Discord Canary"; EXEC="discord" ;;
            ptb)     INSTALL_DIR="/opt/DiscordPTB";    APP_NAME="Discord PTB";    EXEC="discord" ;;
        esac
        URL="https://discord.com/api/download/$channel?platform=linux&format=tar.gz"
        FILE_NAME=$(basename "$(curl -sLI -o /dev/null -w '%{url_effective}' "$URL")")
        LATEST_VERSION=$(echo "$FILE_NAME" | grep -oP '\d+\.\d+\.\d+')
        info "Installing Discord $LATEST_VERSION..."
        curl -L "$URL" -o "$TEMP_FILE"
        sudo tar -xzf "$TEMP_FILE" -C "$TARGET_DIR"
        echo "{\"releaseChannel\": \"$channel\", \"version\": \"$LATEST_VERSION\"}" | sudo tee "$INSTALL_DIR/build_info.json" > /dev/null
        rm -f "$TEMP_FILE"
        success "Discord installation succeeded. Version: $LATEST_VERSION"
        read -p "Do you want to add Discord to the applications menu? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            sudo tee /usr/share/applications/discord-${channel}.desktop > /dev/null <<EOL
[Desktop Entry]
Name=$APP_NAME
Comment=All-in-one voice and text chat for gamers that's free and secure.
Exec=$INSTALL_DIR/$EXEC
Icon=$INSTALL_DIR/discord.png
Terminal=false
Type=Application
Categories=Network;Chat;
EOL
            success "Discord has been added to the applications menu."
        fi
        exit 0
    else
        exit 1
    fi
fi

RELEASE_CHANNEL=$(jq -r '.releaseChannel' "$BUILD_FILE")
VERSION=$(jq -r '.version' "$BUILD_FILE")

case "$RELEASE_CHANNEL" in
    stable)  INSTALL_DIR="/opt/Discord" ;;
    canary)  INSTALL_DIR="/opt/DiscordCanary" ;;
    ptb)     INSTALL_DIR="/opt/DiscordPTB" ;;
esac

URL="https://discord.com/api/download/$RELEASE_CHANNEL?platform=linux&format=tar.gz"
FILE_NAME=$(basename "$(curl -sLI -o /dev/null -w '%{url_effective}' "$URL")")

info "Current Discord version: $VERSION"
info "Channel: $RELEASE_CHANNEL"
info "Checking for updates..."

LATEST_VERSION=$(echo "$FILE_NAME" | grep -oP '\d+\.\d+\.\d+')

info "Latest Discord version: $LATEST_VERSION"

if [ "$VERSION" == "$LATEST_VERSION" ]; then
    success "Discord is already up to date."
    exit 0
else
    info "A new version of Discord is available. Updating..."

    # Backup
    if [ -d "$INSTALL_DIR" ]; then
        info "Creating backup..."
        sudo cp -r "$INSTALL_DIR" "${INSTALL_DIR}.bak"
        success "Backup created at ${INSTALL_DIR}.bak"
    fi

    curl -L "$URL" -o "$TEMP_FILE"
    sudo tar -xzf "$TEMP_FILE" -C "$TARGET_DIR"
    echo "{\"releaseChannel\": \"$RELEASE_CHANNEL\", \"version\": \"$LATEST_VERSION\"}" | sudo tee "$BUILD_FILE" > /dev/null
    rm -f "$TEMP_FILE"
    success "Discord update succeeded. Version: $LATEST_VERSION"

    # Restart Discord if running
    if pgrep -x "discord" > /dev/null; then
        info "Restarting Discord..."
        pkill -x "discord"
        sleep 1
        nohup "$INSTALL_DIR/discord" > /dev/null 2>&1 &
        success "Discord restarted."
    fi
fi
