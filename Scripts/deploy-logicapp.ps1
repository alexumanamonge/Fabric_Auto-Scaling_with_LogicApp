param(param(param(

    [Parameter(Mandatory=$true)]

    [string]$ResourceGroup,    [Parameter(Mandatory=$true)]    [Parameter(Mandatory=$true)]

    

    [Parameter(Mandatory=$true)]    [string]$ResourceGroup,    [string]$ResourceGroup,

    [string]$CapacityName,

            

    [Parameter(Mandatory=$true)]

    [string]$Email,    [Parameter(Mandatory=$true)]    [Parameter(Mandatory=$true)]

    

    [Parameter(Mandatory=$true)]    [string]$CapacityName,    [string]$CapacityName,

    [string]$WorkspaceId,

            

    [string]$Location = "eastus",

    [string]$LogicAppName = "FabricAutoScaleLogicApp",    [Parameter(Mandatory=$true)]    [Parameter(Mandatory=$true)]

    [string]$ScaleUpSku = "F128",

    [string]$ScaleDownSku = "F64",    [string]$Email,    [string]$Email,

    [int]$ScaleUpThreshold = 80,

    [int]$ScaleDownThreshold = 40,        

    [int]$SustainedMinutes = 15

)    [Parameter(Mandatory=$true)]    [string]$Location = "eastus",



# Get the script directory    [string]$WorkspaceId,    [string]$LogicAppName = "FabricAutoScaleLogicApp",

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$TemplateFile = Join-Path (Split-Path -Parent $ScriptDir) "Templates\fabric-autoscale-template.json"        [string]$ScaleUpSku = "F128",

$FunctionAppDir = Join-Path (Split-Path -Parent $ScriptDir) "FunctionApp"

    [string]$Location = "eastus",    [string]$ScaleDownSku = "F64",

Write-Host "Deploying Fabric Auto-Scaling Solution..." -ForegroundColor Green

Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Cyan    [string]$LogicAppName = "FabricAutoScaleLogicApp",    [int]$ScaleUpThreshold = 80,

Write-Host "Capacity Name: $CapacityName" -ForegroundColor Cyan

Write-Host "Workspace ID: $WorkspaceId" -ForegroundColor Cyan    [string]$ScaleUpSku = "F128",    [int]$ScaleDownThreshold = 40

Write-Host "Template File: $TemplateFile" -ForegroundColor Cyan

    [string]$ScaleDownSku = "F64",)

# Deploy the ARM template

Write-Host "`nDeploying Azure resources (Function App, Logic App, connections)..." -ForegroundColor Yellow    [int]$ScaleUpThreshold = 80,

az deployment group create `

  --resource-group $ResourceGroup `    [int]$ScaleDownThreshold = 40,# Get the script directory

  --template-file $TemplateFile `

  --parameters `    [int]$SustainedMinutes = 15$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

    logicAppName=$LogicAppName `

    location=$Location `)$TemplateFile = Join-Path (Split-Path -Parent $ScriptDir) "Templates\fabric-autoscale-template.json"

    fabricCapacityName=$CapacityName `

    fabricWorkspaceId=$WorkspaceId `

    notificationEmail=$Email `

    scaleUpSku=$ScaleUpSku `# Get the script directoryWrite-Host "Deploying Logic App for Fabric Auto-Scaling..." -ForegroundColor Green

    scaleDownSku=$ScaleDownSku `

    scaleUpThreshold=$ScaleUpThreshold `$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.PathWrite-Host "Resource Group: $ResourceGroup" -ForegroundColor Cyan

    scaleDownThreshold=$ScaleDownThreshold `

    sustainedMinutes=$SustainedMinutes$TemplateFile = Join-Path (Split-Path -Parent $ScriptDir) "Templates\fabric-autoscale-template.json"Write-Host "Capacity Name: $CapacityName" -ForegroundColor Cyan



if ($LASTEXITCODE -ne 0) {$FunctionAppDir = Join-Path (Split-Path -Parent $ScriptDir) "FunctionApp"Write-Host "Template File: $TemplateFile" -ForegroundColor Cyan

    Write-Host "`nARM template deployment failed. Please check the error messages above." -ForegroundColor Red

    exit 1

}

Write-Host "Deploying Fabric Auto-Scaling Solution..." -ForegroundColor Green# Deploy the ARM template

Write-Host "`nARM template deployment completed successfully!" -ForegroundColor Green

Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Cyanaz deployment group create `

# Get deployment outputs

$DeploymentName = (Get-ChildItem $TemplateFile).BaseNameWrite-Host "Capacity Name: $CapacityName" -ForegroundColor Cyan  --resource-group $ResourceGroup `

$FunctionAppName = az deployment group show --resource-group $ResourceGroup --name $DeploymentName --query properties.outputs.functionAppName.value -o tsv

