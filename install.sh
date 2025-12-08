#!/bin/bash

# --- Configuration ---
DOWNLOAD_URL="https://github.com/helightdev/hrestore/releases/latest/download/hrestore_linux_x64"
TEMP_FILE="/tmp/hrestore_linux_x64"
TARGET_DIR="/usr/local/bin"

# Check for necessary tools
if ! command -v wget &> /dev/null; then
    echo "Error: 'wget' is required but not installed." >&2
    exit 1
fi
if ! command -v dpkg &> /dev/null; then
    echo "Error: 'dpkg' is required but not installed." >&2
    exit 1
fi

# Download the executable file to a temporary location
echo "Downloading latest HRestore release..."
if ! wget -O "$TEMP_FILE" "$DOWNLOAD_URL"; then
    echo "Error: Failed to download package from $DOWNLOAD_URL." >&2
    exit 1
fi

# Move the file to the target directory and set executable permissions
mkdir -p "$TARGET_DIR"
sudo mv "$TEMP_FILE" "$TARGET_DIR/hrestore"
sudo chmod +x "$TARGET_DIR/hrestore"
rm -f "$TEMP_FILE"

echo "Installation complete. HRestore is now ready to use."
exit 0