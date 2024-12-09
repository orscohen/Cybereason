@echo off
REM Define aliases for sensor executables
SET SENSOR_PATH_32="\\servername\sharename\CybereasonSensor32.cybereason.net.exe"
SET SENSOR_PATH_64="\\servername\sharename\CybereasonSensor64.cybereason.net.exe"

REM Define required version for upgrade
SET REQUIRED_VERSION=23.2.231.1

REM Get the hostname
SET HOSTNAME=%COMPUTERNAME%

REM Define log path
SET LOG_PATH=C:\Windows\Temp\Cybereason_%HOSTNAME%

REM Detect the registry GUID dynamically and validate Displayname
SET REGISTRY_GUID=
FOR /F "tokens=*" %%A IN ('reg query "HKCR\Installer\Dependencies" /s /f "Displayname" /d /t REG_SZ') DO (
    FOR /F "tokens=2*" %%B IN ('reg query "%%A" /v Displayname 2^>nul ^| find /I "Cybereason Sensor"') DO (
        SET REGISTRY_GUID=%%A
        GOTO FOUND_GUID
    )
)

REM If no valid GUID is found, exit with error
IF NOT DEFINED REGISTRY_GUID (
    echo "Failed to locate the Cybereason registry key with Displayname 'Cybereason Sensor'. Exiting script."
    goto END
)

:FOUND_GUID
REM Log the detected GUID
echo "Detected Cybereason GUID: %REGISTRY_GUID%" >> "%LOG_PATH%.log"

REM Check the current version
CALL :COMPARE_VERSION
IF %ERRORLEVEL% EQU 1 (
    echo "Existing Cybereason version is lower than required. Performing upgrade..." >> "%LOG_PATH%.log"
) ELSE IF %ERRORLEVEL% EQU 0 (
    echo "Cybereason is up-to-date. Exiting script." >> "%LOG_PATH%.log"
    goto END
) ELSE (
    echo "Failed to check version. Exiting script." >> "%LOG_PATH%.log"
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
echo "Installing 32-bit Cybereason Sensor..." >> "%LOG_PATH%.log"
%SENSOR_PATH_32% /quiet /norestart -l "%LOG_PATH%_Install.log" 
IF %ERRORLEVEL% NEQ 0 (
    echo "Failed to install 32-bit Cybereason Sensor." >> "%LOG_PATH%_Error.log"
    goto END
)
echo "CybereasonSensor installed - x86" >> "%LOG_PATH%.log"
goto END

:INSTALL_64BIT
REM Installing 64-bit Cybereason Sensor
echo "Installing 64-bit Cybereason Sensor..." >> "%LOG_PATH%.log"
%SENSOR_PATH_64% /quiet /norestart -l "%LOG_PATH%_Install.log"
IF %ERRORLEVEL% NEQ 0 (
    echo "Failed to install 64-bit Cybereason Sensor." >> "%LOG_PATH%_Error.log"
    goto END
)
echo "CybereasonSensor installed - x64" >> "%LOG_PATH%.log"

:END
echo "Script execution completed." >> "%LOG_PATH%.log"
exit /b
