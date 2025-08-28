#requires -RunAsAdministrator
<#
.SYNOPSIS
    Downloads and installs certificates and Windows updates
.DESCRIPTION
    This script downloads and installs trusted root certificates, then checks for 
    and installs specified Windows updates. It verifies admin permissions, validates 
    URLs, includes error handling, and provides detailed progress feedback.
.NOTES
    Requires: PowerShell 5.1+, Administrator privileges, Internet connectivity
#>

####use powershell.exe -ExecutionPolicy Bypass
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
# PowerShell Script to Download and Install Certificates & Windows Updates

# Verify script is running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges. Please restart as administrator." -ForegroundColor Red
    exit 1
}

Write-Host "====== Certificate & Windows Update Installation Script ======" -ForegroundColor Cyan
Write-Host "System: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

# ===============================
# CERTIFICATE INSTALLATION SECTION
# ===============================

Write-Host "PHASE 1: CERTIFICATE INSTALLATION" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta

# Create a temporary directory for certificate downloads
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$certTempDir = Join-Path -Path $env:TEMP -ChildPath "CertDownloads_$timestamp"
if (-Not (Test-Path -Path $certTempDir)) {
    New-Item -ItemType Directory -Path $certTempDir -Force | Out-Null
}

Write-Host "Temporary certificate directory created: $certTempDir" -ForegroundColor Cyan

# Define certificate URLs and their corresponding filenames
$certificates = @(
    @{
        Name = "GeoTrust RSA CA 2018"
        Url = "https://cacerts.digicert.com/GeoTrustRSACA2018.crt"
        FileName = "GeoTrustRSACA2018.crt"
    },
    @{
        Name = "Microsoft Identity Verification Root CA 2020"
        Url = "https://www.microsoft.com/pkiops/certs/microsoft%20identity%20verification%20root%20certificate%20authority%202020.crt"
        FileName = "Microsoft_Identity_Verification_Root_CA_2020.crt"
    },
    @{
        Name = "DigiCert Global Root CA"
        Url = "https://cacerts.digicert.com/DigiCertGlobalRootCA.crt"
        FileName = "DigiCertGlobalRootCA.crt"
    }
)

# Function to download certificate with retry logic
function Download-Certificate {
    param(
        [string]$Url,
        [string]$FilePath,
        [string]$CertName
    )
    
    $maxRetries = 3
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        try {
            Write-Host "  Downloading $CertName..." -ForegroundColor Yellow
            
            # Use Invoke-WebRequest with SSL validation disabled for certificate downloads
            $response = Invoke-WebRequest -Uri $Url -OutFile $FilePath -UseBasicParsing -ErrorAction Stop
            
            if (Test-Path -Path $FilePath) {
                $fileSize = (Get-Item $FilePath).Length
                if ($fileSize -gt 0) {
                    Write-Host "  Successfully downloaded $CertName ($fileSize bytes)" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "  Downloaded file is empty for $CertName" -ForegroundColor Red
                    Remove-Item -Path $FilePath -ErrorAction SilentlyContinue
                }
            }
        }
        catch {
            Write-Host "  Attempt $($retryCount + 1) failed for $CertName : $($_.Exception.Message)" -ForegroundColor Red
        }
        
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Host "  Retrying in 2 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }
    
    Write-Host "  Failed to download $CertName after $maxRetries attempts" -ForegroundColor Red
    return $false
}

# Certificate installation counters
$certInstalled = 0
$certFailed = 0

# Download and install each certificate
foreach ($cert in $certificates) {
    $certPath = Join-Path -Path $certTempDir -ChildPath $cert.FileName
    
    Write-Host "`nProcessing certificate: $($cert.Name)" -ForegroundColor Blue
    
    # Download the certificate
    $downloadSuccess = Download-Certificate -Url $cert.Url -FilePath $certPath -CertName $cert.Name
    
    if ($downloadSuccess) {
        # Install the certificate
        try {
            Write-Host "  Installing certificate: $($cert.Name)..." -ForegroundColor Yellow
            
            # Use certutil to add the certificate to the Trusted Root store
            $result = & certutil -addstore "Root" $certPath 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  Successfully installed certificate: $($cert.Name)" -ForegroundColor Green
                $certInstalled++
            } else {
                Write-Host "  Failed to install certificate: $($cert.Name). certutil output: $result" -ForegroundColor Red
                $certFailed++
            }
        }
        catch {
            Write-Host "  Failed to install certificate: $($cert.Name). Error: $_" -ForegroundColor Red
            $certFailed++
        }
    } else {
        Write-Host "  Skipping installation of $($cert.Name) due to download failure" -ForegroundColor Yellow
        $certFailed++
    }
}

