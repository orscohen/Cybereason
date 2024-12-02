# Cybereason Sensor Multi-Architecture Installation Script
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
# Configuration Variables
$ServerShare = "\\servername\sharename"
$LogPath = "C:\Windows\Temp\CybereasonInstall.log"
$OrganizationName = "TEST"  #Not Mandatory  

# Logging Function
function Write-Log {
    param(
        [string]$Message,
        [string]$LogFile = $LogPath
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] $Message"
    
    Add-Content -Path $LogFile -Value $LogEntry
    Write-Host $LogEntry
}

# Check Installation Status
function Test-CybereasonInstalled {
    $Paths = @(
        "C:\Program Files\Cybereason ActiveProbe",
        "C:\Program Files (x86)\Cybereason ActiveProbe"
    )
    
    foreach ($Path in $Paths) {
        if (Test-Path $Path) {
            Write-Log "Cybereason ActiveProbe already installed at $Path"
            return $true
        }
    }
    return $false
}

# Determine System Architecture
function Get-SystemArchitecture {
    if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
        return "64-bit"
    }
    return "32-bit"
}

# Perform Installation
function Install-CybereasonSensor {
    $Architecture = Get-SystemArchitecture
    
    # Determine Installer Path
    $InstallerName = if ($Architecture -eq "64-bit") {
        "CybereasonSensor64.cybereason.net.exe"
    } else {
        "CybereasonSensor32.cybereason.net.exe"
    }
    
    $InstallerPath = Join-Path $ServerShare $InstallerName
    $ResultFile = "C:\Windows\Temp\CybereasonSensor$($Architecture -replace '-').txt"
    
    # Validate Installer Exists
    if (-not (Test-Path $InstallerPath)) {
        Write-Log "ERROR: Installer not found at $InstallerPath"
        return $false
    }
    
    # Prepare Installation Command
    $InstallArgs = @(
        "/quiet",
        "/norestart",
        "-l", $LogPath,
        "AP_ORGANIZATION=$OrganizationName$($Architecture -replace '-')"
    )
    
    try {
        # Execute Installer
        Start-Process -FilePath $InstallerPath -ArgumentList $InstallArgs -Wait -PassThru
        
        # Create Result File
        "CybereasonSensor installed - $Architecture" | Out-File $ResultFile
        
        Write-Log "Cybereason Sensor installed successfully - $Architecture"
        return $true
    }
    catch {
        Write-Log "ERROR: Installation failed - $($_.Exception.Message)"
        return $false
    }
}

# Main Execution
try {
    # Check if already installed
    if (Test-CybereasonInstalled) {
        Write-Log "Exiting - Cybereason ActiveProbe already installed"
        exit 0
    }
    
    # Perform Installation
    $InstallResult = Install-CybereasonSensor
    
    # Set Exit Code
    if ($InstallResult) {
        exit 0
    }
    else {
        exit 1
    }
}
catch {
    Write-Log "CRITICAL ERROR: $($_.Exception.Message)"
    exit 1
}
