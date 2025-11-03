# Deployment Guide - Fabric Auto-Scaling Logic App

## Quick Start Checklist
- [ ] Azure CLI installed and authenticated
- [ ] Resource group created
- [ ] Fabric capacity deployed
- [ ] Email address for notifications ready

## Step-by-Step Deployment

### 1. Prepare Your Environment

#### Install Azure CLI (if not already installed)
**Windows:**
```powershell
winget install Microsoft.AzureCLI
```

**Linux:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**macOS:**
```bash
brew install azure-cli
```

#### Login to Azure
```bash
az login
az account set --subscription "Your-Subscription-Name-or-ID"
```

### 2. Deploy the Logic App

#### Option A: PowerShell (Recommended for Windows)
```powershell
cd Fabric_Auto-Scaling_with_LogicApp

.\Scripts\deploy-logicapp.ps1 `
  -ResourceGroup "rg-fabric-production" `
  -CapacityName "fabriccapacity01" `
  -Email "admin@contoso.com" `
  -Location "eastus" `
  -LogicAppName "FabricAutoScale" `
  -ScaleUpSku "F128" `
  -ScaleDownSku "F64"
```

#### Option B: Bash (Recommended for Linux/Mac)
```bash
cd Fabric_Auto-Scaling_with_LogicApp

./Scripts/deploy-logicapp.sh \
  -g "rg-fabric-production" \
  -c "fabriccapacity01" \
  -e "admin@contoso.com" \
  -l "eastus" \
  -n "FabricAutoScale" \
  -u "F128" \
  -d "F64"
```

**Deployment typically takes 2-3 minutes.**

### 3. Post-Deployment Configuration

After deployment completes, you'll see the Managed Identity Principal ID in the output. **Copy this ID** for the next steps.

#### Step 3.1: Authorize Office 365 Connection

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your resource group
3. Find the API Connection resource (e.g., `office365-FabricAutoScaleLogicApp`)
4. Click on the resource
5. In the left menu, click **Edit API connection**
6. Click the **Authorize** button
7. Sign in with your Office 365 account when prompted
8. Click **Save** at the top

#### Step 3.2: Grant Managed Identity Permissions

The Logic App needs permission to modify the Fabric capacity. Run these commands:

```bash
# Set your variables
RESOURCE_GROUP="rg-fabric-production"
CAPACITY_NAME="fabriccapacity01"
LOGIC_APP_NAME="FabricAutoScale"

# Get the subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get the Managed Identity Principal ID
PRINCIPAL_ID=$(az resource show \
  --resource-group $RESOURCE_GROUP \
  --name $LOGIC_APP_NAME \
  --resource-type Microsoft.Logic/workflows \
  --query identity.principalId -o tsv)

echo "Principal ID: $PRINCIPAL_ID"

# Assign Contributor role to the Fabric capacity
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Fabric/capacities/$CAPACITY_NAME"

echo "✅ Role assignment completed"
```

**PowerShell version:**
```powershell
$RESOURCE_GROUP = "rg-fabric-production"
$CAPACITY_NAME = "fabriccapacity01"
$LOGIC_APP_NAME = "FabricAutoScale"

$SUBSCRIPTION_ID = (az account show --query id -o tsv)
$PRINCIPAL_ID = (az resource show --resource-group $RESOURCE_GROUP --name $LOGIC_APP_NAME --resource-type Microsoft.Logic/workflows --query identity.principalId -o tsv)

Write-Host "Principal ID: $PRINCIPAL_ID"

az role assignment create `
  --assignee $PRINCIPAL_ID `
  --role "Contributor" `
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Fabric/capacities/$CAPACITY_NAME"

Write-Host "✅ Role assignment completed"
```

#### Step 4.3: Enable the Logic App

The Logic App is deployed but may not be running automatically:

1. In Azure Portal, navigate to your Logic App
2. Click on **Overview** in the left menu
3. If the status shows as **Disabled**, click **Enable** at the top
4. The Logic App will now run every 5 minutes

### 5. Verify Deployment

#### Test the Logic App Manually

