#!/bin/bash

# Terminal handling
setup_terminal() {
    # Save screen
    tput smcup
    # Hide cursor
    tput civis
    # Turn off echoing
    stty -echo
    # Turn off buffering
    stty -icanon
}

restore_terminal() {
    # Restore screen
    tput rmcup
    # Show cursor
    tput cnorm
    # Restore terminal settings
    stty echo
    stty icanon
}

# Ensure we restore terminal on exit
trap restore_terminal EXIT INT TERM

# ANSI color codes and styles
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
REVERSE='\033[7m'

# Box drawing characters
TOP_LEFT='+'
TOP_RIGHT='+'
BOTTOM_LEFT='+'
BOTTOM_RIGHT='+'
HORIZONTAL='-'
VERTICAL='|'

# Initialize services status (1 = enabled, 0 = disabled)
declare -A services=(
    ["Tautulli"]=1
    ["Organizr"]=1
    ["FileBrowser"]=1
    ["Nginx Proxy Manager"]=1
    ["Dozzle"]=1
    ["Bazarr"]=1
)

# Service to compose mapping (lowercase service names in docker-compose.yml)
declare -A service_mapping=(
    ["Tautulli"]="tautulli"
    ["Organizr"]="organizr"
    ["FileBrowser"]="filebrowser"
    ["Nginx Proxy Manager"]="nginx-proxy-manager"
    ["Dozzle"]="dozzle"
    ["Bazarr"]="bazarr"
)

# Environment variable configuration
declare -A env_vars=(
    ["TZ"]="America/New_York:Timezone (e.g. America/New_York)"
    ["PUID"]="1000:User ID for service permissions"
    ["PGID"]="1000:Group ID for service permissions"
    ["DATA_PATH"]="./data:Path for media and application data"
    ["CONFIG_PATH"]="./config:Path for configuration files"
    ["UMASK"]="002:File permission mask"
)

# Initialize default values
TZ="America/New_York"
PUID="1000"
PGID="1000"
DATA_PATH="./data"
CONFIG_PATH="./config"
UMASK="002"

# Current selected item and total count
selected=0
total_services=${#services[@]}

# Current selected env var
selected_env=0
total_env_vars=${#env_vars[@]}

# Function to display the menu
display_menu() {
    clear
    
    # Calculate maximum width needed
    local max_width=70
    
    # Draw header
    draw_box $max_width "SuperPlex Setup (Step 1 of 3)"
    
    # Instructions
    echo -e "\n${BOLD}Optional Services Configuration${NC}"
    echo -e "${DIM}Choose which additional features you want in your media server.${NC}\n"
    
    echo -e "${BOLD}Navigation:${NC}"
    echo -e "  ${YELLOW}↑/↓${NC}      Move selection"
    echo -e "  ${YELLOW}[Space]${NC}  Toggle service"
    echo -e "  ${YELLOW}[Enter]${NC}  Save and continue"
    echo -e "  ${YELLOW}[Q]${NC}      Cancel setup\n"
    
    # Calculate totals for optional services
    local total_enabled=0
    
    # Calculate optional services
    for service in "${!services[@]}"; do
        if [ "${services[$service]}" -eq 1 ]; then
            ((total_enabled++))
        fi
    done
    
    # Table header
    echo -e "  ${BOLD}Optional Services:${NC}"
    echo -e "  ${BLUE}----------------------------------------${NC}"
    
    # Get all service names and sort them
    local names=("${!services[@]}")
    IFS=$'\n' sorted=($(sort <<<"${names[*]}"))
    unset IFS
    
    # Display services
    for i in "${!sorted[@]}"; do
        local service="${sorted[$i]}"
        local status="${services[$service]}"
        local prefix="  "
        
        if [ $i -eq $selected ]; then
            prefix=" >"
            echo -en "${REVERSE}"
        fi
        
        # Status indicator
        if [ "$status" -eq 1 ]; then
            printf "${prefix} %-30s [${GREEN}ON${NC}]" "$service"
        else
            printf "${prefix} %-30s [${RED}OFF${NC}]" "$service"
        fi
        
        if [ $i -eq $selected ]; then
            echo -en "${NC}"
        fi
        echo
    done
    
    echo -e "  ${BLUE}----------------------------------------${NC}"
    echo -e "  ${DIM}Core services + ${GREEN}$total_enabled${NC} optional features enabled${NC}"
    
    # Show current service description
    local current_service="${sorted[$selected]}"
    echo -e "\n${BOLD}About:${NC}"
    case $current_service in
        "Tautulli")
            echo "  Monitor Plex Media Server usage, track user activity,"
            echo "  view playback history, and get notifications."
            ;;
        "Organizr")
            echo "  A unified dashboard for all your services. Access"
            echo "  everything from one clean, organized interface."
            ;;
        "FileBrowser")
            echo "  Browse and manage your media files through a web"
            echo "  interface. Upload, delete, and organize content."
            ;;
        "Nginx Proxy Manager")
            echo "  Manage SSL certificates and access your services"
            echo "  securely from outside your network."
            ;;
        "Dozzle")
            echo "  View Docker container logs in real-time through"
            echo "  an easy-to-use web interface."
            ;;
        "Bazarr")
            echo "  Automatically find and download subtitles for"
            echo "  your movies and TV shows."
            ;;
    esac
    
    # Show next steps
    echo -e "\n${DIM}Next steps: Network configuration → Storage setup${NC}"
}

