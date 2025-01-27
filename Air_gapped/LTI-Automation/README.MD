# LTI Weekly Download Automation Scripts

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

## 2. Secure Password Manager Script: `FTP_LTI_Pass_Secured.sh`

### Password Manager Setup
## Non-Interactive GPG Key for Automation

### Creating a Non-Interactive GPG Key

```bash
# Generate non-interactive GPG key
gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Automation User
Name-Email: automation@example.com
Expire-Date: 0
%no-protection
%commit
EOF
```
3.List the gpg keys to verify

```bash
#List keys to verify
gpg --list-keys
```

4. Store SFTP Credentials:
```bash
# Insert SFTP host details
pass insert sftp/host <<< "sftp.example.com"

# Insert SFTP username
pass insert sftp/user <<< "your_username"

# Insert SFTP password
pass insert sftp/password <<< "your_secure_password"
```

### Script Configuration
Create the script:
```bash
vi FTP_LTI_Pass_Secured.sh
chmod +x FTP_LTI_Pass_Secured.sh
```


### Execution
```bash
./FTP_LTI_Pass_Secured.sh
```

## Cron Job Configuration

### Weekly Monday Schedule at 9 AM

```bash
# Open crontab editor
crontab -e

# Add this line for plain password script
0 10 * * 1 /path/to/FTP_LTI_Pass_plain.sh

# Or for pass manager script
0 10 * * 1 /path/to/FTP_LTI_Pass_Secured.sh
```

### Cron Syntax Breakdown
- `0` = Minute (0-59)
- `10` = Hour (0-23)
- `*` = Day of month (1-31)
- `*` = Month (1-12)
- `1` = Day of week (0-7, where 1 = Monday)

### Verification
```bash
# List current scheduled jobs
crontab -l
```

### Recommended Logging
```bash
0 9 * * 1 /path/to/script.sh >> /var/log/sftp_download.log 2>&1
```
### Rsyslog integration
```bash
# Add to /etc/rsyslog.d/sftp-script.conf
local0.* /var/log/sftp_downloads.log

## Restart rsyslog
sudo systemctl restart rsyslog
```
## Viewing Logs
```bash
# View script-specific logs
sudo journalctl -t FTP_LTI_Pass_Secured.sh

## View detailed system logs
sudo grep local0 /var/log/syslog
```


## Best Practices
- Avoid storing passwords in plain text
- Implement proper access controls
- Regularly rotate credentials

## Troubleshooting
- Use Debug mode to identify the issue:
```bash
# Debug Mode (1 for verbose, 0 for quiet) 
# Change DEBUG=0 to:
DEBUG=1
```
- Verify all paths are correct
- Check network connectivity
- Validate SFTP server credentials
- Ensure script permissions are set correctly
