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
# List the gpg keys to verify
```bash

3. List keys to verify

gpg --list-keys
```

4. Store SFTP Credentials:
```bash
pass insert sftp/host
pass insert sftp/user
pass insert sftp/password
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
0 9 * * 1 /path/to/FTP_LTI_Pass_plain.sh

# Or for pass manager script
0 9 * * 1 /path/to/FTP_LTI_Pass_Secured.sh
```

### Cron Syntax Breakdown
- `0` = Minute (0-59)
- `9` = Hour (0-23)
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

## Best Practices
- Avoid storing passwords in plain text
- Implement proper access controls
- Regularly rotate credentials

## Troubleshooting
- Verify all paths are correct
- Check network connectivity
- Validate SFTP server credentials
- Ensure script permissions are set correctly
