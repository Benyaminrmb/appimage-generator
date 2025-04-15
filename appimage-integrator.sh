#!/usr/bin/env bash
#
# AppImage Desktop Integrator v2.0
# Author: Benyamin Bolhassani
# GitHub: https://github.com/Benyaminrmb/appimage-generator

# ┌──────────────────┐
# │ Style Constants  │
# └──────────────────┘
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ┌──────────────────┐
# │ Default Paths    │
# └──────────────────┘
DEFAULT_APPDIR="$HOME/.local/bin/appimages"
DEFAULT_ICONDIR="$HOME/.local/share/icons/appimages"
DEFAULT_DESKTOPDIR="$HOME/.local/share/applications"

# ┌──────────────────┐
# │ UI Functions     │
# └──────────────────┘

show_welcome() {
    clear
    cat << EOF
${CYAN}${BOLD}
╔═══════════════════════════════════════════════╗
║           AppImage Desktop Integrator         ║
║                   Version 2.0                 ║
╚═══════════════════════════════════════════════╝${NC}

Welcome to the AppImage Integration Wizard! 🚀
This tool will help you integrate your AppImage applications
into your Linux desktop environment.

EOF
}

show_step() {
    local step=$1
    local total=$2
    local message=$3
    echo -e "\n${BLUE}${BOLD}Step ${step}/${total}: ${message}${NC}"
    echo -e "${DIM}$(printf '%.s─' {1..50})${NC}\n"
}

prompt() {
    local message=$1
    local default=$2
    echo -en "${CYAN}${BOLD}?${NC} ${message}${DIM}${default:+ ($default)}${NC}: "
}

success() {
    echo -e "${GREEN}${BOLD}✓${NC} $1"
}

info() {
    echo -e "${BLUE}${BOLD}i${NC} $1"
}

warn() {
    echo -e "${YELLOW}${BOLD}!${NC} $1"
}

error() {
    echo -e "${RED}${BOLD}✗${NC} $1" >&2
}

show_spinner() {
    local pid=$1
    local message=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null; do
        for i in $(seq 0 9); do
            printf "${CYAN}${BOLD}%s${NC} ${message}\r" "${spinstr:$i:1}"
            sleep 0.1
        done
    done
    printf "\r%-60s\r" " "
}

# ┌──────────────────┐
# │ Wizard Steps     │
# └──────────────────┘

step_select_appimage() {
    show_step 1 5 "Select AppImage"
    
    if [ -z "$APPIMAGE_PATH" ]; then
        info "Please drag and drop your AppImage file here, or enter its path:"
        prompt "Path to AppImage"
        read -r APPIMAGE_PATH
        
        if [ ! -f "$APPIMAGE_PATH" ]; then
            error "File not found: $APPIMAGE_PATH"
            return 1
        fi
    fi
    
    success "Selected: $(basename "$APPIMAGE_PATH")"
    return 0
}

step_configure_app() {
    show_step 2 5 "Configure Application"
    
    # Auto-detect name
    local default_name=$(basename "$APPIMAGE_PATH" .AppImage | sed 's/-/ /g' | sed 's/_/ /g')
    info "The wizard will help you configure your application."
    
    prompt "Application Name" "$default_name"
    read -r APP_NAME
    APP_NAME=${APP_NAME:-$default_name}
    
    # Category selection
    echo -e "\nAvailable Categories:"
    local categories=(
        "1" "Utility" "General utility applications"
        "2" "Development" "Development tools"
        "3" "Graphics" "Graphics applications"
        "4" "Audio/Video" "Multimedia applications"
        "5" "Network" "Network applications"
        "6" "Office" "Office applications"
        "7" "Game" "Games"
        "8" "Education" "Educational software"
    )
    
    for ((i=0; i<${#categories[@]}; i+=3)); do
        printf "${CYAN}%s${NC}) %-15s ${DIM}%s${NC}\n" "${categories[i]}" "${categories[i+1]}" "${categories[i+2]}"
    done
    
    prompt "Select category number" "1"
    read -r category_num
    
    case $category_num in
        1) CATEGORIES="Utility;";;
        2) CATEGORIES="Development;";;
        3) CATEGORIES="Graphics;";;
        4) CATEGORIES="AudioVideo;";;
        5) CATEGORIES="Network;";;
        6) CATEGORIES="Office;";;
        7) CATEGORIES="Game;";;
        8) CATEGORIES="Education;";;
        *) CATEGORIES="Utility;";;
    esac
    
    success "Configuration complete!"
    return 0
}

step_install_appimage() {
    show_step 3 5 "Installing AppImage"
    
    # Create directories
    mkdir -p "$DEFAULT_APPDIR" "$DEFAULT_ICONDIR"
    
    # Copy AppImage
    local dest_path="$DEFAULT_APPDIR/$(basename "$APPIMAGE_PATH")"
    info "Copying AppImage to applications directory..."
    cp "$APPIMAGE_PATH" "$dest_path" &
    show_spinner $! "Copying..."
    
    if [ $? -ne 0 ]; then
        error "Failed to copy AppImage"
        return 1
    fi
    
    # Make executable
    chmod +x "$dest_path"
    success "AppImage installed successfully"
    return 0
}

step_create_launcher() {
    show_step 4 5 "Creating Desktop Launcher"
    
    local desktop_file="$DEFAULT_DESKTOPDIR/${APP_NAME// /_}.desktop"
    mkdir -p "$DEFAULT_DESKTOPDIR"
    
    # Create desktop entry
    cat > "$desktop_file" << EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec="$DEFAULT_APPDIR/$(basename "$APPIMAGE_PATH")" %f
Icon=${APP_NAME// /_}
Categories=$CATEGORIES
Comment=AppImage application
Terminal=false
StartupNotify=true
EOF
    
    success "Desktop launcher created successfully"
    return 0
}

step_finalize() {
    show_step 5 5 "Finalizing Installation"
    
    # Update desktop database
    if command -v update-desktop-database >/dev/null; then
        update-desktop-database "$DEFAULT_DESKTOPDIR" &>/dev/null
    fi
    
    cat << EOF

${GREEN}${BOLD}✨ Installation Complete! ✨${NC}

Your application has been successfully integrated:
${CYAN}▪${NC} Name: ${BOLD}$APP_NAME${NC}
${CYAN}▪${NC} Category: ${BOLD}${CATEGORIES%;}${NC}
${CYAN}▪${NC} Location: ${BOLD}$DEFAULT_APPDIR/$(basename "$APPIMAGE_PATH")${NC}

You can now:
${CYAN}1.${NC} Launch from your application menu
${CYAN}2.${NC} Run directly: ${BOLD}$(basename "$APPIMAGE_PATH")${NC}

${BLUE}${BOLD}Thank you for using AppImage Integrator!${NC}
EOF
    return 0
}

# ┌──────────────────┐
# │ Main Function    │
# └──────────────────┘

main() {
    show_welcome
    
    # Run wizard steps
    step_select_appimage || exit 1
    step_configure_app || exit 1
    step_install_appimage || exit 1
    step_create_launcher || exit 1
    step_finalize || exit 1
}

# Parse command line arguments
APPIMAGE_PATH="$1"

# Run main function
main