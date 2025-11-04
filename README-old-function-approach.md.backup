# Microsoft Fabric Auto-Scaling with Azure Logic Apps and Functions

Automated scaling for Microsoft Fabric capacity based on real-time utilization metrics using Azure Functions and Logic Apps.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falexumanamonge%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json)

---

## Overview

This solution automatically scales your Microsoft Fabric capacity up or down based on sustained CU utilization patterns. It leverages a **Python Azure Function** to intelligently query the **Fabric Capacity Metrics App** for real-time usage data, and an **Azure Logic App** to orchestrate scaling actions with email notifications.

The architecture ensures that scaling only occurs when utilization thresholds are sustained over time (default: 15 minutes), preventing costly reactions to temporary spikes.

---


## Key Features

- 🚀 **True One-Click Deployment**: Infrastructure AND code deployed automatically via Azure Deployment Scripts - zero manual steps

- 🎯 **Intelligent Sustained Threshold Detection**: Only scales when utilization stays above/below thresholds for a configurable duration

- 📊 **Native Fabric Metrics Integration**: Queries official Fabric Capacity Metrics App via Power BI REST API

- 🔐 **Enterprise-Grade Security**: Azure AD authentication on Function App, Managed Identity for all resource access (no secrets to manage)

- 📧 **Rich Email Notifications**: Detailed alerts with utilization metrics and SKU changes

- ⚙️ **Fully Configurable**: Customize thresholds, SKUs, sustained duration, and recurrence intervals

- 📈 **Built-in Monitoring**: Application Insights integration for complete telemetry

---

## Deployment

### 📋 Step 1: Fork This Repository

**Before deploying, fork this repository to your GitHub account:**

1. Click the **Fork** button at the top right of this page
2. Select your GitHub account as the destination
3. Wait for the fork to complete

> **Why fork?** This ensures you have full control over the code and deployment. You can customize the function code, update dependencies, and manage your own release cycle.

### 🚀 Step 2: Update ARM Template (In Your Fork)

After forking, update the function package URL to point to your fork:

1. Open `Templates/fabric-autoscale-template.json` in your fork
2. Find line ~200 with `WEBSITE_RUN_FROM_PACKAGE`
3. Replace the URL with your fork:
   ```json
   "value": "https://github.com/YOUR-USERNAME/Fabric_Auto-Scaling_with_LogicApp/raw/master/Releases/functionapp.zip"
   ```
4. Commit the change

### ✨ Step 3: Deploy to Azure (One-Click)

Now deploy from **your forked repository**:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FYOUR-USERNAME%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json)

> **Important:** Replace `YOUR-USERNAME` in the deploy button URL above with your GitHub username.

**Or use the Azure CLI:**

```bash
az deployment group create \
  --resource-group rg-fabric-autoscale \
  --template-uri https://raw.githubusercontent.com/YOUR-USERNAME/Fabric_Auto-Scaling_with_LogicApp/master/Templates/fabric-autoscale-template.json \
  --parameters fabricCapacityName="YourCapacity" fabricWorkspaceId="guid" notificationEmail="email@domain.com"
```

**What happens automatically:**
- ✅ Creates all Azure resources (Function App, Logic App, Storage, App Insights)
- ✅ Downloads and deploys function code from your GitHub fork
- ✅ Configures managed identity authentication
- ✅ Sets up all role assignments

**Total deployment time: ~3-5 minutes** ⏱️

---

### 📋 Optional: Fork for Customization

**You can deploy without forking** - the template works out of the box.

---

### 📋 Deployment Parameters

During deployment, you'll configure:

| Parameter | Example | Description |
|-----------|---------|-------------|
| Fabric Capacity Name | `MyFabricCapacity` | Your Fabric capacity to scale |
| Workspace ID | `12345678-...` | Where Capacity Metrics App is installed |
| Notification Email | `admin@company.com` | Receives scaling alerts |
| Scale Up SKU | `F128` | Target SKU when scaling up |
| Scale Down SKU | `F64` | Target SKU when scaling down |
| Scale Up Threshold | `80` | CU % to trigger scale up |
| Scale Down Threshold | `40` | CU % to trigger scale down |
| Sustained Minutes | `15` | Minutes threshold must be sustained |

---

### 🛠️ Manual Deployment (Advanced)

If you need to manually deploy function code (troubleshooting only):

