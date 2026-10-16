# Installs (or repairs) Seyal for Windows in the person's own programs folder,
#   %LOCALAPPDATA%\Programs\Seyal
# and puts Seyal on the Desktop and in the Start menu. No admin rights needed.
# Published as https://download.robolog.co.in/install.ps1 (and Seyal-Setup.cmd,
# which runs it), from RobologAutomation/seyal-releases. Running it again installs the newest version over the old one.
# The in-app update unpacks into the same folder, so Seyal stays in one place.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is very slow with the progress bar
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$site = 'https://download.robolog.co.in'
$dir = Join-Path $env:LOCALAPPDATA 'Programs\Seyal'
$exe = Join-Path $dir 'seyal.exe'
$work = Join-Path $env:TEMP 'seyal-install'

function Say($text) { Write-Host "  $text" }

try {
  Write-Host ''
  Say 'Seyal for Windows'
  $info = Invoke-RestMethod "$site/latest.json?t=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" -UseBasicParsing
  Say "Downloading version $($info.version) ..."
  $zip = Join-Path $env:TEMP 'seyal-windows.zip'
  Invoke-WebRequest $info.windows.url -OutFile $zip -UseBasicParsing
  if ($info.windows.sha256 -and ((Get-FileHash $zip -Algorithm SHA256).Hash.ToLower() -ne $info.windows.sha256.ToLower())) {
    throw 'the download was damaged. Run it again.'
  }

  $open = Get-Process -Name seyal -ErrorAction SilentlyContinue
  if ($open) {
    Say 'Closing Seyal ...'
    $open | ForEach-Object { $_.CloseMainWindow() | Out-Null }
    Start-Sleep -Seconds 3
    Get-Process -Name seyal -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 1
  }

  Say "Installing in $dir ..."
  if (Test-Path $work) { Remove-Item $work -Recurse -Force }
  Expand-Archive -Path $zip -DestinationPath $work -Force
  $from = $work
  $inside = Get-ChildItem $from
  if (($inside | Measure-Object).Count -eq 1 -and $inside[0].PSIsContainer) { $from = $inside[0].FullName }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  Copy-Item -Path (Join-Path $from '*') -Destination $dir -Recurse -Force
  Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item $zip -Force -ErrorAction SilentlyContinue

  $shell = New-Object -ComObject WScript.Shell
  foreach ($place in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
    $link = $shell.CreateShortcut((Join-Path $place 'Seyal.lnk'))
    $link.TargetPath = $exe
    $link.WorkingDirectory = $dir
    $link.IconLocation = $exe
    $link.Save()
  }
  Say 'Seyal is on your Desktop and in the Start menu.'
  Start-Process $exe
  Say 'Done. Seyal is starting.'
} catch {
  Write-Host ''
  Write-Host "  Seyal could not be installed: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host '  Check the internet connection and run it again.'
  exit 1
}
