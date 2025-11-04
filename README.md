# Fabric Capacity Auto-Scale Solution

Automatic scaling for Microsoft Fabric capacities based on real-time utilization metrics from the Fabric Capacity Metrics App.

## 🎯 What This Does

This solution automatically scales your Fabric capacity up or down based on sustained CPU utilization patterns:
- **Scales UP** when utilization consistently exceeds your threshold (default: ≥80% for 15 minutes)
- **Scales DOWN** when utilization consistently drops below your threshold (default: ≤30% for 15 minutes)
- **Sends email notifications** for every scaling action
- **Prevents flapping** by requiring at least 3 threshold violations during the sustained period

## 🏗️ Architecture

**Simple, no-code deployment** using Azure Logic Apps:

```
┌─────────────────────────────────────────────────────────────┐
│                    LOGIC APP (Recurrence: 5min)             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 1. Get current Fabric capacity SKU                     │ │
│  │ 2. Query Power BI REST API for metrics (DAX query)     │ │
│  │ 3. Calculate sustained threshold violations            │ │
│  │ 4. Scale capacity if sustained condition met           │ │
│  │ 5. Send email notification                             │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                    │
                    ├──> Power BI REST API (Capacity Metrics App)
                    ├──> Azure Resource Manager (Fabric capacity)
                    └──> Office 365 (Email notifications)
```

**Benefits over Function App approach:**
- ✅ **No code deployment** - everything is ARM template
- ✅ **No storage authentication issues** - no function deployment package
- ✅ **Visual workflow** - edit in Logic App Designer
- ✅ **Built-in monitoring** - Logic App run history
- ✅ **Simpler troubleshooting** - see each action's input/output

## 📋 Prerequisites

### 1. Microsoft Fabric Capacity
- Active Fabric capacity (F2, F4, F8, F16, F32, F64, F128, etc.)
- Know the capacity name, resource group, and subscription ID

### 2. Capacity Metrics App Installation
**⚠️ This is REQUIRED before deployment:**

1. Go to your Power BI workspace (or create a new one)
2. Install the **Microsoft Fabric Capacity Metrics** app:
   - Click **+ New** > **More options**
   - Search for "Microsoft Fabric Capacity Metrics" in AppSource
   - Click **Get it now** and follow installation
3. Configure it to monitor your target Fabric capacity
4. **Note the Workspace ID**: Found in URL: `https://app.powerbi.com/groups/{workspace-id}/...`
5. **Get the Dataset ID**:
   - In the workspace, find the "Microsoft Fabric Capacity Metrics" dataset
   - Click ⋯ (More options) > **Settings**
   - Look at the browser URL: `https://app.powerbi.com/groups/{workspaceId}/settings/datasets/{datasetId}`
   - **Copy the `datasetId`** - you'll need this for deployment
6. **Wait for data**: Metrics may take 24-48 hours to appear after installation

### 3. Azure Subscription
- Contributor access to create resources (Logic App, Storage, App Insights)
- Contributor access to the Fabric capacity resource group (for scaling)

### 4. Office 365 Account
- Email address for receiving scaling notifications
- Ability to authorize the Office 365 connector (post-deployment)

## 🚀 Deployment

### Option 1: One-Click Azure Deployment

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falexumanamonge%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json)

**Note:** Click the button above to deploy directly to your Azure subscription.

### Option 2: PowerShell Deployment

```powershell
# Clone the repository
git clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git
cd Fabric_Auto-Scaling_with_LogicApp/Scripts

# Run deployment script
.\deploy-logicapp.ps1 `
    -ResourceGroupName "rg-fabricautoscale" `
    -FabricCapacityName "my-fabric-capacity" `
    -FabricResourceGroup "rg-fabric-prod" `
    -FabricWorkspaceId "12345678-1234-1234-1234-123456789abc" `
    -CapacityMetricsDatasetId "87654321-4321-4321-4321-210987654321" `
    -EmailRecipient "admin@company.com" `
    -ScaleUpThreshold 80 `
    -ScaleDownThreshold 30 `
    -ScaleUpSku "F128" `
    -ScaleDownSku "F64" `
    -SustainedMinutes 15 `
    -CheckIntervalMinutes 5 `
    -Location "eastus"
```

### Option 3: Azure CLI Deployment

```bash
# Clone the repository
git clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git
cd Fabric_Auto-Scaling_with_LogicApp

# Create resource group
az group create --name rg-fabricautoscale --location eastus