$LogicAppPrincipalId = az deployment group show --resource-group $ResourceGroup --name $DeploymentName --query properties.outputs.logicAppPrincipalId.value -o tsvWrite-Host "Workspace ID: $WorkspaceId" -ForegroundColor Cyan  --template-file $TemplateFile `

$FunctionAppPrincipalId = az deployment group show --resource-group $ResourceGroup --name $DeploymentName --query properties.outputs.functionAppPrincipalId.value -o tsv

Write-Host "Template File: $TemplateFile" -ForegroundColor Cyan  --parameters `

# Deploy Function App code

Write-Host "`nDeploying Function App code..." -ForegroundColor Yellow    logicAppName=$LogicAppName `

if (Test-Path $FunctionAppDir) {

    # Check if Azure Functions Core Tools is installed# Deploy the ARM template    location=$Location `

    $funcInstalled = Get-Command func -ErrorAction SilentlyContinue

    if ($funcInstalled) {Write-Host "`nDeploying Azure resources (Function App, Logic App, connections)..." -ForegroundColor Yellow    fabricCapacityName=$CapacityName `

        Push-Location $FunctionAppDir

        func azure functionapp publish $FunctionAppName --pythonaz deployment group create `    notificationEmail=$Email `

        Pop-Location

          --resource-group $ResourceGroup `    scaleUpSku=$ScaleUpSku `

        if ($LASTEXITCODE -eq 0) {

            Write-Host "Function App code deployed successfully!" -ForegroundColor Green  --template-file $TemplateFile `    scaleDownSku=$ScaleDownSku `

        } else {

            Write-Host "Function App code deployment failed. You may need to deploy it manually." -ForegroundColor Yellow  --parameters `    scaleUpThreshold=$ScaleUpThreshold `

        }

    } else {    logicAppName=$LogicAppName `    scaleDownThreshold=$ScaleDownThreshold

        Write-Host "Azure Functions Core Tools not found. Please install it to deploy Function App code." -ForegroundColor Yellow

        Write-Host "Install from: https://docs.microsoft.com/azure/azure-functions/functions-run-local" -ForegroundColor Gray    location=$Location `

    }

} else {    fabricCapacityName=$CapacityName `if ($LASTEXITCODE -eq 0) {

    Write-Host "Function App directory not found: $FunctionAppDir" -ForegroundColor Yellow

    Write-Host "Please deploy the Function App code manually." -ForegroundColor Yellow    fabricWorkspaceId=$WorkspaceId `    Write-Host "`nDeployment completed successfully!" -ForegroundColor Green

}

    notificationEmail=$Email `    Write-Host "`nIMPORTANT: Post-deployment steps:" -ForegroundColor Yellow

Write-Host "`n========================================" -ForegroundColor Green

Write-Host "DEPLOYMENT COMPLETED!" -ForegroundColor Green    scaleUpSku=$ScaleUpSku `    Write-Host "1. Go to the Azure Portal and navigate to the Logic App: $LogicAppName" -ForegroundColor White

Write-Host "========================================" -ForegroundColor Green

    scaleDownSku=$ScaleDownSku `    Write-Host "2. Authorize the Office 365 connection under 'API connections'" -ForegroundColor White

Write-Host "`nIMPORTANT: Post-deployment steps:" -ForegroundColor Yellow

Write-Host "`n1. AUTHORIZE OFFICE 365 CONNECTION" -ForegroundColor White    scaleUpThreshold=$ScaleUpThreshold `    Write-Host "3. Assign 'Contributor' role to the Logic App's Managed Identity on the Fabric capacity resource" -ForegroundColor White

Write-Host "   - Go to Azure Portal > Resource Groups > $ResourceGroup" -ForegroundColor Gray

Write-Host "   - Find the API Connection resource (office365-$LogicAppName)" -ForegroundColor Gray    scaleDownThreshold=$ScaleDownThreshold `    Write-Host "   Run: az role assignment create --assignee <PRINCIPAL_ID> --role Contributor --scope /subscriptions/<SUB_ID>/resourceGroups/$ResourceGroup/providers/Microsoft.Fabric/capacities/$CapacityName" -ForegroundColor White

Write-Host "   - Click 'Edit API connection' > 'Authorize' > Sign in with your Office 365 account" -ForegroundColor Gray

    sustainedMinutes=$SustainedMinutes    

Write-Host "`n2. ASSIGN PERMISSIONS TO LOGIC APP" -ForegroundColor White

Write-Host "   Principal ID: $LogicAppPrincipalId" -ForegroundColor Cyan    # Get the Logic App's principal ID

Write-Host "   Run this command:" -ForegroundColor Gray

$SubscriptionId = az account show --query id -o tsvif ($LASTEXITCODE -ne 0) {    $PrincipalId = az resource show --resource-group $ResourceGroup --name $LogicAppName --resource-type Microsoft.Logic/workflows --query identity.principalId -o tsv

Write-Host "   az role assignment create --assignee $LogicAppPrincipalId --role Contributor --scope /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Fabric/capacities/$CapacityName" -ForegroundColor Gray

    Write-Host "`nARM template deployment failed. Please check the error messages above." -ForegroundColor Red    

Write-Host "`n3. ASSIGN PERMISSIONS TO FUNCTION APP" -ForegroundColor White

Write-Host "   Principal ID: $FunctionAppPrincipalId" -ForegroundColor Cyan    exit 1    if ($PrincipalId) {

Write-Host "   The Function App needs:" -ForegroundColor Gray

Write-Host "   - Reader access to Fabric workspace containing Capacity Metrics App" -ForegroundColor Gray}        Write-Host "`nLogic App Managed Identity Principal ID: $PrincipalId" -ForegroundColor Cyan

Write-Host "   - You may need to grant access via Power BI Admin Portal or Fabric workspace settings" -ForegroundColor Gray

        Write-Host "Use this ID to assign the Contributor role." -ForegroundColor Cyan

Write-Host "`n4. INSTALL FABRIC CAPACITY METRICS APP" -ForegroundColor White

Write-Host "   - Go to your Fabric workspace (ID: $WorkspaceId)" -ForegroundColor GrayWrite-Host "`nARM template deployment completed successfully!" -ForegroundColor Green    }

Write-Host "   - Install the Microsoft Fabric Capacity Metrics App from AppSource" -ForegroundColor Gray

Write-Host "   - Configure it to track your capacity: $CapacityName" -ForegroundColor Gray} else {



Write-Host "`nDeployment summary saved. Enjoy your auto-scaling solution! 🚀" -ForegroundColor Green# Get deployment outputs    Write-Host "`nDeployment failed. Please check the error messages above." -ForegroundColor Red


$DeploymentName = (Get-ChildItem $TemplateFile).BaseName}
$FunctionAppName = az deployment group show --resource-group $ResourceGroup --name $DeploymentName --query properties.outputs.functionAppName.value -o tsv
$LogicAppPrincipalId = az deployment group show --resource-group $ResourceGroup --name $DeploymentName --query properties.outputs.logicAppPrincipalId.value -o tsv
$FunctionAppPrincipalId = az deployment group show --resource-group $ResourceGroup --name $DeploymentName --query properties.outputs.functionAppPrincipalId.value -o tsv

