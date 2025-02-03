# Cybereason Sensor Multi-Architecture Installation Script
#************************************************	
#| Script Configuration:                        |
#| -------------------------------------------  |
#|                                              |
#   ___          ___      _                     |
#  /___\_ **    / **\___ | |__   ___ *_*       |
# //  // '__|  / /  / * \| '* \ / * \ '* \      |
#/ \_//| |    / /__| (_) | | | |  __/ | | |     |
#\___/ |_|    \____/\___/|_| |_|\___|_| |_|     |
#***********************************************

# Configuration Variables
$S3Url64 = "https://your-bucket-url/CybereasonSensor64.cybereason.net.exe"  #add your url here
$LogPath = "C:\Windows\Temp\CybereasonInstall.log"
$TempDownloadPath = "C:\Windows\Temp\CybereasonInstaller.exe"

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

# Download Installer from S3
function Get-InstallerFromS3 {
    param(
        [string]$DownloadUrl,
        [string]$InstallerName
    )
    
    try {
        # Create temp directory if it doesn't exist
        if (-not (Test-Path $TempDownloadPath)) {
            New-Item -ItemType Directory -Path $TempDownloadPath -Force | Out-Null
        }
        
        $LocalPath = Join-Path $TempDownloadPath $InstallerName
        
        Write-Log "Downloading $InstallerName..."
        
        # Create WebClient object with TLS 1.2 support
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $WebClient = New-Object System.Net.WebClient
        
        # Download the file
        $WebClient.DownloadFile($DownloadUrl, $LocalPath)
        
        Write-Log "Successfully downloaded installer to $LocalPath"
        return $LocalPath
    }
    catch {
        Write-Log "ERROR: Failed to download installer - $($_.Exception.Message)"
        throw
    }
}

# Perform Installation
function Install-CybereasonSensor {
    $InstallerName = "CybereasonSensor64.cybereason.net.exe"
    $DownloadUrl = $S3Url64
    
    try {
        # Download Installer
        $InstallerPath = Get-InstallerFromS3 -DownloadUrl $DownloadUrl -InstallerName $InstallerName
        
        # Validate Installer Exists
        if (-not (Test-Path $InstallerPath)) {
            Write-Log "ERROR: Downloaded installer not found at $InstallerPath"
            return $false
        }
        
        # Prepare Installation Command
        $InstallArgs = @(
            "/quiet",
            "/norestart",
            "-l", $LogPath
        )
        
        # Execute Installer
        Start-Process -FilePath $InstallerPath -ArgumentList $InstallArgs -Wait -PassThru
        
        # Cleanup downloaded installer
        Remove-Item -Path $InstallerPath -Force
        
        Write-Log "Cybereason Sensor installed successfully"
        return $true
    }
    catch {
        Write-Log "ERROR: Installation failed - $($_.Exception.Message)"
        return $false
    }
    finally {
        # Cleanup temp directory if empty
        if ((Get-ChildItem $TempDownloadPath -Force | Measure-Object).Count -eq 0) {
            Remove-Item -Path $TempDownloadPath -Force
        }
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
