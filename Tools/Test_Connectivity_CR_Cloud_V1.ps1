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


param (
    [string]$ClientConsole,
    [int[]]$PortsToCheck = @(443, 8443)
)

# Function to Get Ports for Specific Domain
function Get-DomainsWithPorts {
    param (
        [string]$ClientConsole
    )

    $DomainPortConfig = @{
        # Domains with only 443
        "cr-protect.cybereason.net" = @(443)
        "data-epgw-eu-west-1.cybereason.net" = @(443)
        "probe-dist-dns.cybereason.net" = @(443)

        # Check Regestartion & Detection servers access
        "$ClientConsole-r.cybereason.net" = @(443, 8443)
        "$ClientConsole-1-t.cybereason.net" = @(443, 8443)
        "$ClientConsole.cybereason.net" = @(443)
    }

    return $DomainPortConfig
}

# Function to Prompt for Client Console if not provided
function Get-ClientConsole {
    if ([string]::IsNullOrWhiteSpace($ClientConsole)) {
        do {
            Write-Host "Please enter your Cybereason Client Console name:" -ForegroundColor Cyan
            $script:ClientConsole = Read-Host "Client Console"
        } while ([string]::IsNullOrWhiteSpace($script:ClientConsole))
    }
    return $script:ClientConsole
}

# Enhanced Port Connectivity Function
function Test-PortConnectivity {
    param (
        [string]$Hostname,
        [int[]]$Ports,
        [string]$Protocol = "TCP",
        [int]$TimeoutMilliseconds = 3000
    )

    Write-Host "Checking connectivity to $Hostname..." -ForegroundColor Cyan
    
    foreach ($Port in $Ports) {
        $Result = $false
        $ErrorMessage = ""

        try {
            # Create TCP Client with timeout
            $TcpClient = New-Object System.Net.Sockets.TcpClient
            $AsyncResult = $TcpClient.BeginConnect($Hostname, $Port, $null, $null)
            $Wait = $AsyncResult.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)

            if ($Wait) {
                $TcpClient.EndConnect($AsyncResult)
                $Result = $true
            } else {
                $ErrorMessage = "Connection Timeout"
                $Result = $false
            }
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            $Result = $false
        }
        finally {
            if ($TcpClient -ne $null) {
                $TcpClient.Close()
            }
        }

        # Output results
        if ($Result) {
            Write-Host "✓ Port $Port is OPEN on $Hostname" -ForegroundColor Green
        } else {
            Write-Host "✗ Port $Port is CLOSED on $Hostname" -ForegroundColor Red
            Write-Host "   Error: $ErrorMessage" -ForegroundColor Yellow
        }
    }
}

