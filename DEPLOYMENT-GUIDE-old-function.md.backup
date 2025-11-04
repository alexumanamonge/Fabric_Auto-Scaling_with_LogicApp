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
- **GitHub Account** - Required to fork the repository
- **Azure CLI** 2.50.0 or later (optional, for command-line deployment)
- **Git** (optional, for local repository management)

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

### 4. Prepare Deployment Parameters

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

---

## Pre-Deployment Setup

### 1. Fork This Repository

**This is a required step before deployment:**

1. **Go to the repository**: https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp
2. **Click the Fork button** at the top right
3. **Select your GitHub account** as the destination
4. **Wait for fork to complete**

> **Why fork?** The Function App downloads code from GitHub during deployment. Forking gives you full control over the code, allows customization, and ensures your deployment won't be affected by changes to the original repository.

### 2. Update ARM Template (In Your Fork)

After forking, update the template to use your fork:

1. **Navigate to your fork** on GitHub
2. **Open** `Templates/fabric-autoscale-template.json`
3. **Click the edit button** (pencil icon)
4. **Find line ~200** with `WEBSITE_RUN_FROM_PACKAGE`
5. **Replace** the URL:
   ```json
   "value": "https://github.com/YOUR-USERNAME/Fabric_Auto-Scaling_with_LogicApp/raw/master/Releases/functionapp.zip"
   ```
   Replace `YOUR-USERNAME` with your actual GitHub username
6. **Commit the change** directly to master

### 3. Install Fabric Capacity Metrics App

## Deployment Methods

### Method 1: Azure Portal - One-Click Deployment (Recommended)

**✨ Fully automated deployment from your fork!**

**Prerequisites:** You must have completed the fork and ARM template update steps above.

Click to deploy (replace `YOUR-USERNAME` with your GitHub username):

```
https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR-USERNAME%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json
```

Or create a custom deploy button in your fork's README:

```markdown
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR-USERNAME%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json)
```

**Fill in the parameters:**
- **Subscription**: Select your Azure subscription
- **Resource Group**: Create new or select existing
- **Region**: Choose same region as your Fabric capacity
- **Fabric Capacity Name**: Enter your capacity name
- **Fabric Workspace ID**: Enter workspace GUID  
- **Notification Email**: Enter your email
- **Scale Up/Down SKUs**: Configure target SKUs
- **Thresholds**: Set utilization percentages

Click **Review + create** → **Create**

**⏱️ Deployment time:** ~3-5 minutes

**What happens automatically:**
- ✅ All Azure resources created
- ✅ Function code downloaded from **your GitHub fork**
- ✅ Managed identity configured
- ✅ All role assignments set up

> **🔒 Security Benefit:** The code runs from your fork, giving you complete control and isolation from the original repository.

---

### Method 2: PowerShell Script (For Automation)

For automated deployment in CI/CD pipelines:

```powershell
# Login to Azure
az login

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

**What the script does:**
- Deploys ARM template with all resources
- Function code automatically downloaded from GitHub

### Method 3: Bash Script (Linux/Mac/Cloud Shell)

```bash
# Login to Azure
az login

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

**What the script does:**
- Deploys ARM template with all resources
- Function code automatically downloaded from GitHub

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
```

Function code is automatically downloaded from GitHub during deployment.

---

## Post-Deployment Configuration

### Step 1: Verify Function App Deployment

Wait 2-3 minutes after ARM deployment completes, then verify the function was deployed:

```bash
# List functions
az functionapp function list \
  --resource-group rg-fabric-autoscale \
  --name func-fabricscale-xxxxx \
  --query "[].name" -o table
```

You should see `CheckCapacityMetrics` in the list.

**If the function is not showing:**
1. Wait another 2-3 minutes for automatic download and deployment
2. Check the Function App logs in Azure Portal
3. Restart the Function App:
   ```bash
   az functionapp restart --resource-group rg-fabric-autoscale --name func-fabricscale-xxxxx
   ```

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

> **✅ Storage Authentication**: The Function App uses **managed identity** for storage access. The ARM template automatically assigns the required roles (Storage Blob Data Owner, Storage Queue Data Contributor, Storage Table Data Contributor). Function code is deployed via `WEBSITE_RUN_FROM_PACKAGE` from your storage account.

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

### Issue: Function App not showing after deployment

**Symptoms**: Function App exists but no functions are listed

**Solutions**:
1. Wait 2-3 minutes for automatic deployment from GitHub to complete
2. Check Function App configuration has `WEBSITE_RUN_FROM_PACKAGE` setting:
   ```bash
   az functionapp config appsettings list \
     --resource-group rg-fabric-autoscale \
     --name func-fabricscale-xxxxx \
     --query "[?name=='WEBSITE_RUN_FROM_PACKAGE']"
   ```
3. Restart the Function App:
   ```bash
   az functionapp restart --resource-group rg-fabric-autoscale --name func-fabricscale-xxxxx
   ```
4. Check Application Insights for deployment errors

### Issue: Storage account access errors during deployment

**Symptoms**: ARM deployment fails with "Creation of storage file share failed with: '(403) Forbidden'"

**Solutions**:
1. Template uses **managed identity authentication** - no storage keys needed
2. Verify no Azure policies are blocking role assignments
3. Ensure `allowSharedKeyAccess` is not disabled by subscription policy
4. If issue persists, delete partially created resources and redeploy

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
1. Verify Capacity Metrics App is properly installed and configured
2. The dataset ID may be different - check in Power BI workspace
3. Grant Function App Managed Identity access to the workspace
4. Check Function App logs in Application Insights for specific error details

### Issue: Want to update Function App code

**Symptoms**: Need to deploy new version of Python code

**Solutions**:

**Option 1: Update via GitHub (Recommended)**
1. Update code in the `FunctionApp` folder
2. Create new zip: `Compress-Archive -Path FunctionApp\* -DestinationPath Releases\functionapp.zip -Force`
3. Commit and push to GitHub
4. Restart Function App (it will pull latest code automatically)

**Option 2: Manual Package Upload**
1. Create zip of FunctionApp folder
2. Upload to Azure Blob Storage
3. Generate SAS token
4. Update Function App setting:
   ```bash
   az functionapp config appsettings set \
     --resource-group rg-fabric-autoscale \
     --name func-fabricscale-xxxxx \
     --settings "WEBSITE_RUN_FROM_PACKAGE=<YOUR_BLOB_URL_WITH_SAS>"
   ```

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
