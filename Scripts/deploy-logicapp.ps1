# Fabric Capacity Auto-Scale Logic App Deployment Script
# This script deploys the auto-scaling Logic App for Fabric capacities
# Architecture: Logic App only - queries Power BI REST API directly, no Function App

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$FabricCapacityName,
    
    [Parameter(Mandatory=$true)]
    [string]$FabricResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$FabricWorkspaceId,
    
    [Parameter(Mandatory=$true)]
    [string]$EmailRecipient,
    
    [Parameter(Mandatory=$false)]
    [string]$FabricSubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [int]$ScaleUpThreshold = 80,
    
    [Parameter(Mandatory=$false)]
    [int]$ScaleDownThreshold = 30,
    
    [Parameter(Mandatory=$false)]
    [string]$ScaleUpSku = "F128",
    
    [Parameter(Mandatory=$false)]
    [string]$ScaleDownSku = "F64",
    
    [Parameter(Mandatory=$false)]
    [int]$SustainedMinutes = 15,
    
    [Parameter(Mandatory=$false)]
    [int]$CheckIntervalMinutes = 5
)

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateFile = Join-Path (Split-Path -Parent $ScriptDir) "Templates\fabric-autoscale-template.json"

# Use current subscription if not specified
if (-not $FabricSubscriptionId) {
    $FabricSubscriptionId = (az account show --query id -o tsv)
}

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "Fabric Auto-Scale Logic App Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Location: $Location" -ForegroundColor White
Write-Host "Fabric Capacity: $FabricCapacityName" -ForegroundColor White
Write-Host "Fabric RG: $FabricResourceGroup" -ForegroundColor White
Write-Host "Workspace ID: $FabricWorkspaceId" -ForegroundColor White
Write-Host "Email: $EmailRecipient" -ForegroundColor White
Write-Host "Scale Up: >=$ScaleUpThreshold% -> $ScaleUpSku" -ForegroundColor Green
Write-Host "Scale Down: <=$ScaleDownThreshold% -> $ScaleDownSku" -ForegroundColor Yellow
Write-Host "Sustained: $SustainedMinutes minutes (min 3 violations)" -ForegroundColor White
Write-Host "Check Interval: $CheckIntervalMinutes minutes" -ForegroundColor White
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if resource group exists
Write-Host "Checking resource group..." -ForegroundColor Yellow
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -eq "false") {
    Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Green
    az group create --name $ResourceGroupName --location $Location
} else {
    Write-Host "Resource group exists: $ResourceGroupName" -ForegroundColor Green
}

# Deploy the ARM template
Write-Host "`nDeploying Azure resources (Logic App, Storage, App Insights, Office 365 connector)..." -ForegroundColor Yellow
$deployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file $TemplateFile `
    --parameters `
        fabricCapacityName=$FabricCapacityName `
        fabricResourceGroup=$FabricResourceGroup `
        fabricSubscriptionId=$FabricSubscriptionId `
        fabricWorkspaceId=$FabricWorkspaceId `
        emailRecipient=$EmailRecipient `
        scaleUpThreshold=$ScaleUpThreshold `
        scaleDownThreshold=$ScaleDownThreshold `
        scaleUpSku=$ScaleUpSku `
        scaleDownSku=$ScaleDownSku `
        sustainedMinutes=$SustainedMinutes `
        checkIntervalMinutes=$CheckIntervalMinutes `
        location=$Location `
    --query 'properties.outputs' `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Deployment successful!" -ForegroundColor Green
    
    # Extract outputs
    $logicAppName = $deployment.logicAppName.value
    $principalId = $deployment.logicAppPrincipalId.value
    $roleCommands = $deployment.roleAssignmentCommands.value
    $nextSteps = $deployment.nextSteps.value
    
    Write-Host "`n=====================================" -ForegroundColor Cyan
    Write-Host "Deployment Outputs" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "Logic App Name: $logicAppName" -ForegroundColor White
    Write-Host "Managed Identity Principal ID: $principalId" -ForegroundColor White
    Write-Host ""
    
    Write-Host "=====================================" -ForegroundColor Yellow
    Write-Host "POST-DEPLOYMENT STEPS (REQUIRED)" -ForegroundColor Yellow
    Write-Host "=====================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. AUTHORIZE OFFICE 365 CONNECTION:" -ForegroundColor Cyan
    Write-Host "   - Go to Azure Portal > Resource Group: $ResourceGroupName" -ForegroundColor White
    Write-Host "   - Find 'office365-*' connection resource" -ForegroundColor White
    Write-Host "   - Click 'Edit API connection'" -ForegroundColor White
    Write-Host "   - Click 'Authorize' and sign in with your Office 365 account" -ForegroundColor White
    Write-Host "   - Click 'Save'" -ForegroundColor White
    Write-Host ""
    
    Write-Host "2. ASSIGN ROLE TO FABRIC CAPACITY:" -ForegroundColor Cyan
    Write-Host "   Run this command:" -ForegroundColor White
    Write-Host "   $roleCommands" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "3. GRANT POWER BI API PERMISSIONS:" -ForegroundColor Cyan
    Write-Host "   - Go to Azure Portal > Azure Active Directory > Enterprise Applications" -ForegroundColor White
    Write-Host "   - Search for Principal ID: $principalId" -ForegroundColor White
    Write-Host "   - Click on the application > Permissions" -ForegroundColor White
    Write-Host "   - Add Power BI Service API permissions:" -ForegroundColor White
    Write-Host "     * Dataset.Read.All" -ForegroundColor Green
    Write-Host "     * Workspace.Read.All" -ForegroundColor Green
    Write-Host "   - Grant admin consent" -ForegroundColor White
    Write-Host ""
    
    Write-Host "4. VERIFY CAPACITY METRICS APP:" -ForegroundColor Cyan
    Write-Host "   - Ensure 'Microsoft Fabric Capacity Metrics' app is installed in workspace: $FabricWorkspaceId" -ForegroundColor White
    Write-Host "   - Verify dataset ID in Logic App if queries fail (CFafbeb4-7a8b-43d7-a3d3-0a8f8c6b0e85)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "Deployment Complete!" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Green
    Write-Host "The Logic App will check capacity metrics every $CheckIntervalMinutes minutes." -ForegroundColor White
    Write-Host "Scaling occurs when threshold violations are sustained for $SustainedMinutes minutes (≥3 violations)." -ForegroundColor White
    Write-Host ""
    
} else {
    Write-Host "`n✗ Deployment failed!" -ForegroundColor Red
    Write-Host "Check the error messages above for details." -ForegroundColor Red
    exit 1
}