# Deploy Function App code
Write-Host "`nDeploying Function App code..." -ForegroundColor Yellow
if (Test-Path $FunctionAppDir) {
    # Check if Azure Functions Core Tools is installed
    $funcInstalled = Get-Command func -ErrorAction SilentlyContinue
    if ($funcInstalled) {
        Push-Location $FunctionAppDir
        func azure functionapp publish $FunctionAppName --python
        Pop-Location
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Function App code deployed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Function App code deployment failed. You may need to deploy it manually." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Azure Functions Core Tools not found. Please install it to deploy Function App code." -ForegroundColor Yellow
        Write-Host "Install from: https://docs.microsoft.com/azure/azure-functions/functions-run-local" -ForegroundColor Gray
    }
} else {
    Write-Host "Function App directory not found: $FunctionAppDir" -ForegroundColor Yellow
    Write-Host "Please deploy the Function App code manually." -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nIMPORTANT: Post-deployment steps:" -ForegroundColor Yellow
Write-Host "`n1. AUTHORIZE OFFICE 365 CONNECTION" -ForegroundColor White
Write-Host "   - Go to Azure Portal > Resource Groups > $ResourceGroup" -ForegroundColor Gray
Write-Host "   - Find the API Connection resource (office365-$LogicAppName)" -ForegroundColor Gray
Write-Host "   - Click 'Edit API connection' > 'Authorize' > Sign in with your Office 365 account" -ForegroundColor Gray

Write-Host "`n2. ASSIGN PERMISSIONS TO LOGIC APP" -ForegroundColor White
Write-Host "   Principal ID: $LogicAppPrincipalId" -ForegroundColor Cyan
Write-Host "   Run this command:" -ForegroundColor Gray
$SubscriptionId = az account show --query id -o tsv
Write-Host "   az role assignment create --assignee $LogicAppPrincipalId --role Contributor --scope /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Fabric/capacities/$CapacityName" -ForegroundColor Gray

Write-Host "`n3. ASSIGN PERMISSIONS TO FUNCTION APP" -ForegroundColor White
Write-Host "   Principal ID: $FunctionAppPrincipalId" -ForegroundColor Cyan
Write-Host "   The Function App needs:" -ForegroundColor Gray
Write-Host "   - Reader access to Fabric workspace containing Capacity Metrics App" -ForegroundColor Gray
Write-Host "   - You may need to grant access via Power BI Admin Portal or Fabric workspace settings" -ForegroundColor Gray

Write-Host "`n4. INSTALL FABRIC CAPACITY METRICS APP" -ForegroundColor White
Write-Host "   - Go to your Fabric workspace (ID: $WorkspaceId)" -ForegroundColor Gray
Write-Host "   - Install the Microsoft Fabric Capacity Metrics App from AppSource" -ForegroundColor Gray
Write-Host "   - Configure it to track your capacity: $CapacityName" -ForegroundColor Gray

Write-Host "`nDeployment summary saved. Enjoy your auto-scaling solution! 🚀" -ForegroundColor Green
