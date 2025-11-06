# Build with environment variables
$ENV_FILE = ".env"

if (-not (Test-Path $ENV_FILE)) {
    Write-Host "Error: $ENV_FILE file not found. Please create one from .env.example" -ForegroundColor Red
    exit 1
}

# Read .env file and build dart-define arguments
$dartDefines = @()
Get-Content $ENV_FILE | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $dartDefines += "--dart-define=$line"
    }
}

flutter build web --release $($dartDefines -join ' ')
cd build/web

# Clean up old hashed files
Remove-Item -Path "main.*.dart.js" -ErrorAction SilentlyContinue
Remove-Item -Path "flutter_bootstrap.*.js" -ErrorAction SilentlyContinue

$HASH = (Get-FileHash main.dart.js -Algorithm MD5).Hash.ToLower()
Rename-Item -Path main.dart.js -NewName main.$HASH.dart.js
Rename-Item -Path flutter_bootstrap.js -NewName flutter_bootstrap.$HASH.js

# Update references in index.html
(Get-Content index.html) -replace 'main.dart.js', "main.$HASH.dart.js" | Set-Content index.html
(Get-Content index.html) -replace 'flutter_bootstrap.js', "flutter_bootstrap.$HASH.js" | Set-Content index.html

# Update main.dart.js reference in flutter_bootstrap
(Get-Content flutter_bootstrap.$HASH.js) -replace 'main.dart.js', "main.$HASH.dart.js" | Set-Content flutter_bootstrap.$HASH.js

# Add version.json
$timestamp = Get-Date -UFormat %s
$jsonObject = @{ version = "$timestamp" }
$jsonObject | ConvertTo-Json -Compress | Set-Content -Path version.json

# Copy vercel.json from project root
Copy-Item -Path "../../vercel.json" -Destination "vercel.json" -Force

vercel deploy --prod
cd ../../
