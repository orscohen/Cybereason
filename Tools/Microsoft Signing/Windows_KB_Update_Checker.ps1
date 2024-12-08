# Windows KB Update Checker
# Checks if the required KB is installed based on OS type and version

function Get-OSKBRequirement {
    $osInfo = Get-WmiObject Win32_OperatingSystem
    $osCaption = $osInfo.Caption
    $osVersion = $osInfo.Version

    # Supported OS versions
    $supportedOSVersions = @(
        "6.1",   # Windows 7
        "6.2",   # Windows 8
        "6.3",   # Windows 8.1
        "10.0"   # Windows 10 and Server versions
    )

    # Detailed KB requirements mapping
    $kbRequirements = @{
        "Windows 7" = @{
            Condition = { $osCaption -like "*Windows 7*" -and $osCaption -like "*SP1*" }
            RequiredKBs = @("KB5006743", "KB5006728")
            Notes = "Requires ESU support from Microsoft"
            MaxSupportedVersion = "6.1"
        }
        "Windows 8" = @{
            Condition = { $osCaption -like "*Windows 8*" -and $osCaption -notlike "*8.1*" }
            RequiredKBs = @("KB5006739")
            MaxSupportedVersion = "6.2"
        }
        "Windows 8.1" = @{
            Condition = { $osCaption -like "*Windows 8.1*" }
            RequiredKBs = @("KB5006714", "KB5006729")
            MaxSupportedVersion = "6.3"
        }
        "Windows 10 2004" = @{
            Condition = { $osCaption -like "*Windows 10*" -and $osVersion -like "10.0.19041*" }
            RequiredKBs = @("KB5005611")
            MaxSupportedVersion = "10.0.19041"
        }
        "Windows 10 1507" = @{
            Condition = { $osCaption -like "*Windows 10*" -and $osVersion -like "10.0.10240*" }
            RequiredKBs = @("KB5006675")
            MaxSupportedVersion = "10.0.10240"
        }
        "Windows 10 1607" = @{
            Condition = { $osCaption -like "*Windows 10*" -and $osVersion -like "10.0.14393*" }
            RequiredKBs = @("KB5006669")
            MaxSupportedVersion = "10.0.14393"
        }
        "Windows 10 1809" = @{
            Condition = { $osCaption -like "*Windows 10*" -and $osVersion -like "10.0.17763*" }
            RequiredKBs = @("KB5005625")
            MaxSupportedVersion = "10.0.17763"
        }
        "Windows 10 1909" = @{
            Condition = { $osCaption -like "*Windows 10*" -and $osVersion -like "10.0.18363*" }
            RequiredKBs = @("KB5005624")
            MaxSupportedVersion = "10.0.18363"
        }
        "Windows Server 2008 R2" = @{
            Condition = { $osCaption -like "*Windows Server 2008 R2*" -and $osCaption -like "*SP1*" }
            RequiredKBs = @("KB5006743", "KB5006728")
            Notes = "Requires ESU support from Microsoft"
            MaxSupportedVersion = "6.1"
        }
        "Windows Server 2012" = @{
            Condition = { $osCaption -like "*Windows Server 2012*" -and $osCaption -notlike "*R2*" }
            RequiredKBs = @("KB5006739", "KB5006732")
            MaxSupportedVersion = "6.2"
        }
        "Windows Server 2012 R2" = @{
            Condition = { $osCaption -like "*Windows Server 2012 R2*" }
            RequiredKBs = @("KB5006714", "KB5006729")
            MaxSupportedVersion = "6.3"
        }
        "Windows Server 2016" = @{
            Condition = { $osCaption -like "*Windows Server 2016*" }
            RequiredKBs = @("KB5006669")
            MaxSupportedVersion = "10.0.14393"
        }
        "Windows Server 2019" = @{
            Condition = { $osCaption -like "*Windows Server 2019*" }
            RequiredKBs = @("KB5005625")
            MaxSupportedVersion = "10.0.17763"
        }
        "Windows Server 2022" = @{
            Condition = { $osCaption -like "*Windows Server 2022*" }
            RequiredKBs = @("KB5005619")
            MaxSupportedVersion = "10.0.20348"
        }
    }

    # Check if OS is recognized and supported
    $isSupportedOSVersion = $false
    foreach ($supportedVersion in $supportedOSVersions) {
        if ($osVersion.StartsWith($supportedVersion)) {
            $isSupportedOSVersion = $true
            break
        }
    }

    # Abort if unsupported OS or newer version detected
    if (-not $isSupportedOSVersion) {
        Write-Host "UNSUPPORTED OS: This script is not compatible with the current operating system." -ForegroundColor Red
        Write-Host "Detected OS Version: $osCaption (Version: $osVersion)" -ForegroundColor Yellow
        Write-Host "Script will now exit." -ForegroundColor Red
        exit 1
    }

    # Find matching OS
    $matchingOS = $kbRequirements.GetEnumerator() | Where-Object { 
        $condition = $_.Value.Condition
        Invoke-Command $condition 
    }

    if ($matchingOS) {
        $osName = $matchingOS.Key
        $requiredKBs = $matchingOS.Value.RequiredKBs
        $notes = $matchingOS.Value.Notes
        $maxSupportedVersion = $matchingOS.Value.MaxSupportedVersion

        # Additional check for future or unsupported versions
        $isVersionSupported = $false
        if ($osVersion.StartsWith("10.0")) {
            # For Windows 10/Server versions, do a more granular check
            $isVersionSupported = [System.Version]$osVersion -le [System.Version]$maxSupportedVersion
        } else {
            # For older OS versions, check major and minor version
            $isVersionSupported = [System.Version]$osVersion -le [System.Version]$maxSupportedVersion
        }

        if (-not $isVersionSupported) {
            Write-Host "UNSUPPORTED OS VERSION: This script does not support future or newer versions." -ForegroundColor Red
            Write-Host "Detected OS Version: $osCaption (Version: $osVersion)" -ForegroundColor Yellow
            Write-Host "Maximum Supported Version: $maxSupportedVersion" -ForegroundColor Yellow
            Write-Host "Script will now exit." -ForegroundColor Red
            exit 1
        }

        # Check installed updates
        $installedUpdates = Get-HotFix | Where-Object { $requiredKBs -contains $_.HotFixID }

        $result = @{
            OSName = $osName
            RequiredKBs = $requiredKBs
            InstalledKBs = $installedUpdates.HotFixID
            IsCompliant = $installedUpdates.Count -ge $requiredKBs.Count
            Notes = $notes
        }

        return $result
    }
    else {
        Write-Host "UNSUPPORTED OS: No matching OS configuration found." -ForegroundColor Red
        Write-Host "Detected OS: $osCaption (Version: $osVersion)" -ForegroundColor Yellow
        Write-Host "Script will now exit." -ForegroundColor Red
        exit 1
    }
}

# Main script execution
$kbCheck = Get-OSKBRequirement

if ($kbCheck) {
    Write-Host "Operating System: $($kbCheck.OSName)"
    Write-Host "Required KB Updates: $($kbCheck.RequiredKBs -join ', ')"
    Write-Host "Installed KB Updates: $($kbCheck.InstalledKBs -join ', ')"
    
    if ($kbCheck.IsCompliant) {
        Write-Host "Compliance Status: COMPLIANT" -ForegroundColor Green
    }
    else {
        Write-Host "Compliance Status: NON-COMPLIANT" -ForegroundColor Red
        Write-Host "Missing KB Updates: $($kbCheck.RequiredKBs | Where-Object { $_ -notin $kbCheck.InstalledKBs })"
    }

    if ($kbCheck.Notes) {
        Write-Host "Additional Notes: $($kbCheck.Notes)" -ForegroundColor Yellow
    }
}