# Comprehensive SSL Certificate Check
function Test-SSLCertificate {
    param (
        [string]$ClientConsole,
        [int[]]$PortsToCheck = @(443, 8443)
    )

    # Get Domain-Specific Port Configuration
    $DomainPortConfig = @{
        # Domains with only 443
        "cr-protect.cybereason.net" = @(443)
        "data-epgw-eu-west-1.cybereason.net" = @(443)
        "probe-dist-dns.cybereason.net" = @(443)

        # Domains with both 443 and 8443
        "$ClientConsole-r.cybereason.net" = @(443, 8443)
        "$ClientConsole-1-t.cybereason.net" = @(443, 8443)
        "$ClientConsole.cybereason.net" = @(443)
    }

    Write-Host "Checking SSL/TLS Certificates for Cybereason Domains..." -ForegroundColor Cyan

    foreach ($Domain in $DomainPortConfig.Keys) {
        $PortsToTest = $DomainPortConfig[$Domain]

        foreach ($Port in $PortsToTest) {
            try {
                # Create a TCP client to establish an SSL connection
                $TCPClient = New-Object System.Net.Sockets.TcpClient($Domain, $Port)
                $TCPStream = $TCPClient.GetStream()

                # Create SSL Stream
                $SSLStream = New-Object System.Net.Security.SslStream($TCPStream, $false, {
                    param($sender, $certificate, $chain, $sslPolicyErrors)
                    
                    # Validate domain matching
                    $CertificateDomains = @()
                    
                    # Extract Subject Alternative Names (SANs)
                    $certificate.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.17' } | ForEach-Object {
                        $SAN = [System.Security.Cryptography.X509Certificates.X509Extension]::new($_, $_.RawData, $false)
                        $SAN.Format($false) -split ', ' | Where-Object { $_ -match '^DNS=' } | ForEach-Object {
                            $CertificateDomains += $_.Substring(4)
                        }
                    }

                    # Add Subject CN
                    if ($certificate.Subject -match 'CN=([^,]+)') {
                        $CertificateDomains += $Matches[1]
                    }

                    # Check if any domain matches the wildcard *.cybereason.net
                    $WildcardMatch = $CertificateDomains | Where-Object { 
                        $_ -like '*.cybereason.net' -or $_ -eq 'cybereason.net'
                    }

                    # Log certificate details
                    Write-Host "Domain: $Domain : Port $Port" -ForegroundColor DarkCyan
                    Write-Host "Certificate Domains:" -ForegroundColor DarkGreen
                    $CertificateDomains | ForEach-Object { 
                        Write-Host "   - $_" -ForegroundColor DarkGreen 
                    }
                    Write-Host "Subject: $($certificate.Subject)" -ForegroundColor DarkGreen
                    Write-Host "Issuer: $($certificate.Issuer)" -ForegroundColor DarkGreen
                    Write-Host "Valid From: $($certificate.GetEffectiveDateString())" -ForegroundColor DarkGreen
                    Write-Host "Valid To: $($certificate.GetExpirationDateString())" -ForegroundColor DarkGreen

                    # Check for wildcard match
                    if ($WildcardMatch) {
                        Write-Host "✓ Certificate matches *.cybereason.net" -ForegroundColor Green
                    } else {
                        Write-Host "✗ Certificate does not match *.cybereason.net" -ForegroundColor Red
                    }

                    # Check for self-signed or potential issues
                    if ($sslPolicyErrors -ne 'None') {
                        Write-Host "SSL Policy Errors Detected: $sslPolicyErrors" -ForegroundColor Yellow
                    }

                    # Always return true to allow connection for inspection
                    return $true
                }, $null)

                # Perform the SSL Handshake
                $SSLStream.AuthenticateAsClient($Domain)

                # Check certificate chain
                $CertificateChain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
                $CertificateChain.ChainPolicy.RevocationFlag = [System.Security.Cryptography.X509Certificates.X509RevocationFlag]::EntireChain
                $CertificateChain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::Online
                $CertificateChain.ChainPolicy.UrlRetrievalTimeout = New-TimeSpan -Seconds 30

                $ChainIsValid = $CertificateChain.Build($SSLStream.RemoteCertificate)

                if ($ChainIsValid) {
                    Write-Host "✓ SSL Certificate Chain Valid for $Domain : Port $Port" -ForegroundColor Green
                } else {
                    Write-Host "✗ SSL Certificate Chain Invalid for $Domain : Port $Port" -ForegroundColor Red
                    $CertificateChain.ChainStatus | ForEach-Object {
                        Write-Host "   Certificate Chain Error: $($_.Status)" -ForegroundColor Red
                    }
                }

                # Clean up
                $SSLStream.Close()
                $TCPClient.Close()

            } catch {
                Write-Host "✗ Failed to establish SSL connection to $Domain on Port $Port" -ForegroundColor Red
                Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

# Function to Test DNS Resolution
function Test-DNSResolution {
    param (
        [string]$ClientConsole
    )

    $CybereasonHostnames = @(
        "probe-dist-dns.cybereason.net",
        "data-epgw-eu-west-1.cybereason.net",
        "cr-protect.cybereason.net",
        "$ClientConsole-r.cybereason.net",
        "$ClientConsole-1-t.cybereason.net",
        "$ClientConsole.cybereason.net"
    )

    foreach ($Hostname in $CybereasonHostnames) {
        Write-Host "Checking DNS resolution for $Hostname..." -ForegroundColor Cyan
        try {
            $IPs = Resolve-DnsName -Name $Hostname -ErrorAction Stop
            Write-Host "✓ DNS Resolution Successful for $Hostname" -ForegroundColor Green
            $IPs | ForEach-Object { 
                if ($_.Type -eq 'A') {
                    Write-Host "   Resolved IP: $($_.IPAddress)" -ForegroundColor DarkGreen
                }
            }
        } catch {
            Write-Host "✗ DNS Resolution Failed for $Hostname" -ForegroundColor Red
        }
    }
}

# Main Script Execution
try {
    # Get Client Console Name
    $ClientConsole = Get-ClientConsole

    # Get Domain-Specific Port Configuration
    $DomainPortConfig = Get-DomainsWithPorts -ClientConsole $ClientConsole

    # Banner
    Write-Host "===== Cybereason Connectivity Check =====" -ForegroundColor Magenta
    Write-Host "Client Console: $ClientConsole" -ForegroundColor Cyan

    # Perform Checks
    Write-Host "`n[1] DNS Resolution Check" -ForegroundColor Green
    Test-DNSResolution -ClientConsole $ClientConsole

    Write-Host "`n[2] Port Connectivity Check" -ForegroundColor Green
    foreach ($Domain in $DomainPortConfig.Keys) {
        Test-PortConnectivity -Hostname $Domain -Ports $DomainPortConfig[$Domain]
    }

    Write-Host "`n[3] SSL Certificate Validation" -ForegroundColor Green
    Test-SSLCertificate -ClientConsole $ClientConsole -PortsToCheck $PortsToCheck

    Write-Host "`n===== Cybereason Connectivity Check Completed =====" -ForegroundColor Magenta
}
catch {
    Write-Host "An unexpected error occurred: $($_.Exception.Message)" -ForegroundColor Red
}
