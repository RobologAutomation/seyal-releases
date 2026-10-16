@echo off
rem Installs or updates Seyal for Windows. Double-click to run.
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; iex ((New-Object Net.WebClient).DownloadString('https://download.robolog.co.in/install.ps1'))"
echo.
pause
