#!/usr/bin/env bash

# Colors and styles
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
NC='\033[0m'

# Print styled message
print_message() {
    echo -e "${2}${1}${NC}"
}

# Print header
print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════╗"
    echo "║          AppImage Integrator v2.0          ║"
    echo "║        Installation & Setup Wizard         ║"
    echo "╚════════════════════════════════════════════╝${NC}"
    echo
}

# Print section
print_section() {
    echo -e "\n${BLUE}${BOLD}▶ ${1}${NC}\n"
}

# Print step
print_step() {
    echo -e "${CYAN}${BOLD}[${NC}${BLUE}${BOLD} ${1} ${NC}${CYAN}${BOLD}]${NC} ${2}"
}

# Print success
print_success() {
    echo -e "${GREEN}${BOLD}[✓]${NC} ${1}"
}

# Print error
print_error() {
    echo -e "${RED}${BOLD}[✗]${NC} ${1}"
}

# Print the installation complete banner
print_complete() {
    echo -e "\n${GREEN}${BOLD}"
    echo "╔════════════════════════════════════════════╗"
    echo "║        Installation Complete! 🎉           ║"
    echo "╚════════════════════════════════════════════╝${NC}"
}

# Show spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf "${CYAN}${BOLD}[%c]${NC} " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b"
    done
}

# Print the header
print_header

# Check if script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Installation paths
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="appimage-integrator"
TEMP_DIR=$(mktemp -d)

print_section "Starting Installation"

# Download the main script
print_step "1" "Downloading AppImage Integrator..."
curl -fsSL "https://raw.githubusercontent.com/Benyaminrmb/appimage-generator/main/appimage-integrator.sh" -o "$TEMP_DIR/$SCRIPT_NAME" &
spinner $!

if [ $? -ne 0 ]; then
    print_error "Failed to download the script"
    rm -rf "$TEMP_DIR"
    exit 1
fi
print_success "Download complete"

# Make it executable
print_step "2" "Setting up permissions..."
chmod +x "$TEMP_DIR/$SCRIPT_NAME"
print_success "Permissions set"

# Move to installation directory
print_step "3" "Installing to system..."
mv "$TEMP_DIR/$SCRIPT_NAME" "$INSTALL_DIR/"

if [ $? -ne 0 ]; then
    print_error "Failed to install the script"
    rm -rf "$TEMP_DIR"
    exit 1
fi
print_success "Installation complete"

# Create symbolic link for shorter command
print_step "4" "Creating command shortcuts..."
ln -sf "$INSTALL_DIR/$SCRIPT_NAME" "$INSTALL_DIR/appimage"
print_success "Shortcuts created"

# Cleanup
rm -rf "$TEMP_DIR"

# Print completion message
print_complete
echo -e "\n${BOLD}You can now use AppImage Integrator with:${NC}"
echo -e "${CYAN}▪ ${GREEN}appimage-integrator${NC} ${DIM}(full command)${NC}"
echo -e "${CYAN}▪ ${GREEN}appimage${NC} ${DIM}(shorter command)${NC}"
echo
echo -e "${BOLD}Example usage:${NC}"
echo -e "${CYAN}▪${NC} ${GREEN}appimage-integrator${NC} /path/to/your/app.AppImage"
echo -e "${CYAN}▪${NC} ${GREEN}appimage${NC} /path/to/your/app.AppImage"
echo
echo -e "${BLUE}${BOLD}Thank you for installing AppImage Integrator!${NC}"
echo -e "${DIM}For more information, visit: https://github.com/Benyaminrmb/appimage-generator${NC}\n" 