1. In Azure Portal, open your Logic App
2. Click **Overview** → **Run Trigger** → **Recurrence**
3. Click **Run** to execute immediately
4. Click on the run that appears in **Runs history**
5. Review each action to ensure it completed successfully

#### Check for Notifications

- **Email**: Check your inbox for a notification email (if scaling occurred)

#### Monitor Runs

1. Go to Logic App → **Runs history**
2. Each run should show as **Succeeded** (green checkmark)
3. Click on any run to see detailed execution flow
4. Review any failures and check error messages

### 6. Monitoring and Maintenance

#### View Metrics
```bash
# Check recent Logic App runs
az monitor metrics list \
  --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Logic/workflows/$LOGIC_APP_NAME" \
  --metric "RunsSucceeded" \
  --start-time $(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ') \
  --interval PT5M
```

#### Enable Diagnostic Logging
```bash
# Create Log Analytics workspace (if you don't have one)
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name "law-fabric-autoscale" \
  --location eastus

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name "law-fabric-autoscale" \
  --query id -o tsv)

# Enable diagnostic settings
az monitor diagnostic-settings create \
  --name "LogicAppDiagnostics" \
  --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Logic/workflows/$LOGIC_APP_NAME" \
  --workspace $WORKSPACE_ID \
  --logs '[{"category": "WorkflowRuntime", "enabled": true}]' \
  --metrics '[{"category": "AllMetrics", "enabled": true}]'
```

## Troubleshooting

### Issue: "Deployment failed with error: InvalidTemplate"
**Solution:** Ensure your template file path is correct and the JSON is valid. Run:
```bash
az deployment group validate \
  --resource-group $RESOURCE_GROUP \
  --template-file Templates/fabric-autoscale-template.json
```

### Issue: "Authorization failed for Office 365 connection"
**Solution:** 
1. Go to the API Connection resource in Azure Portal
2. Click "Edit API connection"
3. Re-authorize using your Office 365 credentials
4. Save the connection

### Issue: "Logic App runs but doesn't scale the capacity"
**Solution:**
1. Verify the Managed Identity has Contributor role on the capacity
2. Check that the capacity name matches exactly (case-sensitive)
3. Review the Logic App run history for specific error messages
4. Ensure the capacity is not already at the target SKU

### Issue: "No email notifications received"
**Solution:**
1. Verify the email address is correct
2. Check your spam/junk folder
3. Ensure the Office 365 connection is authorized (see Step 3.1)
4. Review the Logic App run history for the email action status
5. Check if the email action failed with authentication errors

### Issue: "Principal ID not found after deployment"
**Solution:**
Wait 30-60 seconds after deployment, then retry getting the principal ID:
```bash
az resource show \
  --resource-group $RESOURCE_GROUP \
  --name $LOGIC_APP_NAME \
  --resource-type Microsoft.Logic/workflows \
  --query identity.principalId -o tsv
```

## Advanced Configuration

### Adjust Recurrence Interval
Edit the template and change the trigger section:
```json
"triggers": {
  "Recurrence": {
    "type": "Recurrence",
    "recurrence": {
      "frequency": "Minute",
      "interval": 10  // Change from 5 to 10 minutes
    }
  }
}
```

### Add SMS Notifications
You can extend the template to include Twilio or Azure Communication Services for SMS alerts.

### Implement Cool-down Logic
For more sophisticated scenarios, consider using Azure Table Storage to track the last scaling time and implement cool-down periods.

## Clean Up

To remove all deployed resources:
```bash
# Delete the Logic App
az logic workflow delete \
  --resource-group $RESOURCE_GROUP \
  --name $LOGIC_APP_NAME

# Delete the Office 365 connection
az resource delete \
  --resource-group $RESOURCE_GROUP \
  --name "office365-$LOGIC_APP_NAME" \
  --resource-type "Microsoft.Web/connections"

# Or delete the entire resource group (if dedicated to this solution)
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## Next Steps

- Set up Azure Monitor alerts for Logic App failures
- Implement Azure Key Vault for sensitive configuration
- Add Application Insights for detailed telemetry
- Create multiple Logic Apps for different environments (dev/test/prod)
- Implement approval workflows for production scaling events

## Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Submit a pull request
- Contact the repository maintainer
