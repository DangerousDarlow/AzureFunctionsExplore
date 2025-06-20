Write-Host "Deploying infrastructure with Terraform..." -ForegroundColor Yellow

try {
    if (-not (Test-Path ".terraform")) {
        Write-Host "Initializing Terraform..."
        terraform init
    }
    
    # `terraform plan` erroneously reports changes to `app_settings.AzureWebJobsStorage`
    # and `app_settings.APPLICATIONINSIGHTS_CONNECTION_STRING`. This is a known issue.
    # It could be suppressed by adding these values to `ignore_changes` but this would
    # mean any actual changes would also be ignored.
    Write-Host "Planning Terraform deployment..."
    terraform plan -out=tfplan

    Write-Host "Applying Terraform configuration..."
    terraform apply tfplan
    
    Write-Host "Infrastructure deployed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to deploy infrastructure: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