# Clean up certificate temporary files
Write-Host "`nCleaning up certificate temporary files..." -ForegroundColor Gray
try {
    Remove-Item -Path $certTempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Certificate temporary files cleaned up successfully" -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not clean up certificate temporary directory: $certTempDir" -ForegroundColor Yellow
}

# Certificate installation summary
Write-Host "`n============= Certificate Summary =============" -ForegroundColor Cyan
Write-Host "Certificates installed: $certInstalled" -ForegroundColor Green
Write-Host "Certificate failures: $certFailed" -ForegroundColor $(if ($certFailed -gt 0) { "Red" } else { "Green" })
Write-Host "=============================================" -ForegroundColor Cyan

# ===============================
# WINDOWS UPDATE INSTALLATION SECTION
# ===============================

Write-Host "`nPHASE 2: WINDOWS UPDATE INSTALLATION" -ForegroundColor Magenta
Write-Host "====================================" -ForegroundColor Magenta

# Define required updates
$updates = @(
    @{
        KB = "KB5005112"
        Url = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/software/secu/2021/08/windows10.0-kb5005112-x64_81d09dc6978520e1a6d44b3b15567667f83eba2c.msu"
        Description = "August 2021 Security Update"
    },
    @{
        KB = "KB5005625"
        Url = "https://catalog.s.download.windowsupdate.com/c/msdownload/update/software/updt/2021/09/windows10.0-kb5005625-x64_9a7d6abe389d940e08d759243c981670c33c71f5.msu"
        Description = "September 2021 Update Preview"
    }
)

# Function to validate URLs before attempting download
function Test-Url {
    param([string]$Url)
    
    try {
        $request = [System.Net.WebRequest]::Create($Url)
        $request.Method = "HEAD"
        $request.Timeout = 5000
        $response = $request.GetResponse()
        $response.Close()
        return $true
    }
    catch {
        return $false
    }
}

# Get installed hotfixes
Write-Host "Checking currently installed updates..." -ForegroundColor Cyan
$installedKBs = Get-HotFix | Select-Object -ExpandProperty HotFixID

# Create a temp directory for updates
$updateTempPath = "$env:TEMP\KBUpdates_$timestamp"
New-Item -Path $updateTempPath -ItemType Directory -Force | Out-Null
Write-Host "Created temporary update directory: $updateTempPath" -ForegroundColor Gray

# Initialize update counters
$totalUpdates = $updates.Count
$installedCount = 0
$errorCount = 0
$downloadedCount = 0

# Track updates for summary report
$updateResults = @()

# Begin update process
Write-Host "`nStarting update process for $totalUpdates updates...`n" -ForegroundColor Cyan

