# Simple Vercel deployment script
# Usage: .\deploy.ps1

Write-Host "Building Flutter web app..." -ForegroundColor Cyan
flutter build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`nDeploying to Vercel..." -ForegroundColor Cyan
vercel deploy --prod --cwd build/web

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Deployment successful!" -ForegroundColor Green
} else {
    Write-Host "`n✗ Deployment failed!" -ForegroundColor Red
    exit 1
}
