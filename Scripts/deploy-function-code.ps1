param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName
)

Write-Host "Deploying Function App code using Kudu API..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Cyan
Write-Host "Function App: $FunctionAppName" -ForegroundColor Cyan

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FunctionAppDir = Join-Path (Split-Path -Parent $ScriptDir) "FunctionApp"
$ZipPath = Join-Path (Split-Path -Parent $ScriptDir) "functionapp.zip"

# Create zip file
Write-Host "`nCreating deployment package..." -ForegroundColor Yellow
if (Test-Path $ZipPath) {
    Remove-Item $ZipPath -Force
}

Compress-Archive -Path "$FunctionAppDir\*" -DestinationPath $ZipPath -Force
Write-Host "Package created: $ZipPath" -ForegroundColor Green

# Get publishing credentials
Write-Host "`nRetrieving publishing credentials..." -ForegroundColor Yellow
$creds = az functionapp deployment list-publishing-credentials `
    --resource-group $ResourceGroup `
    --name $FunctionAppName `
    --query "{username:publishingUserName, password:publishingPassword}" -o json | ConvertFrom-Json

if (-not $creds) {
    Write-Host "Failed to retrieve publishing credentials" -ForegroundColor Red
    exit 1
}

# Deploy using Kudu API
Write-Host "`nDeploying to Function App..." -ForegroundColor Yellow
$kuduUrl = "https://$FunctionAppName.scm.azurewebsites.net/api/zipdeploy"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($creds.username):$($creds.password)"))

try {
    $response = Invoke-RestMethod -Uri $kuduUrl `
        -Method Post `
        -InFile $ZipPath `
        -Headers @{
            Authorization = "Basic $base64AuthInfo"
        } `
        -ContentType "application/zip" `
        -TimeoutSec 300

    Write-Host "`n✅ Deployment successful!" -ForegroundColor Green
} catch {
    Write-Host "`n❌ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verify deployment
Write-Host "`nVerifying deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$functions = az functionapp function list `
    --resource-group $ResourceGroup `
    --name $FunctionAppName `
    --query "[].name" -o tsv

if ($functions -match "CheckCapacityMetrics") {
    Write-Host "✅ Function 'CheckCapacityMetrics' deployed successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Warning: Function not found. Please verify in Azure Portal." -ForegroundColor Yellow
}

# Cleanup
Remove-Item $ZipPath -Force
Write-Host "`nDeployment completed!" -ForegroundColor Green
Write-Host "You can view your function at: https://$FunctionAppName.azurewebsites.net" -ForegroundColor Cyan
