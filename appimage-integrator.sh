#!/usr/bin/env bash
#
# AppImage Desktop Integrator v2.0
# A tool to integrate AppImage applications into your Linux desktop environment
#
# Author: Benyamin Bolhassani
# GitHub: https://github.com/Benyaminrmb/appimage-generator
# License: MIT
#
# This script integrates AppImages into the Linux desktop environment by:
# - Making AppImages executable
# - Extracting application icons and metadata
# - Creating proper desktop entries
# - Supporting sandboxing options
# - Providing clean uninstallation
# - Handling duplicate entries
#
# Usage: appimage-integrator [options] /path/to/your/application.AppImage
#        ai [options] /path/to/your/application.AppImage  (shorter alias)
#
# ░█▀█░█▀█░█▀█░▀█▀░█▄█░█▀█░█▀▀░█▀▀░░░▀█▀░█▀█░▀█▀░█▀▀░█▀▀░█▀▄░█▀█░▀█▀░█▀█░█▀▄
# ░█▀█░█▀▀░█▀▀░░█░░█░█░█▀█░█░█░█▀▀░░░░█░░█░█░░█░░█▀▀░█░█░█▀▄░█▀█░░█░░█░█░█▀▄
# ░▀░▀░▀░░░▀░░░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀▀░░░░▀░░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀░▀░░▀░░▀▀▀░▀░▀
#
# AppImage Desktop Integrator v2.0
# Author: Your Name Here
# GitHub: https://github.com/yourusername/appimage-integrator
# License: MIT
#
# This script integrates AppImages into the Linux desktop environment by:
# - Making AppImages executable
# - Extracting application icons and metadata
# - Creating proper desktop entries
# - Supporting sandboxing options
# - Providing clean uninstallation
# - Handling duplicate entries
#
# Usage: ./appimage-integrator.sh [options] /path/to/your/application.AppImage
# 

# ┌─────────────────────┐
# │ Constants & Globals │
# └─────────────────────┘

VERSION="2.0"
SCRIPT_NAME="$(basename "$0")"

# Default directories
DEFAULT_APPDIR="$HOME/.local/bin/appimages"
DEFAULT_ICONDIR="$HOME/.local/share/icons/appimages"
DEFAULT_DESKTOPDIR="$HOME/.local/share/applications"

# Global variables with defaults that can be overridden by options
APPDIR="$DEFAULT_APPDIR"
ICONDIR="$DEFAULT_ICONDIR"
DESKTOPDIR="$DEFAULT_DESKTOPDIR"
VERBOSE=false
FORCE_OVERWRITE=false
SANDBOX_MODE="default"
CUSTOM_CATEGORIES=""
CUSTOM_APP_NAME=""
LIST_MODE=false
REMOVE_MODE=false
ICON_EXTRACT_MODE="auto"
AUTO_START=false
INTEGRATION_MODE="user"
DEBUG_MODE=false

# ┌─────────────────────┐
# │ Terminal Colors     │
# └─────────────────────┘

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
NC='\033[0m' # No Color

# ┌─────────────────────┐
# │ Helper Functions    │
# └─────────────────────┘

# Print a message in a specific color
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Print a status message
print_status() {
    echo -e "${BLUE}[${BOLD}●${NC}${BLUE}]${NC} $1"
}

# Print a success message
print_success() {
    echo -e "${GREEN}[${BOLD}✓${NC}${GREEN}]${NC} $1"
}

# Print an error message
print_error() {
    echo -e "${RED}[${BOLD}✗${NC}${RED}]${NC} $1" >&2
}

# Print a warning message
print_warning() {
    echo -e "${YELLOW}[${BOLD}!${NC}${YELLOW}]${NC} $1"
}

# Print an info message
print_info() {
    echo -e "${CYAN}[${BOLD}i${NC}${CYAN}]${NC} $1"
}

# Print a debug message (only if debug mode is enabled)
print_debug() {
    if [ "$DEBUG_MODE" = true ]; then
        echo -e "${MAGENTA}[${BOLD}DEBUG${NC}${MAGENTA}]${NC} $1"
    fi
}

# Print a section header
print_section() {
    echo
    echo -e "${BOLD}${UNDERLINE}$1${NC}"
    echo
}

