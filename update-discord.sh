#!/bin/bash

if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is required but not installed."
    exit 1
fi


echo "Gathering latest version information..."

URL="https://discord.com/api/download/stable?platform=linux&format=tar.gz"
BUILD_FILE=""
if [ -f "/opt/Discord/resources/build_info.json" ]; then
    BUILD_FILE="/opt/Discord/resources/build_info.json"
    elif [ -f "/opt/DiscordCanary/resources/build_info.json" ]; then
    BUILD_FILE="/opt/DiscordCanary/resources/build_info.json"
    elif [ -f "/opt/DiscordPTB/resources/build_info.json" ]; then
    BUILD_FILE="/opt/DiscordPTB/resources/build_info.json"
fi
TEMP_FILE="/tmp/discord.tar.gz"
TARGET_DIR="/opt"


if [ ! -f "$BUILD_FILE" ]; then
    echo "Error: Discord is not installed or $BUILD_FILE not found. Check for correct path."
    echo "If you didn't install Discord before press y to install, otherwise press n to exit."
    read -p "Do you want to install Discord? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        read -p "Select channel (stable | canary | ptb): " channel
        if [[ "$channel" != "stable" && "$channel" != "canary" && "$channel" != "ptb" ]]; then
            echo "Invalid channel. Choose: stable, canary or ptb"
            exit 1
        fi
        URL="https://discord.com/api/download/$channel?platform=linux&format=tar.gz"
        echo "Installing Discord..."
        echo "Downloading latest Discord version"
        curl -L "$URL" -o "$TEMP_FILE"
        echo "Uncompressing archive and updating /opt/Discord"
        sudo tar -xzf "$TEMP_FILE" -C "$TARGET_DIR"
        echo "Deleting compressed file..."
        rm -f "$TEMP_FILE"
        echo "Discord installation succeeded."
        read -p "Do you want to add Discord to the applications menu? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo "Adding Discord to the applications menu..."
            case "$channel" in
                stable)  INSTALL_DIR="/opt/Discord";       APP_NAME="Discord";        EXEC="Discord" ;;
                canary)  INSTALL_DIR="/opt/DiscordCanary"; APP_NAME="Discord Canary"; EXEC="DiscordCanary" ;;
                ptb)     INSTALL_DIR="/opt/DiscordPTB";    APP_NAME="Discord PTB";    EXEC="DiscordPTB" ;;
            esac
            
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
            echo "Discord has been added to the applications menu."
        fi
        
        
        
        exit 0
    else
        exit 1
    fi
fi

RELEASE_CHANNEL=$(jq -r '.release_channel' "$BUILD_FILE")
VERSION=$(jq -r '.version' "$BUILD_FILE")


URL="https://discord.com/api/download/$RELEASE_CHANNEL?platform=linux&format=tar.gz"
FILE_NAME=$(basename "$(curl -sLI -o /dev/null -w '%{url_effective}' "$URL")")


echo "Current Discord version: $VERSION"
echo "Channel: $RELEASE_CHANNEL"
echo "Checking for updates..."


LATEST_VERSION=$(echo "$FILE_NAME" | grep -oP '\d+\.\d+\.\d+')


echo "Latest Discord version: $LATEST_VERSION"

if [ "$VERSION" == "$LATEST_VERSION" ]; then
    echo "Discord is already up to date."
    exit 0
else
    echo "A new version of Discord is available. Updating..."
    echo "Downloading latest Discord version"
    curl -L "$URL" -o "$TEMP_FILE"
    echo "Uncompressing archive and updating /opt/Discord"
    sudo tar -xzf "$TEMP_FILE" -C "$TARGET_DIR"
    echo "Deleting compressed file..."
    rm -f "$TEMP_FILE"
    echo "Discord update succeeded"
    
fi
