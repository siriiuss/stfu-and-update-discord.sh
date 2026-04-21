#!/bin/bash

if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is required but not installed."
    exit 1
fi


echo "Gathering latest version information..."
URL="https://discord.com/api/download/stable?platform=linux&format=tar.gz"
BUILD_FILE="/opt/Discord/resources/build_info.json"
FILE_NAME=$(basename "$(curl -sLI -o /dev/null -w '%{url_effective}' "$URL")")
TEMP_FILE="/tmp/discord.tar.gz"
TARGET_DIR="/opt"


if [ ! -f "$BUILD_FILE" ]; then
    echo "Error: Discord is not installed or $BUILD_FILE not found. Check for correct path."
    echo "If you didn't install Discord before press y to install, otherwise press n to exit."
    read -p "Do you want to install Discord? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Installing Discord..."
        echo "Downloading latest Discord version"
        curl -L "$URL" -o "$TEMP_FILE"
        echo "Uncompressing archive and updating /opt/Discord"
        sudo tar -xzf "$TEMP_FILE" -C "$TARGET_DIR"
        echo "Deleting compressed file..."
        rm -f "$TEMP_FILE"
        echo "Discord installation succeeded"
        # Ask user if they want to add Discord to the applications menu if n exit
        read -p "Do you want to add Discord to the applications menu? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            echo "Adding Discord to the applications menu..."
            # Create a .desktop file for Discord
            sudo tee /usr/share/applications/discord.desktop > /dev/null <<EOL
[Desktop Entry]
Name=Discord
Comment=All-in-one voice and text chat for gamers that's free and secure.
Exec=/opt/Discord/Discord
Icon=/opt/Discord/resources/app/icon.png
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


VERSION=$(jq -r '.version' "$BUILD_FILE")
echo "Current Discord version: $VERSION"
echo "Channel: Stable"
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