# Print a progress spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Execute a command with debug output
execute_command() {
    if [ "$DEBUG_MODE" = true ]; then
        print_debug "Executing: $*"
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

# Confirm an action
confirm_action() {
    local message="$1"
    local default="$2"
    
    if [ "$FORCE_OVERWRITE" = true ]; then
        return 0
    fi
    
    local prompt
    local default_upper
    
    if [ "$default" = "y" ]; then
        prompt="[Y/n]"
        default_upper="Y"
    else
        prompt="[y/N]"
        default_upper="N"
    fi
    
    echo -en "${YELLOW}${BOLD}$message $prompt ${NC}"
    read -r response
    
    if [ -z "$response" ]; then
        response="$default_upper"
    fi
    
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check for dependencies
check_dependencies() {
    local missing_deps=()
    
    local deps=("desktop-file-validate" "update-desktop-database" "gio" "zenity")
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            case "$dep" in
                "desktop-file-validate"|"update-desktop-database")
                    missing_deps+=("desktop-file-utils")
                    ;;
                "gio")
                    missing_deps+=("glib2")
                    ;;
                "zenity")
                    missing_deps+=("zenity")
                    ;;
                *)
                    missing_deps+=("$dep")
                    ;;
            esac
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_warning "Some recommended dependencies are missing:"
        printf "  %s\n" "${missing_deps[@]}"
        
        local pkg_manager=""
        if command_exists "apt"; then
            pkg_manager="apt"
            cmd="sudo apt install ${missing_deps[*]}"
        elif command_exists "dnf"; then
            pkg_manager="dnf"
            cmd="sudo dnf install ${missing_deps[*]}"
        elif command_exists "pacman"; then
            pkg_manager="pacman"
            cmd="sudo pacman -S ${missing_deps[*]}"
        elif command_exists "zypper"; then
            pkg_manager="zypper"
            cmd="sudo zypper install ${missing_deps[*]}"
        fi
        
        if [ -n "$pkg_manager" ]; then
            print_info "You can install them with: $cmd"
            if confirm_action "Install missing dependencies now?" "y"; then
                print_status "Installing dependencies..."
                execute_command $cmd
                if [ $? -eq 0 ]; then
                    print_success "Dependencies installed successfully"
                else
                    print_error "Failed to install dependencies"
                    print_info "Continuing without recommended dependencies..."
                fi
            fi
        fi
    fi
}

# ┌─────────────────────┐
# │ AppImage Functions  │
# └─────────────────────┘

# Check if a file is a valid AppImage
check_appimage() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        return 1
    fi
    
    # Check file extension
    if [[ ! "$file" == *.AppImage && ! "$file" == *.appimage ]]; then
        print_warning "File does not have an .AppImage extension: $file"
        
        # Check if it's an ELF file
        if file "$file" | grep -q "ELF"; then
            print_info "File appears to be an executable. Continuing..."
        else
            print_error "File does not appear to be an executable"
            if ! confirm_action "Continue anyway?" "n"; then
                return 1
            fi
        fi
    fi
    
    # Check if it's an Electron app based on file signature instead of trying to execute
    if file "$file" | grep -q -i "electron\|chrome\|chromium"; then
        print_info "Detected Electron-based AppImage (like Outline Client)"
        print_info "Will apply --no-sandbox flag automatically"
        ELECTRON_APP=true
    elif [[ "$file" == *"Outline"* || "$file" == *"outline"* ]]; then
        # Special case for Outline which is known to be Electron-based
        print_info "Detected Outline Client (Electron-based AppImage)"
        print_info "Will apply --no-sandbox flag automatically"
        ELECTRON_APP=true
    fi

    # Don't test execution for Electron apps which might fail due to sandbox issues
    if [ "$ELECTRON_APP" = true ]; then
        print_status "Skipping test execution for Electron app"
    else
        print_status "Validating AppImage..."
        if timeout 3s "$file" --appimage-extract-and-run --version >/dev/null 2>&1; then
            print_success "AppImage validated successfully"
        else
            print_warning "AppImage validation failed"
            print_info "It may require special flags when running"

            # Check if it might be Electron despite not being detected earlier
            if hexdump -n 10000 -C "$file" | grep -q -i "electron\|chrome\|chromium"; then
                print_info "AppImage may be Electron-based, applying --no-sandbox flag"
                ELECTRON_APP=true
            fi
        fi
    fi

    return 0
}

