#requires -RunAsAdministrator
<#
.SYNOPSIS
    Downloads and installs specified Windows updates
.DESCRIPTION
    This script checks for and installs Windows updates based on a predefined list.
    It verifies admin permissions, validates URLs, includes error handling, and 
    provides detailed progress feedback.
.NOTES
    Requires: PowerShell 5.1+, Administrator privileges, Internet connectivity
#>

# Verify script is running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrator privileges. Please restart as administrator." -ForegroundColor Red
    exit 1
}

# Define required updates with the corrected URLs
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

# Create a temp directory with timestamp to avoid conflicts
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tempPath = "$env:TEMP\KBUpdates_$timestamp"
New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
Write-Host "Created temporary directory: $tempPath" -ForegroundColor Gray

# Initialize counters
$totalUpdates = $updates.Count
$installedCount = 0
$errorCount = 0
$downloadedCount = 0

# Track updates for summary report
$updateResults = @()

# Begin update process
Write-Host "`n====== Windows Update Installation Script ======" -ForegroundColor Cyan
Write-Host "Starting update process for $totalUpdates updates..." -ForegroundColor Cyan
Write-Host "System: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Cyan
Write-Host "================================================`n" -ForegroundColor Cyan

foreach ($update in $updates) {
    $kb = $update.KB
    $url = $update.Url
    $description = $update.Description
    $msuPath = Join-Path -Path $tempPath -ChildPath "$kb.msu"
    
    # Create result object
    $result = [PSCustomObject]@{
        KB = $kb
        Description = $description
        Status = "Not processed"
        Details = ""
    }
    
    Write-Host "`nProcessing $kb - $description" -ForegroundColor Blue
    
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
            # Instead of using WebClient with events, use Invoke-WebRequest with progress
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
}

# Clean up the downloads
Write-Host "`nCleaning up temporary files..." -ForegroundColor Gray
Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue

# Display summary
Write-Host "`n============= Update Summary =============" -ForegroundColor Cyan
Write-Host "Total updates processed: $totalUpdates" -ForegroundColor White
Write-Host "Already installed: $($updateResults | Where-Object Status -eq 'Already installed' | Measure-Object).Count" -ForegroundColor Green
Write-Host "Newly installed: $($updateResults | Where-Object {$_.Status -eq 'Installed' -or $_.Status -eq 'Installed - Restart Required'} | Measure-Object).Count" -ForegroundColor Green
Write-Host "Not applicable: $($updateResults | Where-Object Status -eq 'Not applicable' | Measure-Object).Count" -ForegroundColor Cyan
Write-Host "Failed: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host "=========================================" -ForegroundColor Cyan

# Display detailed results
Write-Host "`nDetailed Results:" -ForegroundColor Cyan
$updateResults | Format-Table -AutoSize

# Check if restart is required
$restartNeeded = $updateResults | Where-Object Status -eq 'Installed - Restart Required' | Measure-Object
if ($restartNeeded.Count -gt 0) {
    Write-Host "`nSystem restart required to complete update installation." -ForegroundColor Yellow
    $restart = Read-Host "Would you like to restart now? (Y/N)"
    if ($restart -eq "Y" -or $restart -eq "y") {
        Restart-Computer -Force
    }
    else {
        Write-Host "Please restart your computer at your earliest convenience." -ForegroundColor Yellow
    }
}
