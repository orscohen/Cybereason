# Automating SFTP Downloads with Bash Scripts

This repository contains two Bash scripts for automating SFTP downloads:

* **FTP_LTI_Pass_plain.sh:** This script uses a plain-text password (**not recommended for security reasons**).
* **FTP_LTI_Pass_addon.sh:** This script leverages the `pass` password manager for enhanced security.

**Prerequisites:**

* `sshpass` (for `FTP_LTI_Pass_plain.sh`): `sudo apt install sshpass` (Debian/Ubuntu)
* `pass` (for `FTP_LTI_Pass_addon.sh`): `sudo apt install pass`

**1. FTP_LTI_Pass_plain.sh (Plain-text Password - Not Recommended)**

**a. Create the Script:**

1. Create a new file named `FTP_LTI_Pass_plain.sh`.
2. Paste the following code into the file (replace placeholders with your actual values):

```bash
#!/bin/bash

SFTP_HOST="your_sftp_host"
SFTP_USER="your_sftp_user"
SFTP_PASSWORD="your_sftp_password"  # **Security Recommendation:** Avoid storing passwords in plain text
REMOTE_DIR="/LTI updates"
LOCAL_DIR="/home/cor-unix/test"
DEBUG=1

# ... rest of the script ...