**From Azure Cloud Shell:**
```bash
curl -sL https://raw.githubusercontent.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp/master/Scripts/deploy-function-code-standalone.ps1 | pwsh -Command - -ResourceGroupName "rg-fabric-autoscale" -StorageAccountName "stfabricscalexxxxx"
```

**From local machine:**
```powershell
.\Scripts\upload-function-package.ps1 `
    -ResourceGroupName "rg-fabric-autoscale" `
    -StorageAccountName "stfabricscalexxxxx"
```

---

### 📖 Full Deployment Guide

For complete deployment instructions, prerequisites, and post-deployment configuration, see:

📖 **[Deployment Guide](DEPLOYMENT-GUIDE.md)**

---

## Configuration Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `fabricCapacityName` | Yes | - | Name of your Fabric capacity |
| `fabricWorkspaceId` | Yes | - | Workspace ID where Capacity Metrics App is installed |
| `notificationEmail` | Yes | - | Email address for notifications |
| `scaleUpSku` | No | F128 | Target SKU when scaling up |
| `scaleDownSku` | No | F64 | Target SKU when scaling down |
| `scaleUpThreshold` | No | 80 | CU utilization % to trigger scale up |
| `scaleDownThreshold` | No | 40 | CU utilization % to trigger scale down |
| `sustainedMinutes` | No | 15 | Minutes threshold must be sustained before scaling |
| `location` | No | Resource group location | Azure region |

---

## How It Works

### Sustained Threshold Logic
The solution prevents premature scaling on temporary spikes by requiring sustained high/low utilization:

1. **Every 5 minutes**, Logic App calls Function App
2. Function App **queries Capacity Metrics App** for last X minutes (default: 15 minutes)
3. Function App **counts** how many readings exceeded the threshold
4. **Scale Up**: Requires ≥3 high readings AND current utilization ≥ threshold
5. **Scale Down**: Requires ≥3 low readings AND current utilization ≤ threshold

Example:
- Threshold: 80% (scale up), 40% (scale down)
- Sustained duration: 15 minutes
- If utilization is: [85%, 87%, 82%, 90%] over 15 minutes → **Scale Up** ✅
- If utilization is: [75%, 85%, 70%, 65%] over 15 minutes → **No action** ❌ (only 1 high reading)

### Email Notifications
When scaling occurs, you receive an email with:
- Previous and new SKU
- Current utilization percentage
- Average/min/max utilization over sustained period
- Number of high/low threshold violations
- Timestamp

---
## Cost Estimation

### Azure Resources
- **Function App (Consumption Plan)**: ~$0.20/month (low execution frequency)
- **Logic App (Consumption)**: ~$0.30/month (288 runs/day)
- **Storage Account (LRS)**: ~$0.50/month
- **Application Insights**: ~$2.00/month (basic logging)

**Total**: ~$3.00/month (may vary based on usage)

---

## Monitoring and Troubleshooting

### View Function App Logs
1. Go to **Azure Portal** → **Function App** → **Application Insights**
2. Click **Logs** or **Live Metrics**
3. Query recent executions and errors

### View Logic App Runs
1. Go to **Azure Portal** → **Logic App** → **Runs history**
2. Click on a run to see detailed execution flow
3. Check each action's inputs/outputs

### Common Issues

**Issue**: Function App returns error "Failed to retrieve capacity metrics"
- **Solution**: Ensure Fabric Capacity Metrics App is installed and Function App Managed Identity has workspace access

**Issue**: Logic App fails with "Unauthorized"
- **Solution**: Verify Logic App Managed Identity has Contributor role on Fabric capacity

**Issue**: Storage account access errors during deployment
- **Solution**: Template uses managed identity authentication - ensure no Azure policies are blocking role assignments

**Issue**: No email notifications received
- **Solution**: Check Office 365 connection is authorized and email address is correct

---

## Contributing
Contributions are welcome! Please submit pull requests or open issues for bugs and feature requests.

## License
MIT License - See LICENSE file for details

## Support
For issues and questions, please open an issue on GitHub.

---

## Additional Resources
- [Microsoft Fabric Capacity Metrics App](https://learn.microsoft.com/fabric/enterprise/metrics-app)
- [Azure Logic Apps Documentation](https://docs.microsoft.com/azure/logic-apps/)
- [Azure Functions Python Developer Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-python)
- [Power BI REST API](https://learn.microsoft.com/rest/api/power-bi/)
