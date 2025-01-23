#!/bin/bash

#Install sshpass | sudo apt-get install sshpass | sudo yum install sshpass
#Get the "folder name, User & Password, and IP from the TAM/SE
#Configure them inside the script
# Constants
SFTP_HOST=""
SFTP_USER=""
SFTP_PASSWORD=""
REMOTE_DIR="/LTI folder here/"
LOCAL_DIR="/home/Local folder here"
DEBUG=0 # Set to 1 for debug output

# Logging function
log() {
    if [[ $DEBUG -eq 1 ]]; then
        echo "[DEBUG] $1"
    fi
}

# Main script execution
main() {
    # Ensure required tools are installed
    if ! command -v sshpass >/dev/null 2>&1; then
        echo "Error: sshpass is not installed. Install with: sudo apt-get install sshpass"
        exit 1
    fi

    # Create local directory if it doesn't exist
    mkdir -p "$LOCAL_DIR"

    # Find the latest date-formatted folder
    latest_folder=$(sshpass -p "$SFTP_PASSWORD" sftp -q -o StrictHostKeyChecking=no "$SFTP_USER@$SFTP_HOST" << EOF | awk '$1 ~ /^d/ && $9 ~ /^[0-9]{2}-[0-9]{2}-[0-9]{4}$/ {print $9}' | sort -t'-' -k3,3nr -k2,2nr -k1,1nr | head -n1
        ls -l "$REMOTE_DIR"
EOF
    )

    if [[ -z "$latest_folder" ]]; then
        echo "No date-formatted folders found in the remote directory $REMOTE_DIR"
        exit 1
    fi

    log "Latest date-formatted folder detected: $latest_folder"

    # Download entire folder recursively
    sshpass -p "$SFTP_PASSWORD" sftp -r -q -o StrictHostKeyChecking=no "$SFTP_USER@$SFTP_HOST" << EOF
        get -r "$REMOTE_DIR/$latest_folder" "$LOCAL_DIR/"
EOF

    # Check if download was successful
    if [[ $? -eq 0 ]]; then
        echo "Successfully downloaded folder $latest_folder to $LOCAL_DIR"

        # Find and create alias for JSON file
        json_file=$(find "$LOCAL_DIR/$latest_folder" -name "*.json" | head -n1)
        if [[ -n "$json_file" ]]; then
            json_filename=$(basename "$json_file")
            alias_name="latest_json"
            echo "alias $alias_name='cat $json_file'" >> ~/.bashrc
            echo "Created alias '$alias_name' for $json_filename"
            source ~/.bashrc
        else
            echo "No JSON file found in the downloaded folder"
        fi
    else
        echo "Failed to download folder $latest_folder"
        exit 1
    fi
}

# Run the main function
main