foreach ($update in $updates) {
    $kb = $update.KB
    $url = $update.Url
    $description = $update.Description
    $msuPath = Join-Path -Path $updateTempPath -ChildPath "$kb.msu"
    
    # Create result object
    $result = [PSCustomObject]@{
        KB = $kb
        Description = $description
        Status = "Not processed"
        Details = ""
    }
    
    Write-Host "Processing $kb - $description" -ForegroundColor Blue
    
    # Check if already installed
    if ($installedKBs -contains $kb) {
        Write-Host "  Status: $kb is already installed." -ForegroundColor Green
        $result.Status = "Already installed"
        $installedCount++
    } 
    else {
        Write-Host "  Status: $kb is NOT installed. Processing..." -ForegroundColor Yellow
        
        # Validate URL
        Write-Host "  Validating URL..." -ForegroundColor Gray
        if (-not (Test-Url -Url $url)) {
            Write-Host "  Error: Invalid URL or connection issue for $kb" -ForegroundColor Red
            $result.Status = "Failed"
            $result.Details = "Invalid URL or connection issue"
            $errorCount++
            $updateResults += $result
            continue
        }
        
        # Download the MSU file with progress display
        Write-Host "  Downloading $kb from Microsoft Catalog..." -ForegroundColor Yellow
        try {
            # Use Invoke-WebRequest with progress
            $ProgressPreference = 'Continue'
            Invoke-WebRequest -Uri $url -OutFile $msuPath -UserAgent "PowerShell Script" -UseBasicParsing
            
            # Verify file was downloaded and has content
            if (Test-Path $msuPath) {
                $fileSize = (Get-Item $msuPath).Length
                if ($fileSize -gt 0) {
                    Write-Host "  Download complete. File size: $([math]::Round($fileSize / 1MB, 2)) MB" -ForegroundColor Green
                    $downloadedCount++
                } else {
                    throw "Downloaded file is empty"
                }
            } else {
                throw "File was not downloaded properly"
            }
        } 
        catch {
            Write-Host "  Failed to download $kb from $url" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
            $result.Status = "Failed"
            $result.Details = "Download failed: $($_.Exception.Message)"
            $errorCount++
            $updateResults += $result
            continue
        }
        
        # Install the update silently
        Write-Host "  Installing $kb..." -ForegroundColor Yellow
        try {
            $process = Start-Process -FilePath "wusa.exe" -ArgumentList "`"$msuPath`" /quiet /norestart" -PassThru -Wait -ErrorAction Stop
            
            # Check process exit code
            switch ($process.ExitCode) {
                0 { 
                    Write-Host "  $kb installation completed successfully." -ForegroundColor Green 
                    $result.Status = "Installed"
                    $installedCount++
                }
                3010 { 
                    Write-Host "  $kb installation completed. Restart required." -ForegroundColor Yellow 
                    $result.Status = "Installed - Restart Required"
                    $installedCount++
                }
                2359302 { 
                    Write-Host "  $kb is not applicable to this system." -ForegroundColor Cyan 
                    $result.Status = "Not applicable"
                }
                default { 
                    Write-Host "  $kb installation returned exit code $($process.ExitCode)" -ForegroundColor Red 
                    $result.Status = "Failed"
                    $result.Details = "Exit code: $($process.ExitCode)"
                    $errorCount++
                }
            }
        } 
        catch {
            Write-Host "  Failed to install $kb. Error: $($_.Exception.Message)" -ForegroundColor Red
            $result.Status = "Failed"
            $result.Details = "Installation failed: $($_.Exception.Message)"
            $errorCount++
        }
    }
    
    # Add result to tracking array
    $updateResults += $result
    Write-Host ""
}

# Clean up the update downloads
Write-Host "Cleaning up update temporary files..." -ForegroundColor Gray
Remove-Item -Path $updateTempPath -Recurse -Force -ErrorAction SilentlyContinue

# ===============================
# FINAL SUMMARY
# ===============================

Write-Host "`n============= FINAL SUMMARY =============" -ForegroundColor Cyan
Write-Host "CERTIFICATES:" -ForegroundColor White
Write-Host "  Installed: $certInstalled" -ForegroundColor Green
Write-Host "  Failed: $certFailed" -ForegroundColor $(if ($certFailed -gt 0) { "Red" } else { "Green" })

Write-Host "`nWINDOWS UPDATES:" -ForegroundColor White
Write-Host "  Total processed: $totalUpdates" -ForegroundColor White
Write-Host "  Already installed: $($updateResults | Where-Object Status -eq 'Already installed' | Measure-Object).Count" -ForegroundColor Green
Write-Host "  Newly installed: $($updateResults | Where-Object {$_.Status -eq 'Installed' -or $_.Status -eq 'Installed - Restart Required'} | Measure-Object).Count" -ForegroundColor Green
Write-Host "  Not applicable: $($updateResults | Where-Object Status -eq 'Not applicable' | Measure-Object).Count" -ForegroundColor Cyan
Write-Host "  Failed: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "=========================================" -ForegroundColor Cyan

# Display detailed update results
if ($updateResults.Count -gt 0) {
    Write-Host "`nDetailed Update Results:" -ForegroundColor Cyan
    $updateResults | Format-Table -AutoSize
}

# Check if restart is required
$restartNeeded = $updateResults | Where-Object Status -eq 'Installed - Restart Required' | Measure-Object
if ($restartNeeded.Count -gt 0) {
    Write-Host "`nSystem restart required to complete update installation." -ForegroundColor Yellow
    $restart = Read-Host "Would you like to restart now? (Y/N)"
    if ($restart -eq "Y" -or $restart -eq "y") {
        Write-Host "Restarting system..." -ForegroundColor Yellow
        Restart-Computer -Force
    }
    else {
        Write-Host "Please restart your computer at your earliest convenience." -ForegroundColor Yellow
    }
}

Write-Host "`nScript execution completed." -ForegroundColor Cyan