# Extract AppImage information
extract_appimage_info() {
    local appimage_path="$1"
    local temp_dir="$2"
    local filename=$(basename "$appimage_path")
    local info_file="$temp_dir/appimage_info.txt"
    
    # Try to get version information
    VERSION_INFO=$(strings "$appimage_path" | grep -E "^[0-9]+\.[0-9]+(\.[0-9]+)?(-[a-zA-Z0-9]+)?$" | head -1)
    if [ -z "$VERSION_INFO" ]; then
        VERSION_INFO="unknown"
    fi
    
    # Try to extract with --appimage-extract
    print_status "Extracting AppImage to find metadata..."
    cd "$temp_dir" || return 1
    
    # Use a timeout in case the AppImage hangs
    timeout 30s "$appimage_path" --appimage-extract >/dev/null 2>&1 &
    EXTRACT_PID=$!
    
    # Show spinner while extracting
    spinner $EXTRACT_PID
    
    # Check if extraction was successful
    if [ -d "squashfs-root" ]; then
        print_success "AppImage extraction successful"
        
        # Try to find desktop file
        DESKTOP_FILES=$(find "squashfs-root" -name "*.desktop" 2>/dev/null)
        
        if [ -n "$DESKTOP_FILES" ]; then
            MAIN_DESKTOP_FILE=$(echo "$DESKTOP_FILES" | head -1)
            print_debug "Found desktop file: $MAIN_DESKTOP_FILE"
            
            # Parse the desktop file
            if [ -f "$MAIN_DESKTOP_FILE" ]; then
                APP_NAME_DESKTOP=$(grep -E "^Name=" "$MAIN_DESKTOP_FILE" | head -1 | cut -d= -f2-)
                COMMENT_DESKTOP=$(grep -E "^Comment=" "$MAIN_DESKTOP_FILE" | head -1 | cut -d= -f2-)
                CATEGORIES_DESKTOP=$(grep -E "^Categories=" "$MAIN_DESKTOP_FILE" | head -1 | cut -d= -f2-)
                EXEC_DESKTOP=$(grep -E "^Exec=" "$MAIN_DESKTOP_FILE" | head -1 | cut -d= -f2-)
                
                if [ -n "$APP_NAME_DESKTOP" ]; then
                    echo "Name=$APP_NAME_DESKTOP" >> "$info_file"
                fi
                if [ -n "$COMMENT_DESKTOP" ]; then
                    echo "Comment=$COMMENT_DESKTOP" >> "$info_file"
                fi
                if [ -n "$CATEGORIES_DESKTOP" ]; then
                    echo "Categories=$CATEGORIES_DESKTOP" >> "$info_file"
                fi
                if [ -n "$EXEC_DESKTOP" ]; then
                    echo "Exec=$EXEC_DESKTOP" >> "$info_file"
                fi
            fi
        fi
        
        return 0
    else
        print_warning "AppImage extraction failed or timed out"
        return 1
    fi
}

# Find icon in extracted AppImage
find_icon() {
    local temp_dir="$1"
    local icon_path="$2"
    local icon_found=false
    
    if [ ! -d "$temp_dir/squashfs-root" ]; then
        print_debug "No squashfs-root directory found"
        return 1
    fi
    
    # Common icon locations in AppImages
    local icon_candidates=(
        "squashfs-root/.DirIcon"
        "squashfs-root/AppRun.png"
        "squashfs-root/*.png"
        "squashfs-root/*.svg"
        "squashfs-root/usr/share/icons/hicolor/*/apps/*.png"
        "squashfs-root/usr/share/pixmaps/*.png"
    )
    
    # Try to find an icon starting with the highest quality first
    local found_icons=""
    for size in 512 256 128 64 48 32 24 16; do
        found_icons=$(find "$temp_dir/squashfs-root" -path "*/icons/hicolor/${size}x${size}/apps/*.png" 2>/dev/null)
        if [ -n "$found_icons" ]; then
            break
        fi
    done
    
    # If no size-specific icon found, try other candidates
    if [ -z "$found_icons" ]; then
        for pattern in "${icon_candidates[@]}"; do
            found_icons=$(find "$temp_dir/$pattern" 2>/dev/null | head -n 1)
            if [ -n "$found_icons" ]; then
                break
            fi
        done
    fi
    
    if [ -n "$found_icons" ]; then
        # Use the first found icon
        local found_icon=$(echo "$found_icons" | head -n 1)
        print_success "Found icon: $found_icon"
        
        # Copy the icon to the icon directory
        mkdir -p "$(dirname "$icon_path")"
        cp "$found_icon" "$icon_path"
        icon_found=true
    fi
    
    if [ "$icon_found" = true ]; then
        return 0
    else
        return 1
    fi
}


