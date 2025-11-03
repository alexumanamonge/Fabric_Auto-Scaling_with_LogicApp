param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    
    [Parameter(Mandatory=$true)]
    [string]$CapacityName,
    
    [Parameter(Mandatory=$true)]
    [string]$Email,
    
    [string]$Location = "eastus",
    [string]$LogicAppName = "FabricAutoScaleLogicApp",
    [string]$ScaleUpSku = "F128",
    [string]$ScaleDownSku = "F64",
    [int]$ScaleUpThreshold = 80,
    [int]$ScaleDownThreshold = 40
)

# Get the script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateFile = Join-Path (Split-Path -Parent $ScriptDir) "Templates\fabric-autoscale-template.json"

Write-Host "Deploying Logic App for Fabric Auto-Scaling..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Cyan
Write-Host "Capacity Name: $CapacityName" -ForegroundColor Cyan
Write-Host "Template File: $TemplateFile" -ForegroundColor Cyan

# Deploy the ARM template
az deployment group create `
  --resource-group $ResourceGroup `
  --template-file $TemplateFile `
  --parameters `
    logicAppName=$LogicAppName `
    location=$Location `
    fabricCapacityName=$CapacityName `
    notificationEmail=$Email `
    scaleUpSku=$ScaleUpSku `
    scaleDownSku=$ScaleDownSku `
    scaleUpThreshold=$ScaleUpThreshold `
    scaleDownThreshold=$ScaleDownThreshold

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
    Write-Host "`nIMPORTANT: Post-deployment steps:" -ForegroundColor Yellow
    Write-Host "1. Go to the Azure Portal and navigate to the Logic App: $LogicAppName" -ForegroundColor White
    Write-Host "2. Authorize the Office 365 connection under 'API connections'" -ForegroundColor White
    Write-Host "3. Assign 'Contributor' role to the Logic App's Managed Identity on the Fabric capacity resource" -ForegroundColor White
    Write-Host "   Run: az role assignment create --assignee <PRINCIPAL_ID> --role Contributor --scope /subscriptions/<SUB_ID>/resourceGroups/$ResourceGroup/providers/Microsoft.Fabric/capacities/$CapacityName" -ForegroundColor White
    
    # Get the Logic App's principal ID
    $PrincipalId = az resource show --resource-group $ResourceGroup --name $LogicAppName --resource-type Microsoft.Logic/workflows --query identity.principalId -o tsv
    
    if ($PrincipalId) {
        Write-Host "`nLogic App Managed Identity Principal ID: $PrincipalId" -ForegroundColor Cyan
        Write-Host "Use this ID to assign the Contributor role." -ForegroundColor Cyan
    }
} else {
    Write-Host "`nDeployment failed. Please check the error messages above." -ForegroundColor Red
}