# Function to show confirmation dialog
confirm_save() {
    clear
    draw_box $max_width "Review Settings"
    
    echo -e "\n${BOLD}Selected Services:${NC}\n"
    
    local enabled_count=0
    local disabled_count=0
    
    echo -e "  ${BLUE}----------------------------------------${NC}"
    
    for service in "${!services[@]}"; do
        local status="${services[$service]}"
        if [ "$status" -eq 1 ]; then
            printf "  %-30s [${GREEN}ON${NC}]\n" "$service"
            ((enabled_count++))
        else
            printf "  %-30s [${RED}OFF${NC}]\n" "$service"
            ((disabled_count++))
        fi
    done
    
    echo -e "  ${BLUE}----------------------------------------${NC}"
    
    echo -e "\n${BOLD}Summary:${NC}"
    echo -e "  • ${GREEN}$enabled_count${NC} services enabled"
    echo -e "  • ${RED}$disabled_count${NC} services disabled"
    
    echo -e "\n${DIM}You can modify these settings later in docker-compose.yml${NC}"
    echo -e "\n${YELLOW}Continue to network setup? [y/N]${NC} "
    
    read -rsn1 answer
    case $answer in
        [yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to generate modified docker-compose file
generate_compose_file() {
    echo -e "\n${BOLD}${BLUE}Generating configuration...${NC}"
    
    # Create a copy of the original compose file
    cp docker-compose.yml test-docker-compose.yml
    
    # Process each service
    for service in "${!services[@]}"; do
        local status="${services[$service]}"
        local compose_name="${service_mapping[$service]}"
        
        if [ "$status" -eq 0 ]; then
            echo -e "${RED}Removing${NC} $service..."
            # Service is disabled - remove it from the test file
            sed -i "/^  ${compose_name}:/,/^  [a-z]/ { /^  [a-z]/!d; /^  ${compose_name}:/d; }" test-docker-compose.yml
        else
            echo -e "${GREEN}Keeping${NC} $service..."
        fi
    done
    
    # Clean up any empty lines at the end
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' test-docker-compose.yml
    
    echo -e "\n${BOLD}${GREEN}Configuration saved to test-docker-compose.yml${NC}"
    echo -e "${DIM}Review the file and if satisfied, you can replace docker-compose.yml with it.${NC}"
}

# Function to display the environment variables menu
display_env_menu() {
    clear
    
    # Calculate maximum width needed
    local max_width=70
    
    # Draw header
    draw_box $max_width "SuperPlex Setup (Step 2 of 3)"
    
    # Instructions
    echo -e "\n${BOLD}Environment Configuration${NC}"
    echo -e "${DIM}Configure the environment variables for your media server.${NC}\n"
    
    echo -e "${BOLD}Navigation:${NC}"
    echo -e "  ${YELLOW}↑/↓${NC}      Move selection"
    echo -e "  ${YELLOW}[Enter]${NC}  Edit selected variable"
    echo -e "  ${YELLOW}[S]${NC}      Save and continue"
    echo -e "  ${YELLOW}[Q]${NC}      Cancel setup\n"
    
    # Table header
    echo -e "  ${BOLD}Environment Variables:${NC}"
    echo -e "  ${BLUE}----------------------------------------${NC}"
    
    # Get all variable names and sort them
    local names=(${!env_vars[@]})
    IFS=$'\n' sorted=($(sort <<<"${names[*]}"))
    unset IFS
    
    # Display variables
    for i in "${!sorted[@]}"; do
        local var="${sorted[$i]}"
        local value="${!var}"  # Current value
        local default_value="${env_vars[$var]%%:*}"  # Get default value before colon
        local description="${env_vars[$var]#*:}"  # Get description after colon
        local prefix="  "
        
        if [ $i -eq $selected_env ]; then
            prefix=" >"
            echo -en "${REVERSE}"
        fi
        
        if [[ "$value" != "$default_value" ]]; then
            # Show modified value in a different color
            printf "${prefix} %-15s = ${YELLOW}%-20s${NC}" "$var" "$value"
        else
            printf "${prefix} %-15s = %-20s" "$var" "$value"
        fi
        
        if [ $i -eq $selected_env ]; then
            echo -en "${NC}"
        fi
        echo
    done
    
    echo -e "  ${BLUE}----------------------------------------${NC}"
    
    # Show current variable description
    local current_var="${sorted[$selected_env]}"
    local description="${env_vars[$current_var]#*:}"
    local default_value="${env_vars[$current_var]%%:*}"
    echo -e "\n${BOLD}Description:${NC}"
    echo "  $description"
    echo -e "${DIM}Default value: $default_value${NC}"
    
    # Show next steps
    echo -e "\n${DIM}Next steps: Storage setup${NC}"
}

# Function to edit environment variable
edit_env_var() {
    local var=$1
    local current_value="${!var}"
    local description="${env_vars[$var]#*:}"
    
    clear
    echo -e "${BOLD}Edit Environment Variable${NC}\n"
    echo -e "Variable: ${BLUE}$var${NC}"
    echo -e "Description: ${DIM}$description${NC}"
    echo -e "Current value: ${GREEN}$current_value${NC}\n"
    
    # Temporarily restore echo for input visibility
    stty echo
    echo -n "Enter new value (or press Enter to keep current): "
    read -r new_value
    stty -echo
    
    if [[ -n "$new_value" ]]; then
        eval "$var='$new_value'"
    fi
}

# Function to save environment variables
save_env_vars() {
    echo -e "\n${BOLD}${BLUE}Saving environment configuration...${NC}"
    
    # Create backup of existing .env
    if [[ -f .env ]]; then
        cp .env .env.backup
        echo -e "${DIM}Backup created: .env.backup${NC}"
    fi
    
    # Write new .env file
    {
        echo "# Generated by SuperPlex Setup"
        echo "# $(date)"
        echo
        for var in "${!env_vars[@]}"; do
            echo "$var=${!var}"
        done
    } > .env
    
    echo -e "\n${BOLD}${GREEN}Environment configuration saved to .env${NC}"
}

# Function to handle environment configuration
configure_environment() {
    while true; do
        display_env_menu
        
        read -r -s -n 1 key
        
        if [[ $key == $'\x1b' ]]; then
            read -r -s -n 2 arrow
            case $arrow in
                '[A') # Up arrow
                    ((selected_env--))
                    [ $selected_env -lt 0 ] && selected_env=$((total_env_vars - 1))
                    ;;
                '[B') # Down arrow
                    ((selected_env++))
                    [ $selected_env -ge $total_env_vars ] && selected_env=0
                    ;;
            esac
        elif [[ -z "$key" ]]; then
            # Enter key - edit current variable
            current_var=$(printf '%s\n' "${!env_vars[@]}" | sort | sed -n "$((selected_env+1))p")
            edit_env_var "$current_var"
        elif [[ $key == 's' ]] || [[ $key == 'S' ]]; then
            if save_env_vars; then
                return 0
            fi
        elif [[ $key == 'q' ]] || [[ $key == 'Q' ]]; then
            clear
            echo -e "${YELLOW}Exiting without saving...${NC}"
            exit 1
        fi
    done
}