# Improved create_desktop_entry function
create_desktop_entry() {
    local app_name="$1"
    local exec_path="$2"
    local icon_path="$3"
    local desktop_file="$4"
    local comment="$5"
    local categories="$6"

    # Prepare sandbox options and execution mode for maximum compatibility
    local exec_line=""

    # Add specific handling for Outline Client and other Electron apps
    if [ "$ELECTRON_APP" = true ] || [[ "$app_name" == *"Outline"* ]]; then
        print_debug "Using Electron-compatible execution method"
        # Use --no-sandbox flag explicitly for Electron apps
        exec_line="\"$exec_path\" --no-sandbox %f"
    else
        # For non-Electron apps, use normal execution with any sandbox options
        local sandbox_params=""
        case "$SANDBOX_MODE" in
            "none")
                sandbox_params="--no-sandbox"
                ;;
            "firejail")
                if command_exists "firejail"; then
                    exec_line="firejail --private \"$exec_path\" %f"
                else
                    exec_line="\"$exec_path\" %f"
                    print_warning "Firejail not found. Defaulting to normal execution."
                fi
                ;;
            "flatpak-spawn")
                if command_exists "flatpak-spawn"; then
                    exec_line="flatpak-spawn --host \"$exec_path\" %f"
                else
                    exec_line="\"$exec_path\" %f"
                    print_warning "flatpak-spawn not found. Defaulting to normal execution."
                fi
                ;;
            *)
                exec_line="\"$exec_path\" %f"
                ;;
        esac
    fi

    # Create the directory if it doesn't exist
    mkdir -p "$(dirname "$desktop_file")"

    # Create desktop entry with improved exec line
    cat > "$desktop_file" << EOF
[Desktop Entry]
Type=Application
Name=$app_name
Exec=$exec_line --no-sandbox
Icon=$icon_path
Comment=$comment
Categories=$categories
Terminal=false
StartupNotify=true
EOF

    # Add MimeType if found in original desktop file
    if [ -f "$TEMP_DIR/squashfs-root/"*".desktop" ]; then
        MIME_TYPES=$(grep -E "^MimeType=" "$TEMP_DIR/squashfs-root/"*".desktop" | head -1 | cut -d= -f2-)
        if [ -n "$MIME_TYPES" ]; then
            echo "MimeType=$MIME_TYPES" >> "$desktop_file"
        fi
    fi

    # Add StartupWMClass if extracted
    if [ -f "$TEMP_DIR/squashfs-root/"*".desktop" ]; then
        WM_CLASS=$(grep -E "^StartupWMClass=" "$TEMP_DIR/squashfs-root/"*".desktop" | head -1 | cut -d= -f2-)
        if [ -n "$WM_CLASS" ]; then
            echo "StartupWMClass=$WM_CLASS" >> "$desktop_file"
        fi
    fi

    # Add to autostart if requested
    if [ "$AUTO_START" = true ]; then
        local autostart_dir="$HOME/.config/autostart"
        mkdir -p "$autostart_dir"
        cp "$desktop_file" "$autostart_dir/"
        print_success "Added $app_name to autostart"
    fi

    # Validate desktop file if desktop-file-validate is available
    if command_exists "desktop-file-validate"; then
        if desktop-file-validate "$desktop_file" >/dev/null 2>&1; then
            print_success "Desktop entry validated successfully"
        else
            print_warning "Desktop entry validation failed, but the file was created anyway"
        fi
    fi

    # Update desktop database if update-desktop-database is available
    if command_exists "update-desktop-database"; then
        execute_command update-desktop-database "$DESKTOPDIR"
    fi

    # Set file permissions
    chmod 644 "$desktop_file"

    return 0
}
verify_appimage_execution() {
    local app_path="$1"
    local app_name="$2"

    print_status "Verifying that the application can be launched..."

    local cmd=""
    if [ "$ELECTRON_APP" = true ]; then
        cmd="\"$app_path\" --no-sandbox --version"
    else
        cmd="\"$app_path\" --version"
    fi

    # Try to run in the background with a timeout
    timeout 5s bash -c "$cmd" >/dev/null 2>&1 &
    local pid=$!

    # Wait briefly
    sleep 2

    # Check if process is still running or exited successfully
    if kill -0 $pid 2>/dev/null || wait $pid; then
        print_success "Application appears to be working correctly"
        # Kill the process if it's still running
        kill $pid 2>/dev/null
        return 0
    else
        print_warning "Application might have issues running"
        print_info "Try running it manually: $app_path --no-sandbox"
        return 1
    fi
}

