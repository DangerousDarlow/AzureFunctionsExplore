$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Join-Path $root "AzureFunctionsExplore"
$publishPath = Join-Path $projectRoot "publish"
$packagePath = Join-Path $projectRoot "package.zip"

if (Test-Path $publishPath) {
        Remove-Item $publishPath -Recurse -Force
        Write-Host "Cleaned build artifacts" -ForegroundColor Cyan
}

if (Test-Path $packagePath) {
        Remove-Item $packagePath -Recurse -Force
        Write-Host "Cleaned deployment package" -ForegroundColor Cyan
}