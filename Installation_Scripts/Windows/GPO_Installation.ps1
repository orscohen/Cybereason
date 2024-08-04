# Define variables for the sensor share and local paths
$SensorShare = '\\ShareServer\Software\SoftwareRepo\CybereasonActiveProbe\CybereasonActiveProbe.exe'
$SensorLocal = 'C:\windows\Temp\CybereasonActiveProbe.exe'

# Create the CybereasonActiveProbe TEMP directory if it does not already exist
$TempDir = 'C:\windows\Temp\CybereasonActiveProbe'
if (-Not (Test-Path -Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force
}

# Copy the sensor installer if the share is available
if (Test-Path -Path $SensorShare) {
    Copy-Item -Path $SensorShare -Destination $SensorLocal -Force
} else {
    Write-Host "Sensor share not found: $SensorShare" -ForegroundColor Red
    exit 1
}

# Define the name of the Cybereason ActiveProbe installation
$cr = 'Cybereason ActiveProbe'

# Check if Cybereason ActiveProbe is installed
$installcr = Get-WmiObject -Class Win32_Product -Filter "Name='$cr'" | Where-Object { $_.Name -eq $cr }
if (-Not $installcr) {
    Write-Host "Cybereason ActiveProbe is not installed. Starting installation..."
    & $SensorLocal /install /quiet /norestart CID=$CID
} else {
    Write-Host "Cybereason ActiveProbe is already installed." -ForegroundColor Green
}