# List installed AppImages
list_installed_appimages() {
    print_section "Installed AppImage Applications"
    
    if [ ! -d "$DEFAULT_DESKTOPDIR" ]; then
        print_info "No desktop entries directory found"
        return 1
    fi
    
    local count=0
    local installed_apps=()
    
    while IFS= read -r file; do
        if grep -q "Exec=.*\.AppImage" "$file" 2>/dev/null; then
            local name=$(grep -E "^Name=" "$file" | head -1 | cut -d= -f2-)
            local exec_path=$(grep -E "^Exec=" "$file" | head -1 | cut -d= -f2- | sed 's/ %[fFuU]$//' | sed 's/--no-sandbox//' | tr -s ' ' | sed 's/^ //')
            
            # Clean the exec path to get just the AppImage path
            exec_path=$(echo "$exec_path" | sed 's/firejail --private //' | sed 's/flatpak-spawn --host //')
            
            installed_apps+=("$name|$exec_path|$file")
            ((count++))
        fi
    done < <(find "$DEFAULT_DESKTOPDIR" -name "*.desktop" 2>/dev/null)
    
    if [ $count -eq 0 ]; then
        print_info "No AppImage applications found"
        return 0
    fi
    
    print_info "Found $count AppImage applications:"
    echo
    
    # Print a nice table
    printf "${BOLD}%-4s %-30s %-50s${NC}\n" "№" "Name" "Path"
    printf "%-4s %-30s %-50s\n" "---" "------------------------------" "--------------------------------------------------"
    
    local i=1
    for app in "${installed_apps[@]}"; do
        IFS='|' read -r name exec_path file <<< "$app"
        printf "%-4s ${GREEN}%-30s${NC} ${BLUE}%-50s${NC}\n" "$i." "${name:0:29}" "${exec_path:0:49}"
        ((i++))
    done
    
    echo
    print_info "Use '$SCRIPT_NAME --remove <number>' to remove an application"
    
    return 0
}

