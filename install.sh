#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print colored message
print_message() {
    echo -e "${2}${1}${NC}"
}

# Check if script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    print_message "Please run as root (use sudo)" "$RED"
    exit 1
fi

# Installation paths
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="appimage-integrator"
TEMP_DIR=$(mktemp -d)

print_message "Installing AppImage Integrator..." "$BLUE"

# Download the main script
curl -fsSL "https://raw.githubusercontent.com/Benyaminrmb/appimage-generator/main/appimage-integrator.sh" -o "$TEMP_DIR/$SCRIPT_NAME"

if [ $? -ne 0 ]; then
    print_message "Failed to download the script" "$RED"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Make it executable
chmod +x "$TEMP_DIR/$SCRIPT_NAME"

# Move to installation directory
mv "$TEMP_DIR/$SCRIPT_NAME" "$INSTALL_DIR/"

if [ $? -ne 0 ]; then
    print_message "Failed to install the script" "$RED"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Create symbolic link for shorter command
ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "$INSTALL_DIR/appimage"

# Cleanup
rm -rf "$TEMP_DIR"

print_message "AppImage Integrator has been successfully installed!" "$GREEN"
print_message "You can now use it with either 'appimage-integrator' or the shorter 'appimage' command" "$BLUE"
print_message "Example usage:" "$BLUE"
print_message "  appimage-integrator /path/to/your/app.AppImage" "$GREEN"
print_message "  appimage /path/to/your/app.AppImage" "$GREEN" 