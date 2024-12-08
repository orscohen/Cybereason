# Windows KB Update Checker
# Checks if the required KB is installed based on OS type and version

function Get-OSKBRequirement {
    $osInfo = Get-WmiObject Win32_OperatingSystem
    $osCaption = $osInfo.Caption
    $osVersion = $osInfo.Version

    # Detailed KB requirements mapping
    $kbRequirements = @{
        "Windows 7" = @{
            Condition = $osCaption -like "*Windows 7*" -and $osCaption -like "*SP1*",
            RequiredKBs = @("KB5006743", "KB5006728")
            Notes = "Requires ESU support from Microsoft"
        }
        "Windows 8" = @{
            Condition = $osCaption -like "*Windows 8*" -and $osCaption -notlike "*8.1*",
            RequiredKBs = @("KB5006739")
        }
        "Windows 8.1" = @{
            Condition = $osCaption -like "*Windows 8.1*",
            RequiredKBs = @("KB5006714", "KB5006729")
        }
        "Windows 10 2004" = @{
            Condition = $osCaption -like "*Windows 10*" -and $osVersion -like "10.0.19041*",
            RequiredKBs = @("KB5005611")
        }
        "Windows 10 1507" = @{
            Condition = $osCaption -like "*Windows 10*" -and $osVersion -like "10.0.10240*",
            RequiredKBs = @("KB5006675")
        }
        "Windows 10 1607" = @{
            Condition = $osCaption -like "*Windows 10*" -and $osVersion -like "10.0.14393*",
            RequiredKBs = @("KB5006669")
        }
        "Windows 10 1809" = @{
            Condition = $osCaption -like "*Windows 10*" -and $osVersion -like "10.0.17763*",
            RequiredKBs = @("KB5005625")
        }
        "Windows 10 1909" = @{
            Condition = $osCaption -like "*Windows 10*" -and $osVersion -like "10.0.18363*",
            RequiredKBs = @("KB5005624")
        }
        "Windows Server 2008 R2" = @{
            Condition = $osCaption -like "*Windows Server 2008 R2*" -and $osCaption -like "*SP1*",
            RequiredKBs = @("KB5006743", "KB5006728")
            Notes = "Requires ESU support from Microsoft"
        }
        "Windows Server 2012" = @{
            Condition = $osCaption -like "*Windows Server 2012*" -and $osCaption -notlike "*R2*",
            RequiredKBs = @("KB5006739", "KB5006732")
        }
        "Windows Server 2012 R2" = @{
            Condition = $osCaption -like "*Windows Server 2012 R2*",
            RequiredKBs = @("KB5006714", "KB5006729")
        }
        "Windows Server 2016" = @{
            Condition = $osCaption -like "*Windows Server 2016*",
            RequiredKBs = @("KB5006669")
        }
        "Windows Server 2019" = @{
            Condition = $osCaption -like "*Windows Server 2019*",
            RequiredKBs = @("KB5005625")
        }
        "Windows Server 2022" = @{
            Condition = $osCaption -like "*Windows Server 2022*",
            RequiredKBs = @("KB5005619")
        }
    }

    # Find matching OS
    $matchingOS = $kbRequirements.GetEnumerator() | Where-Object { $_.Value.Condition }

    if ($matchingOS) {
        $osName = $matchingOS.Key
        $requiredKBs = $matchingOS.Value.RequiredKBs
        $notes = $matchingOS.Value.Notes

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
        return $null
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
else {
    Write-Host "No matching OS found or unsupported OS version." -ForegroundColor Red
}
