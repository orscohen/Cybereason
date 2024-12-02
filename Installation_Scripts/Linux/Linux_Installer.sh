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

# Define the path to the Cybereason sensor installer file (RPM or DEB)
INSTALLER_FILE="/path/to/your/installer/file.rpm"  # Replace with the actual path

# Function to install Cybereason sensor on RPM-based systems
install_rpm() {
  echo "Installing Cybereason Sensor (RPM-based system)..."
  sudo rpm -ivh $1
}

# Function to install Cybereason sensor on DEB-based systems (including Ubuntu)
install_deb() {
  echo "Installing Cybereason Sensor (Ubuntu)..."
  sudo dpkg -i $1
}

# Function to verify Cybereason sensor status
verify_sensor() {
  echo "Verifying Cybereason Sensor status..."

  if [[ -f "/etc/os-release" ]]; then
    . /etc/os-release
  fi

  # Check if the system is Ubuntu
  if [[ $ID == "ubuntu" ]]; then
    # For Ubuntu 16 LTS and newer
    systemctl status cybereason-sensor
  fi

  # Check if the system is CentOS, RHEL, or Oracle Linux (RPM-based)
  if [[ $ID == "centos" || $ID == "rhel" || $ID == "oracle" || $ID == "amzn" ]]; then
    # CentOS 7+, RHEL 7+, Oracle Linux 7+, Amazon Linux, Ubuntu 16 LTS+
    if [[ "$VERSION_ID" == "7" || "$VERSION_ID" == "8" || "$ID" == "amzn" || "$VERSION_ID" == "16" ]]; then
      systemctl status cybereason-sensor
    else
      # CentOS 6/RHEL 6/Oracle Linux 6
      initctl status cybereason-sensor
    fi
  fi
}

# Main installation process
echo "Starting Cybereason Sensor installation..."

# Determine the package type (RPM or DEB)
if [[ $INSTALLER_FILE == *.rpm ]]; then
  install_rpm $INSTALLER_FILE
elif [[ $INSTALLER_FILE == *.deb ]]; then
  install_deb $INSTALLER_FILE
else
  echo "Invalid file type. Please provide an RPM or DEB file."
  exit 1
fi

# Verify the sensor status
verify_sensor
