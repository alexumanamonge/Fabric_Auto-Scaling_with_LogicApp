# Script to list all datasets in a Power BI workspace
# This helps identify the correct Capacity Metrics dataset ID

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceId
)

Write-Host "Fetching datasets from workspace: $WorkspaceId" -ForegroundColor Cyan

# Install Power BI module if not already installed
if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Write-Host "Installing MicrosoftPowerBIMgmt module..." -ForegroundColor Yellow
    Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser -Force
}

# Import the module
Import-Module MicrosoftPowerBIMgmt

# Connect to Power BI
Write-Host "Connecting to Power BI (browser window will open)..." -ForegroundColor Yellow
Connect-PowerBIServiceAccount

# Get all datasets in the workspace
Write-Host "`nFetching datasets..." -ForegroundColor Yellow
$datasets = Invoke-PowerBIRestMethod -Url "groups/$WorkspaceId/datasets" -Method Get | ConvertFrom-Json

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "Datasets in Workspace" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

foreach ($dataset in $datasets.value) {
    Write-Host "`nDataset Name: $($dataset.name)" -ForegroundColor White
    Write-Host "Dataset ID: $($dataset.id)" -ForegroundColor Green
    Write-Host "Configured By: $($dataset.configuredBy)" -ForegroundColor Gray
    
    if ($dataset.name -like "*Capacity Metrics*") {
        Write-Host "*** THIS IS YOUR CAPACITY METRICS DATASET ***" -ForegroundColor Yellow
        Write-Host "Use this ID for deployment: $($dataset.id)" -ForegroundColor Yellow
    }
    Write-Host "---"
}

Write-Host "`nDone!" -ForegroundColor Green