# Setup terminal
setup_terminal

# Main loop
while true; do
    display_menu
    
    # Read a single character without echoing
    read -r -s -n 1 key
    
    # Debug output - print key code to a file
    printf "Key pressed (hex): %x\n" "'$key" >> /tmp/setup_debug.log
    
    # Handle special keys
    if [[ $key == $'\x1b' ]]; then
        echo "Escape sequence detected" >> /tmp/setup_debug.log
        # Read the next two characters for arrow keys
        read -r -s -n 2 arrow
        case $arrow in
            '[A') # Up arrow
                ((selected--))
                [ $selected -lt 0 ] && selected=$((total_services - 1))
                ;;
            '[B') # Down arrow
                ((selected++))
                [ $selected -ge $total_services ] && selected=0
                ;;
        esac
    elif [[ $key == ' ' ]]; then
        echo "Space key detected" >> /tmp/setup_debug.log
        # Toggle current service
        current_service=$(printf '%s\n' "${!services[@]}" | sort | sed -n "$((selected+1))p")
        services["$current_service"]=$((1 - services["$current_service"]))
    elif [[ -z "$key" ]]; then
        echo "Empty key (likely Enter) detected" >> /tmp/setup_debug.log
        if confirm_save; then
            clear
            generate_compose_file
            configure_environment
            exit 0
        fi
    elif [[ $key == 'q' ]] || [[ $key == 'Q' ]]; then
        echo "Quit key detected" >> /tmp/setup_debug.log
        clear
        echo -e "${YELLOW}Exiting without saving...${NC}"
        exit 1
    fi
done
