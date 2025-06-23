$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Join-Path $root "AzureFunctionsExplore"

Write-Host "Change location to $projectRoot" -ForegroundColor Yellow
Push-Location $projectRoot

try {
    if (Test-Path "publish") {
        Remove-Item "publish" -Recurse -Force
        Write-Host "Cleaned previous build artifacts" -ForegroundColor Gray
    }
    
    Write-Host "Restoring NuGet packages..." -ForegroundColor Cyan
    dotnet restore

    if ($LASTEXITCODE -ne 0) {
        throw "Restore failed"
    }

    Write-Host "Building project..." -ForegroundColor Cyan
    dotnet build --configuration Release --runtime linux-x64 --no-restore

    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
    
    Write-Host "Publishing project..." -ForegroundColor Cyan
    dotnet publish --configuration Release --runtime linux-x64 --output .\publish --no-build --self-contained false

    if ($LASTEXITCODE -ne 0) {
        throw "Publish failed"
    }
    
    Write-Host "Success" -ForegroundColor Green
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}