# Fabric Capacity Auto-Scale Solution

Automatic scaling for Microsoft Fabric capacities based on real-time utilization metrics from the Fabric Capacity Metrics App.

## 🎯 What This Does

Automatically scales your Fabric capacity up or down based on sustained CPU utilization:

- **Scales UP** when utilization stays above threshold (default: ≥80%) for a sustained period (default: 5 minutes)
- **Scales DOWN** when utilization stays below threshold (default: ≤30%) for a sustained period (default: 10 minutes)
- **Sends email notifications** for every scaling action
- **Uses 30-second data points** from Capacity Metrics App for precise monitoring
- **Prevents flapping** with separate configurable timing for scale-up and scale-down

## ✨ Key Features

- ✅ **No code deployment** - Pure ARM template, no function deployment packages
- ✅ **Visual workflow** - Edit logic in Azure Logic App Designer
- ✅ **Built-in monitoring** - Logic App run history shows every decision
- ✅ **Flexible configuration** - Separate thresholds and timing for scale-up vs scale-down
- ✅ **Real-time metrics** - Queries Capacity Metrics App dataset (30-second granularity)
- ✅ **Cost optimization** - Automatically scales down during low usage

## 📊 How It Works

The Logic App runs on a schedule (default: every 5 minutes) and follows this workflow:

```
1. Get current capacity SKU
   ↓
2. Query Capacity Metrics dataset for recent utilization (30-sec intervals)
   ↓
3. Count how many data points exceed thresholds
   ↓
4. Scale UP if:
   - ≥ (scaleUpMinutes × 2) data points above scaleUpThreshold
   - Current SKU ≠ target scaleUpSku
   ↓
5. Scale DOWN if:
   - ≥ (scaleDownMinutes × 2) data points below scaleDownThreshold
   - Current SKU ≠ target scaleDownSku
   ↓
6. Send email notification with details
```

**Example with default settings:**
- **Query window**: 20 minutes (scaleDownMinutes × 2 = 10 × 2 = 20 data points)
- **Scale-UP trigger**: 10 consecutive data points above 80% = 5 minutes sustained
- **Scale-DOWN trigger**: 20 consecutive data points below 30% = 10 minutes sustained

This asymmetric design responds quickly to demand while being conservative about scaling down to prevent cost-inefficient flapping.

## 📋 Prerequisites

### 1. Microsoft Fabric Capacity
- Active Fabric capacity (F2, F4, F8, F16, F32, F64, F128, F256, F512, etc.)
- Know: capacity name, resource group, subscription ID

### 2. Capacity Metrics App (REQUIRED)

Install the Microsoft Fabric Capacity Metrics app **before deploying**:

1. Go to your Power BI workspace (or create one)
2. Click **+ New** > **More options** > Search "Microsoft Fabric Capacity Metrics"
3. Install from AppSource and configure for your capacity
4. **Get Workspace ID** from URL: `https://app.powerbi.com/groups/{workspace-id}/...`
5. **Get Dataset ID**:
   - Workspace > "Microsoft Fabric Capacity Metrics" dataset > ⋯ > Settings
   - Copy from URL: `.../datasets/{dataset-id}/...`
6. **Wait 24-48 hours** for data to populate

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
| `scaleUpThreshold` | 80 | CPU % to trigger scale up (0-100) |
| `scaleDownThreshold` | 30 | CPU % to trigger scale down (0-100) |
| `scaleUpSku` | F128 | SKU to scale up to |
| `scaleDownSku` | F64 | SKU to scale down to |
| `scaleUpMinutes` | 5 | Minutes to sustain before scaling UP (max: 15) |
| `scaleDownMinutes` | 10 | Minutes to sustain before scaling DOWN (max: 30) |
| `checkIntervalMinutes` | 5 | How often to check metrics (1-30) |

**Note on timing:**
- Data points are collected at 30-second intervals
- `scaleUpMinutes = 5` means 10 data points must exceed threshold (5 min × 2 points/min)
- `scaleDownMinutes = 10` means 20 data points must be below threshold (10 min × 2 points/min)
- Query retrieves last `scaleDownMinutes × 2` data points to accommodate the longer window

## 📧 Email Notifications

You'll receive an email for each scaling action with:
- Action taken (SCALED UP / SCALED DOWN)
- Previous and new SKU
- Number of threshold violations and time period
- Average utilization during the period
- Threshold value
- Timestamp

� For monitoring details, testing instructions, and troubleshooting, see [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md).

## 💡 Customization Examples

### Different Thresholds for Business Hours

Edit the Logic App to add conditions based on time:
- Scale up aggressively during business hours (70% threshold, 3 min sustained)
- Scale conservatively off-hours (85% threshold, 10 min sustained)

### Multi-Tier Scaling

Add nested conditions to scale to different SKUs based on utilization:
- ≥90% → F256
- ≥80% → F128
- ≥70% → F64

See [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) for customization guidance.

## 💰 Cost Estimate

**Monthly costs (East US):**
- Logic App (Consumption): ~$86/month (5-min intervals)
- Storage (Standard LRS): ~$0.02/month
- Application Insights: ~$2.88/month (first 5GB free)
- **Total: ~$89/month**

**Cost optimization:**
- Increase `checkIntervalMinutes` to 10 → halves costs
- Disable during off-hours → save 60-70%

## 💡 Customization Examples

### Different Thresholds for Business Hours

Edit the Logic App to add conditions based on time:
- Scale up aggressively during business hours (70% threshold, 3 min sustained)
- Scale conservatively off-hours (85% threshold, 10 min sustained)

### Multi-Tier Scaling

Add nested conditions to scale to different SKUs based on utilization:
- ≥90% → F256
- ≥80% → F128
- ≥70% → F64

See [DEPLOYMENT-GUIDE.md](./DEPLOYMENT-GUIDE.md) for customization guidance and troubleshooting.

## 🤝 Contributing

Contributions welcome! Please fork the repository, create a feature branch, and submit a pull request.

---

## � License & Disclaimer

**MIT License** - This solution is provided **as-is** without any warranties or guarantees. Use at your own risk.

The authors and contributors are not responsible for any costs, data loss, service disruptions, or other issues that may arise from using this solution. Always test thoroughly in a non-production environment before deploying to production.

Built for Microsoft Fabric capacity optimization based on real-world enterprise requirements.
