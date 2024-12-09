@echo off
REM Define aliases for sensor executables
SET SENSOR_PATH_32="\\servername\sharename\CybereasonSensor32.cybereason.net.exe"
SET SENSOR_PATH_64="\\servername\sharename\CybereasonSensor64.cybereason.net.exe"

REM Define the log path (change this to your desired location)
SET LOG_PATH=C:\Windows\Temp

REM Define required version for upgrade
SET REQUIRED_VERSION=23.2.231.1

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
echo "Detected Cybereason GUID: %REGISTRY_GUID%"

REM Check the current version
CALL :COMPARE_VERSION
IF %ERRORLEVEL% EQU 1 (
    echo "Existing Cybereason version is lower than required. Performing upgrade..."
) ELSE IF %ERRORLEVEL% EQU 0 (
    echo "Cybereason is up-to-date. Exiting script."
    goto END
) ELSE (
    echo "Failed to check version. Exiting script."
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
%SENSOR_PATH_32% /quiet /norestart -l "%LOG_PATH%\CybereasonInstall.log" AP_ORGANIZATION="TEST32"
IF %ERRORLEVEL% NEQ 0 (
    echo "Failed to install 32-bit Cybereason Sensor." > "%LOG_PATH%\CybereasonSensor32_Error.log"
    goto END
)
echo "CybereasonSensor installed - x86" > "%LOG_PATH%\CybereasonSensor32.txt"
goto END

:INSTALL_64BIT
REM Installing 64-bit Cybereason Sensor
echo "Installing 64-bit Cybereason Sensor..."
%SENSOR_PATH_64% /quiet /norestart -l "%LOG_PATH%\CybereasonInstall.log" AP_ORGANIZATION="TEST64"
IF %ERRORLEVEL% NEQ 0 (
    echo "Failed to install 64-bit Cybereason Sensor." > "%LOG_PATH%\CybereasonSensor64_Error.log"
    goto END
)
echo "CybereasonSensor installed - x64" > "%LOG_PATH%\CybereasonSensor64.txt"

:END
echo "Script execution completed."
exit /b

:COMPARE_VERSION
REM Query the version from the detected GUID
FOR /F "tokens=3" %%A IN ('reg query "%REGISTRY_GUID%" /v version') DO SET CURRENT_VERSION=%%A

REM Split the versions into parts
FOR /F "tokens=1-4 delims=." %%A IN ("%CURRENT_VERSION%") DO (
    SET CUR_MAJOR=%%A
    SET CUR_MINOR=%%B
    SET CUR_BUILD=%%C
    SET CUR_REV=%%D
)
FOR /F "tokens=1-4 delims=." %%A IN ("%REQUIRED_VERSION%") DO (
    SET REQ_MAJOR=%%A
    SET REQ_MINOR=%%B
    SET REQ_BUILD=%%C
    SET REQ_REV=%%D
)

REM Compare version numbers
IF %CUR_MAJOR% LSS %REQ_MAJOR% EXIT /B 1
IF %CUR_MAJOR% GTR %REQ_MAJOR% EXIT /B 0
IF %CUR_MINOR% LSS %REQ_MINOR% EXIT /B 1
IF %CUR_MINOR% GTR %REQ_MINOR% EXIT /B 0
IF %CUR_BUILD% LSS %REQ_BUILD% EXIT /B 1
IF %CUR_BUILD% GTR %REQ_BUILD% EXIT /B 0
IF %CUR_REV% LSS %REQ_REV% EXIT /B 1
IF %CUR_REV% GTR %REQ_REV% EXIT /B 0

REM Versions are equal
EXIT /B 0
