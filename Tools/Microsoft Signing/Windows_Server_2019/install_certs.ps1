####use powershell.exe -ExecutionPolicy Bypass
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
# PowerShell Script to Install Certificates to Trusted Root

# Prompt the user to enter the folder path containing the certificates
$certFolderPath = Read-Host -Prompt "Enter the folder path where the certificates are located"

# Check if the folder path exists
if (-Not (Test-Path -Path $certFolderPath)) {
    Write-Host "The specified folder path does not exist. Please check the path and try again." -ForegroundColor Red
    exit
}

# Define certificate file names
$certFiles = @(
    "GeoTrustRSACA2018.cer",
    "Microsoft Identity Verification Root Certificate Authority 2020.crt",
    "DigiCertGlobalRootCA.cer"
)

# Iterate through each certificate file and install it
foreach ($certFile in $certFiles) {
    $certPath = Join-Path -Path $certFolderPath -ChildPath $certFile
    
    # Check if the certificate file exists
    if (-Not (Test-Path -Path $certPath)) {
        Write-Host "Certificate file '$certFile' not found in the specified folder. Skipping..." -ForegroundColor Yellow
        continue
    }
    
    # Install the certificate
    try {
        certutil -addstore "Root" $certPath
        Write-Host "Successfully installed certificate: $certFile" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install certificate: $certFile. Error: $_" -ForegroundColor Red
    }
}

Write-Host "Certificate installation process completed." -ForegroundColor Cyan
