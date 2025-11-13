# Fabric Capacity Auto-Scale Solution

Automatic scaling for Microsoft Fabric capacities based on real-time utilization metrics from the Fabric Capacity Metrics App.

## 🎯 What This Does

Automatically scales your Fabric capacity up or down based on sustained CPU utilization:

- **Scales UP** when utilization stays above threshold (default: ≥100%) for a sustained period (default: 5 minutes)
- **Scales DOWN** when utilization stays below threshold (default: ≤45%) for a sustained period (default: 15 minutes)
- **Sends email notifications** for every scaling action
- **Uses 30-second data points** from Capacity Metrics App for precise monitoring

## ✨ Key Features

- ✅ **Visual workflow** - Edit logic in Azure Logic App Designer
- ✅ **Built-in monitoring** - Logic App run history shows every decision
- ✅ **Flexible configuration** - Separate thresholds and timing for scale-up vs scale-down
- ✅ **Real-time metrics** - Queries Capacity Metrics App dataset (30-second granularity)
- ✅ **Cost optimization** - Automatically scales down during low usage

## 📊 How It Works

The Logic App runs on a schedule (default: every 5 minutes) to monitor and scale your Fabric capacity:

1. **Collects metrics** from the Capacity Metrics App dataset (last hour of data at 30-second intervals)
2. **Evaluates utilization** against configured thresholds using separate time windows for scale-up (5 min) and scale-down (15 min)
3. **Scales the capacity** if thresholds are met and sends email notification
4. **Prevents unnecessary scaling** with intelligent logic that prioritizes scale-up over scale-down

**Note**: Capacity Metrics data typically has a 5-6 minute lag, which is normal and factored into the evaluation logic.

## 📋 Prerequisites

### 1. Microsoft Fabric Capacity
- Active Fabric capacity (F2, F4, F8, F16, F32, F64, F128, F256, F512, etc.)
- Know: capacity name, resource group, subscription ID

### 2. Capacity Metrics App (REQUIRED)

**Install and configure the Microsoft Fabric Capacity Metrics app before deploying this solution.**

📖 Follow the official Microsoft documentation to install the app:
- **[Install the Microsoft Fabric Capacity Metrics app](https://learn.microsoft.com/en-us/fabric/enterprise/metrics-app-install)**

**You will need:**
- **Workspace ID**: Found in the Power BI workspace URL: `https://app.powerbi.com/groups/{workspace-id}/...`
- **Dataset ID**: Found in the dataset settings URL: `.../datasets/{dataset-id}/...`
  - Navigate to: Workspace > "Microsoft Fabric Capacity Metrics" dataset > ⋯ > Settings
  - Copy the GUID from the browser URL

**Important**: Wait 24-48 hours after installation for data to populate.

### 3. Azure Subscription
- Contributor access to create resources
- Contributor access to Fabric capacity for scaling

### 4. Office 365 Account
- Email for notifications
- Access to authorize Office 365 connector (post-deployment step)

## 🚀 Quick Start

### Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falexumanamonge%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json)

**Or use PowerShell/CLI** - see [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) for detailed instructions.

### After Deployment (3 Required Steps)

1. **Authorize Office 365 Connection**
   - Azure Portal > Resource Group > `office365-*` connection > Edit API connection > Authorize

2. **Assign Fabric Capacity Permissions**
   - Fabric Capacity > Access control (IAM) > Add > Contributor > Select Logic App managed identity

3. **Grant Power BI Workspace Access**
   - Power BI workspace > Manage access > Add Logic App (use Principal ID) > **Member** role

📖 See [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) for step-by-step instructions.

## 🎛️ Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `fabricCapacityName` | *Required* | Name of your Fabric capacity |
| `fabricResourceGroup` | *Required* | Resource group containing the capacity |
| `fabricWorkspaceId` | *Required* | Workspace ID where Capacity Metrics App is installed |
| `capacityMetricsDatasetId` | *Required* | Dataset ID of Capacity Metrics App |
| `emailRecipient` | *Required* | Email for scaling notifications |
| `scaleUpThreshold` | 100 | CPU % to trigger scale up (0-200) |
| `scaleDownThreshold` | 50 | CPU % to trigger scale down (0-100) |
| `scaleUpSku` | F128 | SKU to scale up to |
| `scaleDownSku` | F64 | SKU to scale down to |
| `scaleUpMinutes` | 5 | Minutes evaluation window for scale-UP (max: 15) |
| `scaleDownMinutes` | 15 | Minutes evaluation window for scale-DOWN (max: 30) |
| `checkIntervalMinutes` | 5 | How often to check metrics (1-30) |

**Note on timing:**
- Data points are collected at 30-second intervals
- `scaleUpMinutes = 5` evaluates last 5 minutes of data (~10 data points)
- `scaleDownMinutes = 15` evaluates last 15 minutes of data (~30 data points)
- Longer scale-down window provides more conservative scaling behavior

### Post-Deployment Parameter Changes

After deployment, you can adjust scaling behavior **without redeploying** by editing parameters in Azure Portal:

**Editable Parameters:**
- `scaleUpThreshold`, `scaleDownThreshold` - Adjust CPU thresholds
- `scaleUpSku`, `scaleDownSku` - Change target SKUs
- `scaleUpMinutes`, `scaleDownMinutes` - Modify evaluation windows

Go to: **Logic App** > **Parameters** > Edit values > **Save**

## 📧 Email Notifications

You'll receive an email for each scaling action with:
- Action taken (SCALED UP / SCALED DOWN)
- Previous and new SKU
- Evaluation window duration (5 or 15 minutes)
- Number of data points evaluated
- Average utilization during the period
- Threshold value that triggered the action
- Cutoff time and newest data point timestamp
- Total data points retrieved

📖 **For known issues, troubleshooting, customization examples, and detailed monitoring instructions**, see [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md).

## 💰 Cost Estimate

**Monthly costs (East US, approximate):**
- Logic App (Consumption): ~$2-4/month (8,640 runs × ~12 actions per run)
- Storage (Standard LRS): ~$0.02/month
- Application Insights: ~$2.88/month (first 5GB free)
- **Total: ~$5-7/month**

**Breakdown:**
- 5-minute intervals = 12 runs/hour × 24 hours × 30 days = 8,640 runs/month
- ~12 actions per run (queries, parsing, conditions, compose, switch) = ~103,000 actions/month
- Logic Apps pricing: $0.000025 per action after first 4,000 free

**Cost optimization:**
- Increase `checkIntervalMinutes` to 10 → halves Logic App costs (~$1-2/month)
- Disable during off-hours → save 60-70%

## 🤝 Contributing

Contributions welcome! Please fork the repository, create a feature branch, and submit a pull request.

---

## 📄 License & Disclaimer

**MIT License** - This solution is provided **as-is** without any warranties or guarantees. Use at your own risk.

The authors and contributors are not responsible for any costs, data loss, service disruptions, or other issues that may arise from using this solution. Always test thoroughly in a non-production environment before deploying to production.

Built for Microsoft Fabric capacity optimization based on real-world enterprise requirements.
