# Fabric Auto-Scaling Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Pre-Deployment Setup](#pre-deployment-setup)
3. [Deployment Methods](#deployment-methods)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
- **Azure CLI** 2.50.0 or later ([Install](https://docs.microsoft.com/cli/azure/install-azure-cli))
- **Azure Functions Core Tools** 4.x ([Install](https://docs.microsoft.com/azure/azure-functions/functions-run-local))
- **Python 3.11** (for local testing - optional)
- **PowerShell 7+** (for Windows deployment)
- **Git** (to clone the repository)

### Required Azure Resources
- **Azure Subscription** with active Fabric capacity
- **Microsoft Fabric Capacity** (F2, F4, F8, F16, F32, F64, F128, etc.)
- **Fabric Workspace** with Capacity Metrics App installed
- **Office 365** account for email notifications

### Required Permissions
- **Contributor** or **Owner** role on the Resource Group
- **Fabric Administrator** or workspace access to install Capacity Metrics App
- Ability to grant role assignments on Fabric capacity

---

## Pre-Deployment Setup

### 1. Install Fabric Capacity Metrics App

The solution depends on the **Microsoft Fabric Capacity Metrics App** for accurate utilization data.

1. **Navigate to Your Fabric Workspace**:
   - Go to [Power BI Portal](https://app.powerbi.com) or [Fabric Portal](https://app.fabric.microsoft.com)
   - Select or create a workspace

2. **Install Capacity Metrics App**:
   - In the workspace, click **+ New** → **More options**
   - Search for **"Microsoft Fabric Capacity Metrics"** in AppSource
   - Click **Get it now** and follow installation prompts
   - Configure it to monitor your target Fabric capacity

3. **Note the Workspace ID**:
   - Go to workspace **Settings**
   - Copy the **Workspace ID** (GUID format: `12345678-1234-1234-1234-123456789abc`)
   - You'll need this during deployment

### 2. Prepare Deployment Parameters

Gather the following information:

| Parameter | Example | How to Find |
|-----------|---------|-------------|
| Resource Group Name | `rg-fabric-autoscale` | Create new or use existing |
| Fabric Capacity Name | `MyFabricCapacity` | Azure Portal → Fabric Capacities |
| Workspace ID | `12345678-...` | Workspace Settings |
| Notification Email | `admin@company.com` | Your email address |
| Scale Up SKU | `F128` | Target SKU for scale up |
| Scale Down SKU | `F64` | Target SKU for scale down |
| Location | `eastus` | Azure region (same as capacity) |

### 3. Clone the Repository

```bash
git clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git
cd Fabric_Auto-Scaling_with_LogicApp
```

---

## Deployment Methods

### Method 1: Azure Portal (Deploy to Azure Button)

1. Click **Deploy to Azure** button in README
2. Fill in the deployment form in Azure Portal
3. Click **Review + create** → **Create**
4. After deployment, manually deploy Function App code:
   ```bash
   cd FunctionApp
   func azure functionapp publish <FUNCTION_APP_NAME> --python
   ```

### Method 2: PowerShell Script (Recommended for Windows)

```powershell
# Login to Azure
az login

# Set subscription (if you have multiple)
az account set --subscription "<SUBSCRIPTION_ID>"

# Run deployment script
.\Scripts\deploy-logicapp.ps1 `
  -ResourceGroup "rg-fabric-autoscale" `
  -CapacityName "MyFabricCapacity" `
  -WorkspaceId "12345678-1234-1234-1234-123456789abc" `
  -Email "admin@company.com" `
  -Location "eastus" `
  -ScaleUpSku "F128" `
  -ScaleDownSku "F64" `
  -ScaleUpThreshold 80 `
  -ScaleDownThreshold 40 `
  -SustainedMinutes 15
```

**What the script does**:
1. Deploys ARM template (Function App, Logic App, Storage, App Insights, connections)
2. Attempts to deploy Function App code (requires Azure Functions Core Tools)
3. Displays principal IDs for role assignments
4. Provides post-deployment instructions

### Method 3: Bash Script (Linux/Mac/WSL)

```bash
# Login to Azure
az login

# Set subscription (if you have multiple)
az account set --subscription "<SUBSCRIPTION_ID>"

# Make script executable
chmod +x Scripts/deploy-logicapp.sh

# Run deployment script
./Scripts/deploy-logicapp.sh \
  -g "rg-fabric-autoscale" \
  -c "MyFabricCapacity" \
  -w "12345678-1234-1234-1234-123456789abc" \
  -e "admin@company.com" \
  -l "eastus" \
  -u "F128" \
  -d "F64" \
  -s 15
```

### Method 4: Manual Azure CLI

```bash
# Create resource group (if needed)
az group create \
  --name rg-fabric-autoscale \
  --location eastus

# Deploy ARM template
az deployment group create \
  --resource-group rg-fabric-autoscale \
  --template-file Templates/fabric-autoscale-template.json \
  --parameters \
    fabricCapacityName="MyFabricCapacity" \
    fabricWorkspaceId="12345678-1234-1234-1234-123456789abc" \
    notificationEmail="admin@company.com" \
    scaleUpSku="F128" \
    scaleDownSku="F64" \
    scaleUpThreshold=80 \
    scaleDownThreshold=40 \
    sustainedMinutes=15

# Deploy Function App code
cd FunctionApp
func azure functionapp publish <FUNCTION_APP_NAME> --python
```

---

## Post-Deployment Configuration

After deployment completes, you **must** perform these steps:

### Step 1: Deploy Function App Code

The ARM template creates the Function App infrastructure, but the Python code must be deployed separately.

**Option A: Using Azure Functions Core Tools**
```bash
cd FunctionApp
func azure functionapp publish func-fabricscale-xxxxx --python
```

**Option B: Using VS Code**
1. Install **Azure Functions extension** for VS Code
2. Open `FunctionApp` folder
3. Click **Azure** icon → **Function App** → **Deploy to Function App**
4. Select your Function App

**Option C: Using Azure CLI**
```bash
cd FunctionApp
az functionapp deployment source config-zip \
  --resource-group rg-fabric-autoscale \
  --name func-fabricscale-xxxxx \
  --src FunctionApp.zip
```

**Verify deployment**:
- Go to Azure Portal → Function App → Functions
- You should see `CheckCapacityMetrics` function

### Step 2: Authorize Office 365 Connection

1. Go to **Azure Portal**
2. Navigate to **Resource Groups** → Select your resource group
3. Find the **API Connection** resource (name: `office365-FabricAutoScaleLogicApp`)
4. Click **Edit API connection**
5. Click **Authorize**
6. Sign in with your **Office 365 account**
7. Click **Save**

### Step 3: Assign Permissions to Logic App

The Logic App needs **Contributor** access to scale the Fabric capacity.

**Get Principal ID from deployment output** or run:
```bash
LOGIC_APP_PRINCIPAL_ID=$(az deployment group show \
  --resource-group rg-fabric-autoscale \
  --name fabric-autoscale-template \
  --query properties.outputs.logicAppPrincipalId.value -o tsv)

echo "Logic App Principal ID: $LOGIC_APP_PRINCIPAL_ID"
```

**Assign Contributor role**:
```bash
az role assignment create \
  --assignee $LOGIC_APP_PRINCIPAL_ID \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Fabric/capacities/MyFabricCapacity
```

**Verify assignment**:
```bash
az role assignment list \
  --assignee $LOGIC_APP_PRINCIPAL_ID \
  --output table
```

### Step 4: Assign Permissions to Function App

The Function App needs access to the Fabric workspace to query Capacity Metrics App.

**Get Principal ID**:
```bash
FUNCTION_APP_PRINCIPAL_ID=$(az deployment group show \
  --resource-group rg-fabric-autoscale \
  --name fabric-autoscale-template \
  --query properties.outputs.functionAppPrincipalId.value -o tsv)

echo "Function App Principal ID: $FUNCTION_APP_PRINCIPAL_ID"
```

**Grant workspace access** (choose one method):

**Method A: Via Power BI/Fabric Portal** (Recommended)
1. Go to your Fabric workspace
2. Click **Workspace settings** → **Manage access**
3. Click **+ Add people or groups**
4. Search for the Function App's Managed Identity (use Principal ID)
5. Assign **Viewer** or **Contributor** role
6. Click **Add**

**Method B: Via Power BI Admin Portal**
1. Go to [Power BI Admin Portal](https://app.powerbi.com/admin-portal)
2. Navigate to **Tenant settings** → **Developer settings**
3. Enable **Service principals can access Power BI APIs**
4. Add the Function App Principal ID to allowed list

### Step 5: Enable Logic App

1. Go to **Azure Portal** → **Resource Groups** → **Logic App**
2. Click **Enable** (if not already enabled)
3. Click **Overview** → **Trigger history** to verify it's running

---

## Verification

### 1. Test Function App

Test the Function App directly:

```bash
# Get Function App URL
FUNCTION_APP_NAME="func-fabricscale-xxxxx"

# Call the function (replace with your values)
curl "https://$FUNCTION_APP_NAME.azurewebsites.net/api/CheckCapacityMetrics?code=<FUNCTION_KEY>&capacityName=MyFabricCapacity&workspaceId=12345678-1234-1234-1234-123456789abc&currentSku=F64&scaleUpSku=F128&scaleDownSku=F32"
```

Expected response:
```json
{
  "shouldScaleUp": false,
  "shouldScaleDown": false,
  "currentUtilization": 65.5,
  "sustainedHighCount": 2,
  "metrics": { ... }
}
```

### 2. Check Logic App Run History

1. Go to **Azure Portal** → **Logic App** → **Runs history**
2. Click on the most recent run
3. Verify all actions succeeded
4. Check **Call_Function_Check_Metrics** output

### 3. Monitor Application Insights

1. Go to **Azure Portal** → **Application Insights**
2. Click **Live Metrics** to see real-time function executions
3. Click **Logs** → Run query:
   ```kusto
   traces
   | where timestamp > ago(1h)
   | where message contains "Fabric Auto-Scale"
   | order by timestamp desc
   ```

---

## Troubleshooting

### Issue: Function App deployment fails

**Symptoms**: `func azure functionapp publish` fails with authentication error

**Solutions**:
1. Ensure you're logged in: `az login`
2. Set correct subscription: `az account set --subscription <SUB_ID>`
3. Verify Function App exists: `az functionapp list --resource-group rg-fabric-autoscale`
4. Try deploying via VS Code instead

### Issue: Function returns "Failed to retrieve capacity metrics"

**Symptoms**: Function response has `error: "Failed to retrieve capacity metrics"`

**Solutions**:
1. Verify Capacity Metrics App is installed in the workspace
2. Check Function App Managed Identity has workspace access
3. Verify Workspace ID is correct (GUID format)
4. Check Application Insights logs for detailed error:
   ```bash
   az monitor app-insights query \
     --app <APP_INSIGHTS_NAME> \
     --analytics-query "traces | where message contains 'Error' | take 10"
   ```

### Issue: Logic App fails with "Unauthorized"

**Symptoms**: Logic App run fails at "Scale_Up" or "Scale_Down" action

**Solutions**:
1. Verify Logic App Managed Identity has Contributor role on Fabric capacity
2. Check role assignment:
   ```bash
   az role assignment list --assignee <LOGIC_APP_PRINCIPAL_ID>
   ```
3. Wait 5-10 minutes for role propagation

### Issue: No email notifications received

**Symptoms**: Scaling occurs but no email is sent

**Solutions**:
1. Check Office 365 connection is authorized
2. Verify email address is correct in parameters
3. Check spam/junk folder
4. Review Logic App run history for "Send_Email" action errors

### Issue: Function App shows "Dataset not found"

**Symptoms**: Function logs show Power BI API error about missing dataset

**Solutions**:
1. The Capacity Metrics App dataset may have a different ID
2. Update Function App code to discover the correct dataset:
   ```python
   # List all datasets in workspace
   api_url = f"https://api.powerbi.com/v1.0/myorg/groups/{workspace_id}/datasets"
   ```
3. Redeploy Function App with correct dataset ID

---

## Advanced Configuration

### Custom Thresholds
Edit `fabric-autoscale-template.json` parameters section:
```json
"scaleUpThreshold": {
  "defaultValue": 85  // Changed from 80
},
"scaleDownThreshold": {
  "defaultValue": 30  // Changed from 40
}
```

### Custom Recurrence Interval
Edit Logic App trigger in template:
```json
"Recurrence": {
  "type": "Recurrence",
  "recurrence": {
    "frequency": "Minute",
    "interval": 10  // Changed from 5
  }
}
```

### Enable Application Insights Sampling
Edit `FunctionApp/host.json`:
```json
{
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "maxTelemetryItemsPerSecond": 5  // Reduce costs
      }
    }
  }
}
```

---

## Next Steps

After successful deployment:
1. Monitor Logic App runs for 24 hours
2. Adjust thresholds if needed
3. Review Application Insights for performance
4. Set up alerts for failed runs
5. Document your custom configuration

For more details, see [TESTING-GUIDE.md](TESTING-GUIDE.md).
