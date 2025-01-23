# SFTP Download Automation Scripts

## Overview
This repository contains two Bash scripts for automating SFTP downloads with different authentication methods.

## Prerequisites

### System Requirements
- Linux (Debian/Ubuntu recommended)
- Bash shell

### Package Dependencies
- `sshpass` (for plain password script)
- `pass` (for secure password management script)

### Installation
```bash
sudo apt update
sudo apt install sshpass pass
```

## 1. Plain Password Script: `FTP_LTI_Pass_plain.sh`

### ⚠️ Security Warning
**Not Recommended for Production Use** - Storing passwords in plain text is a significant security risk.

### Script Configuration
1. Create the script:
```bash
vi FTP_LTI_Pass_plain.sh
chmod +x FTP_LTI_Pass_plain.sh
```

2. Configure script variables:
```bash
#!/bin/bash

# SFTP Server Configuration
SFTP_HOST="sftp.example.com"        # SFTP server hostname
SFTP_USER="your_username"            # SFTP login username
SFTP_PASSWORD="your_password"        # SFTP login password

# Directory Paths
REMOTE_DIR="/path/to/remote/directory"  # Remote directory to download from
LOCAL_DIR="/path/to/local/directory"    # Local destination directory

# Debug Mode (1 for verbose, 0 for quiet)
DEBUG=1
```

### Execution
```bash
./FTP_LTI_Pass_plain.sh
```

## 2. Secure Password Manager Script: `FTP_LTI_Pass_addon.sh`

### Password Manager Setup

1. Generate GPG Key (if not already done):
```bash
gpg --full-generate-key
```

2. Initialize Password Store:
```bash
# Use the email from your GPG key
pass init your_gpg_email@example.com
```

3. Store SFTP Credentials:
```bash
pass insert sftp/host
pass insert sftp/user
pass insert sftp/password
```

### Script Configuration
Create the script:
```bash
vi FTP_LTI_Pass_addon.sh
chmod +x FTP_LTI_Pass_addon.sh
```


### Execution
```bash
./FTP_LTI_Pass_addon.sh
```

## Best Practices
- Avoid storing passwords in plain text
- Implement proper access controls
- Regularly rotate credentials

## Troubleshooting
- Verify all paths are correct
- Check network connectivity
- Validate SFTP server credentials
- Ensure script permissions are set correctly
