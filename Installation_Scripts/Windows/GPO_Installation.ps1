# Cybereason ActiveProbe Installation Script
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

# Define network share and local installation paths
$SensorShare = '\\ShareServer\Software\SoftwareRepo\CybereasonActiveProbe\CybereasonActiveProbe.exe'
$SensorLocal = 'C:\Windows\Temp\CybereasonActiveProbe.exe'
$TempDir = 'C:\Windows\Temp\CybereasonActiveProbe'

# Logging Function
function Write-InstallLog {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] $Message"
    
    Write-Host $LogEntry -ForegroundColor $Color
    Add-Content -Path "C:\Windows\Temp\CybereasonInstall.log" -Value $LogEntry
}

# Pre-Installation Checks
try {
    # Create Temporary Directory
    if (-Not (Test-Path -Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        Write-InstallLog -Message "Created temporary directory: $TempDir" -Color Cyan
    }

    # Validate Network Share
    if (-Not (Test-Path -Path $SensorShare)) {
        Write-InstallLog -Message "ERROR: Sensor share not found: $SensorShare" -Color Red
        exit 1
    }

    # Copy Installer
    Copy-Item -Path $SensorShare -Destination $SensorLocal -Force
    Write-InstallLog -Message "Copied installer to: $SensorLocal" -Color Green

    # Define Installation Parameters
    $ProductName = 'Cybereason ActiveProbe'

    # Check Existing Installation
    $ExistingInstall = Get-WmiObject -Class Win32_Product | 
        Where-Object { $_.Name -eq $ProductName }

    # Perform Installation
    if (-Not $ExistingInstall) {
        Write-InstallLog -Message "Cybereason ActiveProbe not detected. Starting installation..." -Color Yellow
        
        # Silent Installation
        Start-Process -FilePath $SensorLocal -ArgumentList @('/install', '/quiet', '/norestart') -Wait
        
        # Verify Installation
        $VerifyInstall = Get-WmiObject -Class Win32_Product | 
            Where-Object { $_.Name -eq $ProductName }
        
        if ($VerifyInstall) {
            Write-InstallLog -Message "Cybereason ActiveProbe installed successfully" -Color Green
        } else {
            Write-InstallLog -Message "Installation verification failed" -Color Red
            exit 1
        }
    } else {
        Write-InstallLog -Message "Cybereason ActiveProbe is already installed" -Color Green
    }

    # Optional: Clean up installer
    Remove-Item -Path $SensorLocal -Force -ErrorAction SilentlyContinue
}
catch {
    Write-InstallLog -Message "ERROR: $($_.Exception.Message)" -Color Red
    exit 1
}