# Deploy template
az deployment group create \
  --resource-group rg-fabricautoscale \
  --template-file Templates/fabric-autoscale-template.json \
  --parameters \
    fabricCapacityName="my-fabric-capacity" \
    fabricResourceGroup="rg-fabric-prod" \
    fabricWorkspaceId="12345678-1234-1234-1234-123456789abc" \
    capacityMetricsDatasetId="87654321-4321-4321-4321-210987654321" \
    emailRecipient="admin@company.com" \
    scaleUpSku="F128" \
    scaleDownSku="F64" \
    scaleUpThreshold=80 \
    scaleDownThreshold=30 \
    sustainedMinutes=15 \
    checkIntervalMinutes=5
```

## ⚙️ Post-Deployment Configuration

After deployment completes, **you must complete these 3 steps**:

### Step 1: Authorize Office 365 Connection

1. Go to **Azure Portal** > Resource Group (where you deployed)
2. Find the **API Connection** resource (named `office365-*`)
3. Click **Edit API connection**
4. Click **Authorize** and sign in with your Office 365 account
5. Click **Save**

### Step 2: Assign Fabric Capacity Permissions

The Logic App needs **Contributor** access to scale the Fabric capacity:

**Option A: Azure Portal**
1. Go to **Azure Portal** > Your Fabric Capacity resource
2. Click **Access control (IAM)** > **+ Add** > **Add role assignment**
3. Select **Contributor** role
4. Click **Next**
5. Click **+ Select members**
6. Search for your Logic App name (e.g., `fabricautoscale-...`)
7. Select it and click **Select**
8. Click **Review + assign**

**Option B: Azure CLI**
```bash
# Get the Logic App's managed identity principal ID from deployment output
PRINCIPAL_ID="<from-deployment-output>"

# Assign Contributor role to the Fabric capacity
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role Contributor \
  --scope /subscriptions/<subscription-id>/resourceGroups/<fabric-rg>/providers/Microsoft.Fabric/capacities/<capacity-name>
