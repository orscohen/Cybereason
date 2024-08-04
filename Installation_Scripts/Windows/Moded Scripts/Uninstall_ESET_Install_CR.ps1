# Set execution policy
Set-ExecutionPolicy Bypass -Scope Process -Force

# Define variables
$password = "**************"
$cr = 'Cybereason ActiveProbe'
$logFile = "C:\windows\Temp\CybereasonInstall.log"

# Function to uninstall software
function Uninstall-Software {
    param (
        [string]$softwareName
    )
    $uninstallString = gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | 
                       foreach { gp $_.PSPath } | 
                       ? { $_ -match $softwareName } | 
                       select UninstallString

    if ($uninstallString) {
        $uninstallCommand = $uninstallString.UninstallString -Replace "msiexec.exe", "" -Replace "/I", "" -Replace "/X", ""
        $uninstallCommand = $uninstallCommand.Trim()
        Write-Output "Uninstalling $softwareName..."
        start-process "msiexec.exe" -ArgumentList "/X $uninstallCommand /norestart /qn password=$password" -Wait
    }
}

# Uninstall ESET Endpoint Antivirus and ESET Management Agent
Uninstall-Software -softwareName "ESET Endpoint Antivirus"
Uninstall-Software -softwareName "ESET Management Agent"

# Enable firewall profiles
Set-NetFirewallProfile -Profile * -Enabled True

# Verification of deletion
Write-Host "Deletion verification process ..."
$installedProducts = Get-WmiObject -Class Win32_Product | Select-Object -Property Name

if ($installedProducts -contains "ESET Management Agent" -or $installedProducts -contains "ESET Endpoint Antivirus") {
    Write-Host "ESET products are still installed" -BackgroundColor Black -ForegroundColor Green
} else {
    # Check for Cybereason Installation
    $installCr = Get-WmiObject -Class Win32_Product -Filter "Name='$cr'" | Where-Object { $_.Name -eq $cr }
    if (-Not $installCr) {
        # Install Cybereason
        Write-Output "Installing Cybereason..."
        \\remote-server\CybereasonSensor64.cybereason.net.exe /quiet /norestart -l $logFile 
    }
}
