#!/bin/bash

#Get the REMOTE_DIR folder name , User & Password and IP from the TAM/SE
#At the end of the script you will get $latest_json file , which can be used as you wish

# Configuration
SFTP_HOST=$(pass sftp/host)  # Added host retrieval from pass
REMOTE_DIR="/Insert here the LTI FTP folder " #LTI Folder name
LOCAL_DIR="/home/insered here the local folder/test" # Local folder
DEBUG=0 #If need to debug - put debug = 1




# Logging function
log() {
  if [[ $DEBUG -eq 1 ]]; then
    echo "[DEBUG] $1"
  fi
}

# Function to get credentials from pass
get_credentials() {
  SFTP_USER=$(pass sftp/user)
  SFTP_PASSWORD=$(pass sftp/password)
}

# Main script execution
main() {
  # Check if pass is installed
  if ! command -v pass >/dev/null 2>&1; then
    echo "Error: pass is not installed. Install with: sudo apt-get install pass"
    exit 1
  fi

  # Get credentials
  get_credentials

  # Ensure credentials and host are not empty
  if [[ -z "$SFTP_HOST" || -z "$SFTP_USER" || -z "$SFTP_PASSWORD" ]]; then
    echo "Error: Credentials or host not found in pass"
    exit 1
  fi

  # Rest of the script remains the same as previous version
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
      echo "No JSON file found in downloaded folder"
    fi
  else
    echo "Failed to download folder $latest_folder"
    exit 1
  fi
}

# Run the main function
main
