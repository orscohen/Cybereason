#!/bin/bash

# Define the log file path
LOG_FILE="/tmp/cybereason_check_$(date +'%Y%m%d_%H%M%S').log"

# Function to log messages with timestamp
log_message() {
    local message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
}

# Function to check if the Cybereason sensor is running
check_sensor_running() {
    log_message "Checking if Cybereason sensor is running..."
    if ps -ax | grep -q '[C]ybereasonSensor'; then
        log_message "Cybereason sensor is running."
    else
        log_message "Cybereason sensor is not running."
        exit 1
    fi
}

# Function to verify sensor logs
check_sensor_logs() {
    log_message "Checking Cybereason sensor logs..."

    # Define the log file path
    LOCAL_LOG_FILE="/usr/local/cybereason/logs/CrAv.log"

    # Check if the log file exists
    if [ ! -f "$LOCAL_LOG_FILE" ]; then
        log_message "Log file does not exist at $LOCAL_LOG_FILE."
        exit 1
    fi

    # Define patterns to look for in the log file with regex for variable numbers
    patterns=(
        "Full disk access failed! Need to grant full disk access"
        "Retrying [0-9]+ out of [0-9]+, sleeping for [0-9]+ minutes"
        "Full disk access permissions are ok"
        "OS permissions are ok"
    )

    # Search for patterns in the log file
    for pattern in "${patterns[@]}"; do
        if grep -E -q "$pattern" "$LOCAL_LOG_FILE"; then
            log_message "Found log entry matching: $pattern"
        else
            log_message "Log entry not found for pattern: $pattern"
        fi
    done
}

# Execute the functions
check_sensor_running
check_sensor_logs
