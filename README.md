# Fabric Capacity Auto-Scale Solution

Automatic scaling for Microsoft Fabric capacities based on real-time utilization metrics from the Fabric Capacity Metrics App.

## 🎯 What This Does

This solution automatically scales your Fabric capacity up or down based on sustained CPU utilization patterns:
- **Scales UP** when utilization consistently exceeds your threshold for **5 minutes** (default: ≥80%)
- **Scales DOWN** when utilization consistently drops below your threshold for **10 minutes** (default: ≤30%)
- **Sends email notifications** for every scaling action
- **Uses 30-second data points** from the Capacity Metrics App for precise monitoring
- **Prevents flapping** with asymmetric timing (quick scale-up, conservative scale-down)

## 🏗️ Architecture

**Simple, no-code deployment** using Azure Logic Apps:

```
┌─────────────────────────────────────────────────────────────┐
│                    LOGIC APP (Recurrence: 5min)             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ 1. Get current Fabric capacity SKU                     │ │
│  │ 2. Query Capacity Metrics dataset (30-sec intervals)   │ │
│  │ 3. Count threshold violations in last 20 minutes       │ │
│  │ 4. Scale UP if ≥10 violations (5 min sustained)        │ │
│  │ 5. Scale DOWN if ≥20 violations (10 min sustained)     │ │
│  │ 6. Send email notification on scaling                  │ │
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
    -SustainedMinutes 5 `
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
    sustainedMinutes=5 \
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

The Logic App needs **Member** access to query the Capacity Metrics App dataset:

1. Go to **Power BI Service**: https://app.powerbi.com
2. Navigate to your workspace (where Capacity Metrics App is installed)
3. Click **Workspace settings** (gear icon) > **Manage access**
4. Click **+ Add people or groups**
5. Paste the **Logic App's Principal ID** (from deployment output)
6. It will show as the Logic App name
7. Assign **Member** role (Viewer is insufficient for DAX queries)
8. Click **Add**

> **Important**: The Logic App requires **Member** role to execute DAX queries via the Power BI REST API. Viewer access will result in authorization errors.

**Alternative: Azure AD Enterprise Application permissions (Optional)**

If your organization requires explicit API permissions:
1. Go to **Azure Portal** > **Azure Active Directory** > **Enterprise Applications**
2. Search for the Logic App's **Principal ID**
3. Click **API permissions** > **Add a permission** > **Power BI Service**
4. Add: `Dataset.Read.All`, `Workspace.Read.All` (Application permissions)
5. Click **Grant admin consent**

## 📊 How It Works

### Sustained Threshold Logic

The solution prevents "flapping" (rapid scaling up/down) by using asymmetric timing:

1. **Data Collection**: Every 5 minutes (default), queries the last 20 minutes of utilization data from the Capacity Metrics App (30-second intervals = 40 data points)
2. **Violation Counting**: Counts how many data points exceed the threshold
3. **Scale-UP Decision**: Scales up if **≥10 data points** (5 minutes sustained) are above the upper threshold
4. **Scale-DOWN Decision**: Scales down if **≥20 data points** (10 minutes sustained) are below the lower threshold
5. **Cooldown**: After scaling, the capacity SKU changes, preventing immediate re-scaling

**Example (Scale Up):**
- Upper Threshold: 80%
- Data points needed: 10 consecutive points above threshold (5 minutes)
- Data collected (last 20 min): 40 points at 30-second intervals
- Last 5 minutes show: 82%, 85%, 87%, 84%, 83%, 88%, 86%, 85%, 84%, 87% (10 points)
- Result: **SCALE UP** ✅

**Example (Scale Down):**
- Lower Threshold: 30%
- Data points needed: 20 consecutive points below threshold (10 minutes)
- Data collected (last 20 min): 40 points at 30-second intervals
- Last 10 minutes show: 28%, 25%, 27%, 26%, 24%, 28%, 29%, 27%, 26%, 25%, 28%, 27%, 26%, 25%, 24%, 28%, 27%, 26%, 25%, 24% (20 points)
- Result: **SCALE DOWN** ✅

**Example (No Action):**
- Upper Threshold: 80%
- Data collected: 75%, 85%, 78%, 82%, 76%, 88%, 74%, 81%, 79%, 77%
- Violations: Only 4 points above threshold → **NO ACTION** (not sustained for 5 minutes)

### DAX Query

The Logic App queries the "Usage Summary (Last 1 hour)" table from the Capacity Metrics App:

```dax
EVALUATE 
TOPN(
    40, 
    'Usage Summary (Last 1 hour)', 
    'Usage Summary (Last 1 hour)'[Timestamp], 
    DESC
)
```

This returns the last 40 data points (20 minutes) with 30-second granularity, including:
- `Timestamp`: Date/time of the measurement
- `Average CU %`: Capacity utilization percentage (0-100)

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
| `sustainedMinutes` | 5 | Minutes threshold must be sustained for scale-UP (1-15). Scale-DOWN uses 2x this value (10 min default) |
| `checkIntervalMinutes` | 5 | How often to check metrics (1-30) |

> **Note**: The `sustainedMinutes` parameter controls scale-UP timing. Scale-DOWN automatically requires twice as long (asymmetric scaling to prevent flapping).

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
- **Verify:** The dataset ID matches your Capacity Metrics App dataset ID (found in Power BI workspace > dataset settings > URL)
- **Note:** Dataset ID is unique to each Capacity Metrics App installation

**Issue:** "PowerBIEntityNotFound" or authorization errors
- **Check:** Logic App has **Member** role in the Power BI workspace (not just Viewer)
- **Verify:** Workspace access was granted to the Logic App's managed identity using its Principal ID
  - Go to Power BI workspace > Dataset settings > copy the dataset ID
  - Update the Logic App workflow if it's different

## 🛠️ Customization

### Change Scaling Logic

Edit the Logic App in the Azure Portal Designer:
1. Go to Logic App > **Logic app designer**
2. Modify actions:
   - `Check_Scale_Up_Condition`: Change the data point count threshold (default ≥10 for 5 minutes)
   - `Check_Scale_Down_Condition`: Change the data point count threshold (default ≥20 for 10 minutes)
   - `Query_Capacity_Metrics`: Adjust the TOPN count (default 40 = 20 minutes of data)
   - Email templates: Customize subject/body

### Adjust Timing Windows

To change the sustained threshold windows:
1. Modify the `sustainedMinutes` parameter (controls scale-UP, default 5)
2. Scale-DOWN automatically uses 2x this value (10 minutes when sustainedMinutes=5)
3. Update the TOPN query count to match: 
   - Formula: `TOPN count = (scale-DOWN minutes × 2)` (e.g., 10 min × 2 = 40 data points)

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
