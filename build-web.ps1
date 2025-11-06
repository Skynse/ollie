# PowerShell script to build Flutter web with environment variables
# Usage: .\build-web.ps1

param(
    [string]$EnvFile = ".env"
)

Write-Host "Building Flutter web with environment variables from $EnvFile" -ForegroundColor Green

# Check if .env file exists
if (-not (Test-Path $EnvFile)) {
    Write-Host "Error: $EnvFile file not found. Please create one from .env.example" -ForegroundColor Red
    exit 1
}

# Read .env file and build dart-define arguments
$dartDefines = @()
Get-Content $EnvFile | ForEach-Object {
    $line = $_.Trim()
    # Skip empty lines and comments
    if ($line -and -not $line.StartsWith("#")) {
        $dartDefines += "--dart-define=$line"
    }
}

if ($dartDefines.Count -eq 0) {
    Write-Host "Error: No environment variables found in $EnvFile" -ForegroundColor Red
    exit 1
}

Write-Host "Found $($dartDefines.Count) environment variables" -ForegroundColor Cyan

# Build the Flutter web app
$buildCommand = "flutter build web $($dartDefines -join ' ')"
Write-Host "Running: $buildCommand" -ForegroundColor Yellow

Invoke-Expression $buildCommand

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild completed successfully!" -ForegroundColor Green
    Write-Host "Output directory: build/web" -ForegroundColor Cyan
} else {
    Write-Host "`nBuild failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}