# Remove installed AppImage
remove_appimage() {
    local query="$1"
    
    if [ ! -d "$DEFAULT_DESKTOPDIR" ]; then
        print_error "No desktop entries directory found"
        return 1
    fi
    
    local installed_apps=()
    
    while IFS= read -r file; do
        if grep -q "Exec=.*\.AppImage" "$file" 2>/dev/null; then
            local name=$(grep -E "^Name=" "$file" | head -1 | cut -d= -f2-)
            local exec_path=$(grep -E "^Exec=" "$file" | head -1 | cut -d= -f2- | sed 's/ %[fFuU]$//' | tr -s ' ')
            
            installed_apps+=("$name|$exec_path|$file")
        fi
    done < <(find "$DEFAULT_DESKTOPDIR" -name "*.desktop" 2>/dev/null)
    
    local matching_apps=()
    
    # If query is a number, select that app from the list
    if [[ "$query" =~ ^[0-9]+$ ]] && [ "$query" -le "${#installed_apps[@]}" ] && [ "$query" -gt 0 ]; then
        matching_apps=("${installed_apps[$query-1]}")
    else
        # Otherwise search by name
        for app in "${installed_apps[@]}"; do
            IFS='|' read -r name exec_path file <<< "$app"
            if [[ "$name" == *"$query"* ]]; then
                matching_apps+=("$app")
            fi
        done
    fi
    
    if [ ${#matching_apps[@]} -eq 0 ]; then
        print_error "No matching AppImages found for '$query'"
        list_installed_appimages
        return 1
    elif [ ${#matching_apps[@]} -gt 1 ]; then
        print_warning "Multiple matches found:"
        local i=1
        for app in "${matching_apps[@]}"; do
            IFS='|' read -r name exec_path file <<< "$app"
            echo "$i. $name ($exec_path)"
            ((i++))
        done
        
        echo
        echo -n "Enter number to remove (1-${#matching_apps[@]}): "
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -le "${#matching_apps[@]}" ] && [ "$selection" -gt 0 ]; then
            IFS='|' read -r name exec_path file <<< "${matching_apps[$selection-1]}"
        else
            print_error "Invalid selection"
            return 1
        fi
    else
        IFS='|' read -r name exec_path file <<< "${matching_apps[0]}"
    fi
    
    print_status "Removing $name ($exec_path)"
    
    # Extract the AppImage path
    local appimage_path=$(echo "$exec_path" | sed 's/firejail --private //' | sed 's/flatpak-spawn --host //' | sed 's/--no-sandbox//' | awk '{print $1}')
    
    # Check if appimage file is in the default directory
    if [[ "$appimage_path" == "$DEFAULT_APPDIR"/* ]]; then
        if confirm_action "Remove the AppImage file ($appimage_path)?" "y"; then
            if rm -f "$appimage_path"; then
                print_success "AppImage file removed"
            else
                print_error "Failed to remove AppImage file"
            fi
        fi
    fi
    
    # Remove desktop file
    if rm -f "$file"; then
        print_success "Desktop entry removed"
    else
        print_error "Failed to remove desktop entry"
    fi
    
    # Remove autostart entry if it exists
    local autostart_file="$HOME/.config/autostart/$(basename "$file")"
    if [ -f "$autostart_file" ]; then
        if rm -f "$autostart_file"; then
            print_success "Removed from autostart"
        fi
    fi
    
    # Update desktop database
    if command_exists "update-desktop-database"; then
        execute_command update-desktop-database "$DEFAULT_DESKTOPDIR"
    fi
    
    print_success "AppImage '$name' has been successfully removed"
    return 0
}

# ┌─────────────────────┐
# │ Main Functions      │
# └─────────────────────┘

# Show help and usage information
show_help() {
    cat << EOF
${BOLD}AppImage Integrator v${VERSION}${NC}
A tool to integrate AppImage applications into your Linux desktop environment.

${BOLD}USAGE:${NC}
  $SCRIPT_NAME [OPTIONS] /path/to/your/application.AppImage

${BOLD}OPTIONS:${NC}
  -h, --help              Show this help message and exit
  -v, --verbose           Enable verbose output
  -f, --force             Force overwrite existing files without asking
  -n, --name NAME         Specify custom application name
  -c, --categories CATS   Specify application categories (semicolon-separated)
  -s, --sandbox MODE      Set sandbox mode (none, firejail, flatpak-spawn, default)
  -d, --directory DIR     Set custom directory for AppImages
  -a, --autostart         Add application to autostart
  -l, --list              List installed AppImage applications
  -r, --remove NAME/NUM   Remove an installed AppImage application
  --icon-extract MODE     Icon extraction mode (auto, none, force)
  --debug                 Enable debug output

${BOLD}EXAMPLES:${NC}
  # Basic usage
  $SCRIPT_NAME ~/Downloads/MyApp.AppImage
  
  # Set custom name and categories
  $SCRIPT_NAME --name "My Application" --categories "Development;Utility;" ~/Downloads/MyApp.AppImage
  
  # Disable sandboxing
  $SCRIPT_NAME --sandbox none ~/Downloads/MyApp.AppImage
  
  # List installed AppImages
  $SCRIPT_NAME --list
  
  # Remove an installed AppImage (by name or number)
  $SCRIPT_NAME --remove "MyApp"
  $SCRIPT_NAME --remove 1

${BOLD}INTEGRATION MODES:${NC}
  - None: No sandbox parameters
  - Firejail: Run with firejail sandboxing (firejail must be installed)
  - Flatpak-spawn: Run within a flatpak environment (for use inside flatpaks)
  - Default: Automatic detection

${BOLD}NOTES:${NC}
  - AppImages are copied to ${DEFAULT_APPDIR} by default
  - Desktop entries are created in ${DEFAULT_DESKTOPDIR}
  - Icons are extracted and saved to ${DEFAULT_ICONDIR}
EOF
}

# Show version information
show_version() {
    cat << EOF
AppImage Integrator v${VERSION}
EOF
}

# Parse command line arguments
parse_args() {
    APPIMAGE_PATH=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE_OVERWRITE=true
                shift
                ;;
            -n|--name)
                if [ -n "$2" ]; then
                    CUSTOM_APP_NAME="$2"
                    shift 2
                else
                    print_error "Missing argument for --name"
                    exit 1
                fi
                ;;
            -c|--categories)
                if [ -n "$2" ]; then
                    CUSTOM_CATEGORIES="$2"
                    shift 2
                else
                    print_error "Missing argument for --categories"
                    exit 1
                fi
                ;;
            -s|--sandbox)
                if [ -n "$2" ]; then
                    case "$2" in
                        none|firejail|flatpak-spawn|default)
                            SANDBOX_MODE="$2"
                            ;;
                        *)
                            print_error "Invalid sandbox mode: $2"
                            exit 1
                            ;;
                    esac
                    shift 2
                else
                    print_error "Missing argument for --sandbox"
                    exit 1
                fi
                ;;
            -d|--directory)
                if [ -n "$2" ]; then
                    APPDIR="$2"
                    shift 2
                else
                    print_error "Missing argument for --directory"
                    exit 1
                fi
                ;;
            -l|--list)
                LIST_MODE=true
                shift
                ;;
            -r|--remove)
                if [ -n "$2" ]; then
                    REMOVE_MODE=true
                    REMOVE_QUERY="$2"
                    shift 2
                else
                    print_error "Missing argument for --remove"
                    exit 1
                fi
                ;;
            -a|--autostart)
                AUTO_START=true
                shift
                ;;
            --icon-extract)
                if [ -n "$2" ]; then
                    case "$2" in
                        auto|none|force)
                            ICON_EXTRACT_MODE="$2"
                            ;;
                        *)
                            print_error "Invalid icon extraction mode: $2"
                            exit 1
                            ;;
                    esac
                    shift 2
                else
                    print_error "Missing argument for --icon-extract"
                    exit 1
                fi
                ;;
            --debug)
                DEBUG_MODE=true
                VERBOSE=true
                shift
                ;;
            --version)
                show_version
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [ -z "$APPIMAGE_PATH" ]; then
                    APPIMAGE_PATH="$1"
                else
                    print_error "Multiple AppImage paths specified"
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check for required arguments based on mode
    if [ "$LIST_MODE" = false ] && [ "$REMOVE_MODE" = false ] && [ -z "$APPIMAGE_PATH" ]; then
        print_error "No AppImage path specified"
        show_help
        exit 1
    fi
}

# Main function
# Improved main function with cleaner output
main() {
    # Print welcome banner with cleaner design
    echo
    print_color "${CYAN}${BOLD}" "┌─────────────────────────────────────────────┐"
    print_color "${CYAN}${BOLD}" "│         AppImage Desktop Integrator         │"
    print_color "${CYAN}${BOLD}" "│                Version ${VERSION}                │"
    print_color "${CYAN}${BOLD}" "└─────────────────────────────────────────────┘"
    echo

    # Handle list mode
    if [ "$LIST_MODE" = true ]; then
        list_installed_appimages
        exit 0
    fi

    # Handle remove mode
    if [ "$REMOVE_MODE" = true ]; then
        remove_appimage "$REMOVE_QUERY"
        exit $?
    fi

    # Check dependencies quietly unless in verbose mode
    if [ "$VERBOSE" = true ]; then
        check_dependencies
    else
        check_dependencies > /dev/null
    fi

    # Initial setup
    ELECTRON_APP=false

    # Check if the specified AppImage is valid
    if ! check_appimage "$APPIMAGE_PATH"; then
        exit 1
    fi

    # Get absolute path to AppImage
    APPIMAGE_PATH=$(realpath "$APPIMAGE_PATH")

    # Get filename without path
    APPIMAGE_FILENAME=$(basename "$APPIMAGE_PATH")

    # Get app name from filename (without extension)
    if [ -z "$CUSTOM_APP_NAME" ]; then
        APP_NAME="${APPIMAGE_FILENAME%.*}"
        # Clean up app name (replace dashes and underscores with spaces)
        APP_NAME=$(echo "$APP_NAME" | sed 's/[-_]/ /g' | sed 's/\b\(.\)/\u\1/g')
    else
        APP_NAME="$CUSTOM_APP_NAME"
    fi

    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    print_debug "Created temporary directory: $TEMP_DIR"

    # Destination paths
    mkdir -p "$APPDIR"
    DEST_APPIMAGE="$APPDIR/$APPIMAGE_FILENAME"
    ICON_PATH="$ICONDIR/${APP_NAME// /_}.png"
    DESKTOP_FILE="$DESKTOPDIR/${APP_NAME// /_}.desktop"

    # Print a clean summary of what will be done
    print_section "Installation Summary"
    print_info "Application: ${BOLD}${GREEN}$APP_NAME${NC}"
    print_info "Source: $APPIMAGE_PATH"
    print_info "Destination: $DEST_APPIMAGE"
    echo

    # Check if AppImage is already integrated
    if [ -f "$DESKTOP_FILE" ]; then
        print_warning "AppImage already integrated: $APP_NAME"
        if ! confirm_action "Overwrite existing integration?" "n"; then
            cleanup
            exit 0
        fi
    fi

    # Copy AppImage to destination with progress indicator
    print_status "Installing AppImage..."
    if [ "$APPIMAGE_PATH" != "$DEST_APPIMAGE" ]; then
        # Show progress for large files
        if [ $(stat -c%s "$APPIMAGE_PATH") -gt 10485760 ]; then # > 10MB
            rsync -ah --progress "$APPIMAGE_PATH" "$DEST_APPIMAGE" || {
                print_error "Failed to copy AppImage"
                cleanup
                exit 1
            }
        else
            if cp "$APPIMAGE_PATH" "$DEST_APPIMAGE"; then
                print_success "AppImage copied to destination"
            else
                print_error "Failed to copy AppImage"
                cleanup
                exit 1
            fi
        fi
    else
        print_info "AppImage is already in the target directory"
    fi

    # Make AppImage executable
    chmod +x "$DEST_APPIMAGE" || {
        print_error "Failed to make AppImage executable"
        cleanup
        exit 1
    }

    # Extract AppImage metadata
    print_status "Extracting application information..."
    extract_appimage_info "$DEST_APPIMAGE" "$TEMP_DIR" > /dev/null 2>&1

    # Set default comment and categories if not provided
    COMMENT="AppImage application"
    if [ -f "$TEMP_DIR/appimage_info.txt" ]; then
        EXTRACTED_COMMENT=$(grep -E "^Comment=" "$TEMP_DIR/appimage_info.txt" | cut -d= -f2-)
        if [ -n "$EXTRACTED_COMMENT" ]; then
            COMMENT="$EXTRACTED_COMMENT"
        fi

        if [ -z "$CUSTOM_CATEGORIES" ]; then
            EXTRACTED_CATEGORIES=$(grep -E "^Categories=" "$TEMP_DIR/appimage_info.txt" | cut -d= -f2-)
            if [ -n "$EXTRACTED_CATEGORIES" ]; then
                CATEGORIES="$EXTRACTED_CATEGORIES"
            else
                CATEGORIES="Utility;"
            fi
        else
            CATEGORIES="$CUSTOM_CATEGORIES"
        fi
    else
        CATEGORIES="Utility;"
    fi

    # If custom categories were specified, use those
    if [ -n "$CUSTOM_CATEGORIES" ]; then
        CATEGORIES="$CUSTOM_CATEGORIES"
    fi

    # Extract and save icon
    print_status "Processing application icon..."
    if [ "$ICON_EXTRACT_MODE" != "none" ]; then
        if find_icon "$TEMP_DIR" "$ICON_PATH" > /dev/null 2>&1; then
            print_success "Application icon extracted successfully"
            ICON_EXTRACTED=true
        else
            print_info "Using default application icon"
            ICON_EXTRACTED=false

            # Use generic AppImage icon if available
            if [ -f "/usr/share/icons/hicolor/256x256/apps/appimage.png" ]; then
                cp "/usr/share/icons/hicolor/256x256/apps/appimage.png" "$ICON_PATH"
                ICON_EXTRACTED=true
            fi
        fi
    else
        ICON_EXTRACTED=false
    fi

    # If icon extraction failed and not forced, use app name as icon
    if [ "$ICON_EXTRACTED" = false ]; then
        ICON_PATH="${APP_NAME// /_}"
    fi

    # Create desktop entry
    print_status "Creating desktop shortcut..."
    if create_desktop_entry "$APP_NAME" "$DEST_APPIMAGE" "$ICON_PATH" "$DESKTOP_FILE" "$COMMENT" "$CATEGORIES"; then
        print_success "Desktop shortcut created successfully"
    else
        print_error "Failed to create desktop shortcut"
        cleanup
        exit 1
    fi


    # After creating the desktop entry:
    if [ "$ELECTRON_APP" = true ]; then
        print_info "For ${BOLD}Outline Client${NC} and similar Electron apps, you might need to run it with:"
        echo
        echo -e "  ${GREEN}${BOLD}$DEST_APPIMAGE --no-sandbox${NC}"
        echo

        # Add a script to help running with correct parameters
        WRAPPER_SCRIPT="$APPDIR/${APP_NAME// /_}_launcher.sh"
        cat > "$WRAPPER_SCRIPT" << EOF
#!/bin/bash
# Launcher script for $APP_NAME
exec "$DEST_APPIMAGE" --no-sandbox "\$@"
EOF
  chmod +x "$WRAPPER_SCRIPT"

  print_info "Created a launcher script that includes the required parameters:"
  echo -e "  ${GREEN}${BOLD}$WRAPPER_SCRIPT${NC}"

  # Update the desktop file to use the wrapper
  sed -i "s|Exec=.*|Exec=\"$WRAPPER_SCRIPT\" %f|" "$DESKTOP_FILE"
  print_info "Updated desktop shortcut to use the launcher script"
    fi

    # Integration complete
    print_section "Installation Complete"
    print_success "${BOLD}$APP_NAME has been successfully installed!${NC}"

    # Add special note for Electron apps
    if [ "$ELECTRON_APP" = true ]; then
        print_info "This is an Electron-based app and has been configured with --no-sandbox"
        print_info "This fixes the common sandbox error seen with apps like Outline Client"
    fi

    # Suggest running the application with a cleaner format
    echo
    print_info "You can now find ${BOLD}$APP_NAME${NC} in your application menu"
    print_info "Or run it directly with this command:"
    echo
    echo -e "  ${GREEN}${BOLD}$DEST_APPIMAGE${NC}"
    echo
    
    # Cleanup
    cleanup
    exit 0
}

# Cleanup function to remove temporary files
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        print_debug "Cleaning up temporary directory: $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
}

# Error handling for script termination
handle_error() {
    print_error "Script terminated unexpectedly"
    cleanup
    exit 1
}

# Set up error handling
trap handle_error SIGINT SIGTERM

# Parse command line arguments and run main function
parse_args "$@"
main
