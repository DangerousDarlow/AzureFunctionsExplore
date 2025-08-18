$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Join-Path $root "AzureFunctionsExplore"
$terraformRoot = Join-Path $root "Terraform"
$publishPath = Join-Path $projectRoot "publish"
$packagePath = Join-Path $projectRoot "package.zip"

try {
    Write-Host "Build" -ForegroundColor Yellow

    Push-Location $projectRoot

    if (Test-Path $publishPath) {
        Remove-Item $publishPath -Recurse -Force
        Write-Host "Cleaned previous build artifacts" -ForegroundColor Cyan
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
    
    Write-Host "Build Succeeded" -ForegroundColor Green
}
catch {
    Write-Host "Build Failed - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}



try {
    Write-Host "Package" -ForegroundColor Yellow

    Push-Location $projectRoot

    if (-not (Test-Path $publishPath)) {
        throw "Publish directory does not exist"
    }

    if (Test-Path $packagePath) {
        Remove-Item $packagePath -Force
        Write-Host "Cleaned previous package" -ForegroundColor Cyan
    }

    Compress-Archive -Path "$publishPath\*" -DestinationPath $packagePath -Force

    if ($LASTEXITCODE -ne 0) {
        throw "Archiving failed"
    }

    Write-Host "Package Succeeded" -ForegroundColor Green
}
catch {
    Write-Host "Package Failed - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}



try {
    Write-Host "Deploy" -ForegroundColor Yellow

    Push-Location $terraformRoot

    if (-not (Test-Path $packagePath)) {
        throw "Package does not exist"
    }

    $appName = terraform output -raw function_app_name
    $resourceGroupName = terraform output -raw resource_group_name
    $appUrl = terraform output -raw function_app_url

    if (-not $appName -or -not $resourceGroupName) {
        throw "Failed to retrieve function app name or resource group from Terraform outputs"
    }

    $azAccount = az account show 2>$null | ConvertFrom-Json

    if (-not $azAccount) {
        throw "Azure CLI not found or not logged in. Run 'az login' first."
    }

    Write-Host "Stopping app..." -ForegroundColor Cyan
    az functionapp stop --resource-group $resourceGroupName --name $appName --output none

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to stop the app"
    }

    Write-Host "Uploading deployment package..." -ForegroundColor Cyan
    az functionapp deployment source config-zip `
        --resource-group $resourceGroupName `
        --name $appName `
        --src $packagePath `
        --build-remote false `
        --timeout 300

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to upload the deployment package"
    }

    Write-Host "Starting app..." -ForegroundColor Cyan
    az functionapp start --resource-group $resourceGroupName --name $appName --output none

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start the app"
    }

    Write-Host "$appName at: https://$appUrl" -ForegroundColor Cyan

    Write-Host "Checking app status..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5

    $appStatus = az functionapp show --resource-group $resourceGroupName --name $appName --query "state" --output tsv
    if ($appStatus -eq "Running") {
        Write-Host "App is running" -ForegroundColor Green
    }
    else {
        Write-Host "App status: $appStatus" -ForegroundColor Yellow
    }

    Write-Host "Deploy Succeeded" -ForegroundColor Green
}
catch {
    Write-Host "Deploy Failed - $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    Pop-Location
}