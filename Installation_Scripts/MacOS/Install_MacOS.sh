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

# Set the path to the .pkg file and the required directory for installation
PACKAGE_PATH="/path/to/your/CybereasonInstall.pkg"
LOG_FILE="/var/log/cybereason_install.log"

# Ensure the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root (use sudo)" | tee -a "$LOG_FILE"
    exit 1
fi

# Check if the package file exists
if [ ! -f "$PACKAGE_PATH" ]; then
    echo "The specified package file does not exist: $PACKAGE_PATH" | tee -a "$LOG_FILE"
    exit 1
fi

# Step 1: Install the Cybereason sensor
echo "Installing Cybereason sensor..." | tee -a "$LOG_FILE"
sudo installer -pkg "$PACKAGE_PATH" -target / >> "$LOG_FILE" 2>&1

# Step 2: Verify the sensor is running
echo "Verifying Cybereason sensor is running..." | tee -a "$LOG_FILE"
if ps -ax | grep -q 'CybereasonSensor$'; then
    echo "Cybereason sensor is running" | tee -a "$LOG_FILE"
else
    echo "Cybereason sensor is not running" | tee -a "$LOG_FILE"
fi

# Step 3: Final confirmation
echo "Cybereason sensor installation completed. Please check the sensor's status in the Cybereason platform." | tee -a "$LOG_FILE"
