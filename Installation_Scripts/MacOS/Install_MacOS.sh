#!/bin/bash
#************************************************	
#| Script Configuration:                        |
#| -------------------------------------------  |
#|                                              |
#   ___          ___      _                     |
#  /___\_ __    / __\___ | |__   ___ _ __       |
# //  // '__|  / /  / _ \| '_ \ / _ \ '_ \      |
#/ \_//| |    / /__| (_) | | | |  __/ | | |     |
#\___/ |_|    \____/\___/|_| |_|\___|_| |_|     |
#***********************************************

##Please review "Deploy and Distribute Cybereason Sensors using JAMF MDM"|| https://nest.cybereason.com/knowledgebase/7745196
## MDM mobileconfig file: https://nest.cybereason.com/system/files/resource-documents/2023-03/Cybereason_Sensor_Policy%20%283%29.mobileconfig
##Make sure the MDM mobile config profile is deployed before the Script deployment.


# Configuration Variables
PACKAGE_PATH="/path/to/your/CybereasonInstall.pkg"
LOG_FILE="/var/log/cybereason_install.log"
SENSOR_PROCESS_NAME="CybereasonSensor"

# Logging Function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "INFO")
            echo "[INFO] $timestamp - $message" | tee -a "$LOG_FILE"
            ;;
        "WARN")
            echo "[WARN] $timestamp - $message" | tee -a "$LOG_FILE" >&2
            ;;
        "ERROR")
            echo "[ERROR] $timestamp - $message" | tee -a "$LOG_FILE" >&2
            ;;
        "SUCCESS")
            echo "[SUCCESS] $timestamp - $message" | tee -a "$LOG_FILE"
            ;;
    esac
}

# Pre-Installation Checks
pre_installation_checks() {
    # Check macOS version compatibility
    macos_version=$(sw_vers -productVersion)
    log "INFO" "Detected macOS version: $macos_version"
    
    # Perform version-specific compatibility checks if needed
    # Example: if [[ $(echo "$macos_version < 10.15" | bc) -eq 1 ]]; then
    #    log "ERROR" "Unsupported macOS version. Minimum version required: 10.15"
    #    exit 1
    # fi
    
    # Check available disk space
    available_space=$(df -h / | awk '/\// {print $4}')
    log "INFO" "Available disk space: $available_space"
    
    # Basic system requirements check
    if ! command -v installer &> /dev/null; then
        log "ERROR" "macOS installer utility not found"
        exit 1
    fi
}

# Root Privilege Check
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "ERROR" "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Package Validation
validate_package() {
    if [ ! -f "$PACKAGE_PATH" ]; then
        log "ERROR" "The specified package file does not exist: $PACKAGE_PATH"
        exit 1
    fi
    
    # Optional: Add checksum verification
    # Example: 
    # expected_checksum="your_expected_checksum"
    # actual_checksum=$(shasum -a 256 "$PACKAGE_PATH" | awk '{print $1}')
    # if [[ "$actual_checksum" != "$expected_checksum" ]]; then
    #     log "ERROR" "Package checksum verification failed"
    #     exit 1
    # fi
}

# Install Cybereason Sensor
install_sensor() {
    log "INFO" "Starting Cybereason sensor installation..."
    
    # Attempt installation
    installer -pkg "$PACKAGE_PATH" -target / >> "$LOG_FILE" 2>&1
    
    # Check installation status
    if [ $? -eq 0 ]; then
        log "SUCCESS" "Cybereason sensor package installed successfully"
    else
        log "ERROR" "Cybereason sensor installation failed"
        exit 1
    fi
}

# Verify Sensor Status
verify_sensor() {
    # Wait a few seconds for sensor to start
    sleep 5
    
    # Check if sensor process is running
    if pgrep -x "$SENSOR_PROCESS_NAME" > /dev/null; then
        log "SUCCESS" "Cybereason sensor is running"
    else
        log "WARN" "Cybereason sensor is not running"
        
        # Additional diagnostics
        log "INFO" "Checking system logs for potential issues..."
        log "INFO" "$(system_profiler SPInstallHistoryDataType | grep -A 5 "Cybereason")"
    }
    
    # Optional: Additional sensor verification steps
    # For example, check sensor configuration or connection status
}

# Cleanup Function
cleanup() {
    # Optional cleanup tasks
    log "INFO" "Cleaning up installation artifacts..."
    # Add any necessary cleanup commands
}

# Main Installation Process
main() {
    # Redirect all output to log file
    exec > >(tee -a "$LOG_FILE") 2>&1
    
    check_root
    pre_installation_checks
    validate_package
    install_sensor
    verify_sensor
    cleanup
    
    log "SUCCESS" "Cybereason sensor installation and verification completed"
}

# Trap exit signals to ensure cleanup
trap cleanup EXIT

# Execute main installation process
main
