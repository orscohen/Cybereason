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
##chmod +x Linux_Installer.sh
###./Linux_Installer.sh

# Define the path to the Cybereason sensor installer file
INSTALLER_FILE="/path/to/your/installer/file.rpm"  # Replace with the actual path


# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    case "$level" in
        "INFO")
            echo "[INFO] $timestamp - $message"
            ;;
        "WARN")
            echo "[WARN] $timestamp - $message" >&2
            ;;
        "ERROR")
            echo "[ERROR] $timestamp - $message" >&2
            ;;
        "SUCCESS")
            echo "[SUCCESS] $timestamp - $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Check if script is run with root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log "ERROR" "This script must be run as root. Use sudo ./Linux_Installer.sh"
        exit 1
    fi
}

# Detect Linux distribution
detect_distribution() {
    if [[ -f "/etc/os-release" ]]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    elif [[ -f "/etc/redhat-release" ]]; then
        DISTRO=$(cat /etc/redhat-release | awk '{print tolower($1)}')
        DISTRO_VERSION=$(cat /etc/redhat-release | awk '{print $3}')
    else
        log "ERROR" "Unsupported Linux distribution"
        exit 1
    fi
    log "INFO" "Detected Distribution: $DISTRO $DISTRO_VERSION"
}

# Check and install required dependencies
check_dependencies() {
    local required_libs=(
        "linux-vdso.so.1"
        "libnsl.so.1"
        "librt.so.1"
        "libpthread.so.0"
        "libm.so.6"
        "libgcc_s.so.1"
        "libc.so.6"
        "ld-linux-x86-64.so.2"
        "libdl.so.2"
        "libpopt.so.0"
        "libelf.so.1"
        "libattr.so.1"
        "libz.so.1"
    )
    
    local optional_libs=(
        "libcap.so.2"
        "librpm.so"
        "librpmio.so"
        "gdb"
    )
    
    local missing_required=()
    local missing_optional=()
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        log "WARN" "Python 3 not found. Attempting to install."
        if [[ $DISTRO == "ubuntu" || $DISTRO == "debian" ]]; then
            apt-get update && apt-get install -y python3
        elif [[ $DISTRO == "centos" || $DISTRO == "rhel" || $DISTRO == "oracle" || $DISTRO == "fedora" ]]; then
            yum install -y python3
        fi
    fi
    
    # Check required libraries
    for lib in "${required_libs[@]}"; do
        if ! ldconfig -p | grep -q "$lib"; then
            missing_required+=("$lib")
        fi
    done
    
    # Check optional libraries
    for lib in "${optional_libs[@]}"; do
        if ! ldconfig -p | grep -q "$lib" && ! command -v "$lib" &> /dev/null; then
            missing_optional+=("$lib")
        fi
    done
    
    # Check network configuration tools
    if ! command -v iptables &> /dev/null && ! command -v nftables &> /dev/null; then
        missing_required+=("iptables/nftables")
    fi
    
    # Report missing libraries
    if [[ ${#missing_required[@]} -ne 0 ]]; then
        log "ERROR" "Missing required libraries/dependencies:"
        printf '%s\n' "${missing_required[@]}"
        
        # Attempt to install missing dependencies
        if [[ $DISTRO == "ubuntu" || $DISTRO == "debian" ]]; then
            apt-get update
            apt-get install -y $(printf 'lib%s ' "${missing_required[@]}")
        elif [[ $DISTRO == "centos" || $DISTRO == "rhel" || $DISTRO == "oracle" || $DISTRO == "fedora" ]]; then
            yum install -y $(printf 'lib%s ' "${missing_required[@]}")
        fi
    fi
    
    # Report optional libraries
    if [[ ${#missing_optional[@]} -ne 0 ]]; then
        log "WARN" "Missing optional libraries/dependencies:"
        printf '%s\n' "${missing_optional[@]}"
    fi
}


# Function to install Cybereason sensor on RPM-based systems
install_rpm() {
    log "INFO" "Installing Cybereason Sensor (RPM-based system)..."
    sudo rpm -ivh "$1" || {
        log "ERROR" "RPM installation failed"
        exit 1
    }
}

# Function to install Cybereason sensor on DEB-based systems (including Ubuntu)
install_deb() {
    log "INFO" "Installing Cybereason Sensor (Ubuntu)..."
    sudo dpkg -i "$1" || {
        log "ERROR" "DEB installation failed"
        exit 1
    }
}

# Function to verify Cybereason sensor status
verify_sensor() {
    log "INFO" "Verifying Cybereason Sensor status..."
    
    # Determine service management based on distribution and version
    if [[ $DISTRO == "ubuntu" ]]; then
        systemctl status cybereason-sensor
    elif [[ $DISTRO == "centos" || $DISTRO == "rhel" || $DISTRO == "oracle" || $DISTRO == "amzn" ]]; then
        if [[ "$DISTRO_VERSION" == "7" || "$DISTRO_VERSION" == "8" ]]; then
            systemctl status cybereason-sensor
        else
            initctl status cybereason-sensor
        fi
    fi
}

# Main installation process
main() {
    check_root
    detect_distribution
    check_dependencies
    
    # Determine the package type (RPM or DEB)
    if [[ $INSTALLER_FILE == *.rpm ]]; then
        install_rpm "$INSTALLER_FILE"
    elif [[ $INSTALLER_FILE == *.deb ]]; then
        install_deb "$INSTALLER_FILE"
    else
        log "ERROR" "Invalid file type. Please provide an RPM or DEB file."
        exit 1
    fi
    
    # Verify the sensor status
    verify_sensor
    
    log "SUCCESS" "Cybereason Sensor installation completed successfully"
}

# Run the main installation process
main