```

### Step 3: Grant Power BI Workspace Access

The Logic App needs to query the Capacity Metrics App dataset:

1. Go to **Power BI Service**: https://app.powerbi.com
2. Navigate to your workspace (where Capacity Metrics App is installed)
3. Click **Workspace settings** (gear icon) > **Manage access**
4. Click **+ Add people or groups**
5. Paste the **Logic App's Principal ID** (from deployment output)
6. It will show as the Logic App name
7. Assign at least **Viewer** role
8. Click **Add**

**Alternative: Azure AD Enterprise Application permissions (Optional)**

If your organization requires explicit API permissions:
1. Go to **Azure Portal** > **Azure Active Directory** > **Enterprise Applications**
2. Search for the Logic App's **Principal ID**
3. Click **API permissions** > **Add a permission** > **Power BI Service**
4. Add: `Dataset.Read.All`, `Workspace.Read.All` (Application permissions)
5. Click **Grant admin consent**

## 📊 How It Works

### Sustained Threshold Logic

The solution prevents "flapping" (rapid scaling up/down) by requiring sustained conditions:

1. **Data Collection**: Every 5 minutes (default), queries the last 15 minutes (default) of utilization data
2. **Violation Counting**: Counts how many data points exceed the threshold
3. **Scaling Decision**: Only scales if **≥3 violations** occur during the sustained period
4. **Cooldown**: After scaling, the capacity SKU changes, preventing immediate re-scaling

**Example (Scale Up):**
- Threshold: 80%
- Sustained period: 15 minutes
- Data points collected (5min intervals): 85%, 87%, 82%, 90%
- Violations: 4 out of 4 → **SCALE UP** ✅

**Example (No Action):**
- Threshold: 80%
- Sustained period: 15 minutes
- Data points collected: 75%, 85%, 78%, 81%
- Violations: 2 out of 4 → **NO ACTION** (not sustained)

### DAX Query

The Logic App queries the Capacity Metrics App using DAX:

```dax
EVALUATE 
SUMMARIZECOLUMNS(
    'Timepoint'[Datetime],
    FILTER(
        ALL('Capacities'),
        'Capacities'[Capacity Name] = "your-capacity-name"
        && 'Timepoint'[Datetime] >= DATETIME(2024-01-15, 10:00:00)
        && 'Timepoint'[Datetime] <= DATETIME(2024-01-15, 10:15:00)
    ),
    "Utilization", [Utilization %]
)
ORDER BY 'Timepoint'[Datetime] DESC
```

## 🎛️ Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `fabricCapacityName` | *Required* | Name of your Fabric capacity |
| `fabricResourceGroup` | *Required* | Resource group containing the capacity |
| `fabricWorkspaceId` | *Required* | Workspace ID where Capacity Metrics App is installed |
| `capacityMetricsDatasetId` | *Required* | Dataset ID of Capacity Metrics App - find in Power BI workspace > dataset settings > copy from URL |
| `emailRecipient` | *Required* | Email for scaling notifications |
| `scaleUpThreshold` | 80 | CPU % to trigger scale up (0-100) |
| `scaleDownThreshold` | 30 | CPU % to trigger scale down (0-100) |
| `scaleUpSku` | F128 | SKU to scale up to |
| `scaleDownSku` | F64 | SKU to scale down to |
| `sustainedMinutes` | 15 | Minutes threshold must be sustained (5-60) |
| `checkIntervalMinutes` | 5 | How often to check metrics (1-30) |

## 📧 Email Notifications

You'll receive HTML emails for every scaling action:

**Subject:** `Fabric Capacity Scaled UP - my-capacity`

**Body includes:**
- Action taken (SCALED UP / SCALED DOWN)
- Previous and new SKU
- Trigger details (violation count, sustained period)
- Average utilization during the period
- Threshold value
- Timestamp

## 🔍 Monitoring

### Logic App Run History

1. Go to **Azure Portal** > Logic App > **Overview**
2. Click **Runs history** to see each execution
3. Click on a run to see:
   - Each action's input/output
   - Metrics query results
   - Scaling decisions
   - Email sent confirmation

### Application Insights

The deployment creates an Application Insights resource for advanced monitoring:
- Query execution times
- Success/failure rates
- Custom telemetry

### Troubleshooting

**Issue:** Logic App runs but doesn't scale
- **Check:** Run history for errors in "Query_Capacity_Metrics" action
- **Verify:** Power BI API permissions are granted and consented
- **Verify:** Capacity Metrics App has data (may take 24-48 hours after installation)

**Issue:** Office 365 action fails
- **Check:** Office 365 connection is authorized
- **Verify:** Email recipient address is valid

**Issue:** "Invalid dataset ID" error
- **Check:** Workspace ID is correct
- **Verify:** The dataset ID `CFafbeb4-7a8b-43d7-a3d3-0a8f8c6b0e85` matches your Capacity Metrics App
  - Go to Power BI workspace > Dataset settings > copy the dataset ID
  - Update the Logic App workflow if it's different

## 🛠️ Customization

### Change Scaling Logic

Edit the Logic App in the Azure Portal Designer:
1. Go to Logic App > **Logic app designer**
2. Modify actions:
   - `Check_Scale_Up_Condition`: Change the threshold violation count (default ≥3)
   - `Query_Capacity_Metrics`: Adjust the DAX query
   - Email templates: Customize subject/body

### Add More SKU Tiers

You can configure multiple scale-up tiers by:
1. Adding parameters for additional SKUs (F256, F512, etc.)
2. Adding nested conditions in the scaling logic
3. Checking current SKU and utilization to determine target SKU

Example: Scale to F256 if >90%, F128 if >80%

## 🔒 Security

- **Managed Identity**: No credentials stored; Logic App uses Azure AD identity
- **Storage Account**: Encrypted at rest (TLS 1.2 minimum)
- **API Calls**: All over HTTPS
- **Role-Based Access**: Least-privilege Contributor role only on the specific capacity

## 💰 Cost Estimate

**Monthly costs (East US pricing):**
- Logic App (Consumption): ~$0.01 per run × 8,640 runs/month = **~$86/month**
- Storage (Standard LRS): **~$0.02/month**
- Application Insights: **~$2.88/month** (first 5GB free)
- **Total: ~$89/month**

*Costs may vary by region and usage. Check [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/).*

## 📝 License

MIT License - see LICENSE file

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## 📞 Support

For issues or questions:
- Open an issue on GitHub
- Check the [Troubleshooting section](#troubleshooting)
- Review Logic App run history for detailed error messages

## 🗺️ Roadmap

- [ ] Support for multiple capacities in one deployment
- [ ] Teams notifications (in addition to email)
- [ ] Custom metrics beyond CPU utilization
- [ ] Terraform deployment option
- [ ] Auto-pause capacity during non-business hours
