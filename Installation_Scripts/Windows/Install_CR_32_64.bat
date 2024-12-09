@echo off
REM Define aliases for sensor executables
SET SENSOR_PATH_32="\\servername\sharename\CybereasonSensor32.cybereason.net.exe"
SET SENSOR_PATH_64="\\servername\sharename\CybereasonSensor64.cybereason.net.exe"

REM Check if Cybereason ActiveProbe is already installed
IF EXIST "C:\Program Files\Cybereason ActiveProbe" (
    echo "Cybereason ActiveProbe is already installed."
    goto END
)

IF EXIST "C:\Program Files (x86)\Cybereason ActiveProbe" (
    echo "Cybereason ActiveProbe is already installed."
    goto END
)

REM Check if the system is 64-bit or 32-bit
IF EXIST "%SystemRoot%\SysWOW64" (
    goto INSTALL_64BIT
) ELSE (
    goto INSTALL_32BIT
)

:INSTALL_32BIT
REM Installing 32-bit Cybereason Sensor
echo "Installing 32-bit Cybereason Sensor..."
%SENSOR_PATH_32% /quiet /norestart -l C:\windows\Temp\CybereasonInstall.log AP_ORGANIZATION="TEST32"
IF %ERRORLEVEL% NEQ 0 (
    echo "Failed to install 32-bit Cybereason Sensor." > "C:\Windows\Temp\CybereasonSensor32_Error.log"
    goto END
)
echo "CybereasonSensor installed - x86" > "C:\Windows\Temp\CybereasonSensor32.txt"
goto END

:INSTALL_64BIT
REM Installing 64-bit Cybereason Sensor
echo "Installing 64-bit Cybereason Sensor..."
%SENSOR_PATH_64% /quiet /norestart -l C:\windows\Temp\CybereasonInstall.log AP_ORGANIZATION="TEST64"
IF %ERRORLEVEL% NEQ 0 (
    echo "Failed to install 64-bit Cybereason Sensor." > "C:\Windows\Temp\CybereasonSensor64_Error.log"
    goto END
)
echo "CybereasonSensor installed - x64" > "C:\Windows\Temp\CybereasonSensor64.txt"

:END
echo "Script execution completed."
exit /b
