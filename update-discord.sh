#!/bin/bash

URL="https://discord.com/api/download/stable?platform=linux&format=tar.gz"
TEMP_FILE="/tmp/discord.tar.gz"
TARGET_DIR="/opt"

echo "⏳ Downloading latest Discord version"

curl -L "$URL" -o "$TEMP_FILE"

echo "📦 Unscompressing archieve and updating /opt/Discord"

sudo tar -xzf "$TEMP_FILE" -C "$TARGET_DIR"

echo "🧹 Deleting compressed file..."
rm -f "$TEMP_FILE"

echo "Discord update succeed"
