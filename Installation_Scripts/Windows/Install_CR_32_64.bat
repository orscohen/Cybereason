IF EXIST "C:\Program Files\Cybereason ActiveProbe" GOTO END
IF EXIST "C:\Program Files (x86)\Cybereason ActiveProbe" GOTO END

:32-bit
if exist %SystemRoot%\SysWOW64 goto 64-bit
\\servername\sharename\CybereasonSensor32.cybereason.net.exe /quiet /norestart -l C:\windows\Temp\CybereasonInstall.log AP_ORGANIZATION="TEST32"
echo "CybereasonSensor installed- x86" > "c:\Windows\temp\CybereasonSensor32.txt"
goto END

:64-bit
\\servername\sharename\CybereasonSensor64.cybereason.net.exe /quiet /norestart -l C:\windows\Temp\CybereasonInstall.log AP_ORGANIZATION="TEST64"
echo "CybereasonSensor installed- x64" > "c:\Windows\temp\CybereasonSensor64.txt"

:END
