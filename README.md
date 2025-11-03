# Microsoft Fabric Auto-Scaling with Azure Logic Apps

## Overview
This solution automates scaling Microsoft Fabric capacity based on overload metrics using Azure Logic Apps with Managed Identity authentication. The Logic App monitors your Fabric capacity and automatically scales up or down based on utilization.

## Features
- ✅ **Automated Scaling**: Scale up (e.g., F64 → F128) when capacity is overloaded, scale down when underutilized
- ✅ **Managed Identity Authentication**: Secure authentication using Azure Managed Identity (no secrets to manage)
- ✅ **Email Notifications**: Receive email alerts via Office 365 when scaling events occur
- ✅ **Configurable Thresholds**: Customize scale-up and scale-down SKUs via ARM template parameters
- ✅ **Azure Monitor Integration**: Uses native Azure Monitor metrics for Fabric capacity
- ✅ **Automated Deployment**: Deploy via Azure CLI using PowerShell or Bash scripts

## Architecture
The solution uses:
- **Azure Logic App** with System-assigned Managed Identity
- **Azure Monitor Metrics** to track Fabric capacity overload
- **Office 365 Connector** for email notifications
- **ARM Template** for infrastructure-as-code deployment

## Prerequisites
Before deploying, ensure you have:
1. ✅ Azure subscription with an active Fabric capacity
2. ✅ Azure CLI installed ([Download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
3. ✅ Contributor or Owner role on the resource group
4. ✅ Office 365 account for email notifications

## Deployment Steps

### Option 1: PowerShell Deployment (Windows)
```powershell
# Clone the repository
git clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git
cd Fabric_Auto-Scaling_with_LogicApp

# Run the deployment script
.\Scripts\deploy-logicapp.ps1 `
  -ResourceGroup "myResourceGroup" `
  -CapacityName "myFabricCapacity" `
  -Email "admin@company.com" `
  -Location "eastus" `
  -ScaleUpSku "F128" `
  -ScaleDownSku "F64"
```

### Option 2: Bash Deployment (Linux/Mac)
```bash
# Clone the repository
git clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git
cd Fabric_Auto-Scaling_with_LogicApp

# Make the script executable
chmod +x Scripts/deploy-logicapp.sh

# Run the deployment script
./Scripts/deploy-logicapp.sh \
  -g "myResourceGroup" \
  -c "myFabricCapacity" \
  -e "admin@company.com" \
  -l "eastus" \
  -u "F128" \
  -d "F64"
```

### Option 3: Direct Azure CLI Deployment
```bash
az deployment group create \
  --resource-group myResourceGroup \
  --template-file Templates/fabric-autoscale-template.json \
  --parameters \
    fabricCapacityName=myFabricCapacity \
    notificationEmail=admin@company.com \
    scaleUpSku=F128 \
    scaleDownSku=F64
```

## Post-Deployment Configuration

### 1. Authorize Office 365 Connection
After deployment, you must authorize the Office 365 API connection:
1. Go to Azure Portal → Resource Groups → [Your Resource Group]
2. Find the API Connection resource named `office365-FabricAutoScaleLogicApp`
3. Click "Edit API connection" → "Authorize" → Sign in with your Office 365 account
4. Click "Save"

### 2. Assign Managed Identity Permissions
The Logic App needs permission to manage the Fabric capacity:

```bash
# Get the subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get the Logic App's Managed Identity Principal ID
PRINCIPAL_ID=$(az resource show \
  --resource-group myResourceGroup \
  --name FabricAutoScaleLogicApp \
  --resource-type Microsoft.Logic/workflows \
  --query identity.principalId -o tsv)

# Assign Contributor role to the Fabric capacity
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/myResourceGroup/providers/Microsoft.Fabric/capacities/myFabricCapacity
```

### 3. Enable the Logic App
1. Go to Azure Portal → Logic App
2. Click "Enable" to start the recurrence trigger (runs every 5 minutes)

## Configuration Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `logicAppName` | Name of the Logic App | FabricAutoScaleLogicApp | No |
| `location` | Azure region | Resource group location | No |
| `fabricCapacityName` | Name of the Fabric capacity | - | Yes |
| `notificationEmail` | Email for notifications | - | Yes |
| `scaleUpSku` | SKU to scale up to | F128 | No |
| `scaleDownSku` | SKU to scale down to | F64 | No |

## Customization

### Modify Scaling Logic
Edit the ARM template (`Templates/fabric-autoscale-template.json`) to:
- Change the recurrence interval (currently 5 minutes)
- Adjust SKU sizes for scale-up/down
- Implement custom scaling logic

### Add Azure Monitor Alerts
You can also configure Azure Monitor alerts for additional scenarios. See `Example/alert-configuration.md` for guidance.

## How It Works
1. **Trigger**: Logic App runs every 5 minutes
2. **Check Metrics**: Queries Azure Monitor for Fabric capacity overload metric
3. **Evaluate**: Determines if scaling is needed based on metrics
4. **Scale**: Calls Azure Management API to update capacity SKU
5. **Notify**: Sends email notification about the scaling event

## Monitoring
- View Logic App run history in Azure Portal
- Check email for scaling notifications
- Monitor Fabric capacity metrics in Azure Monitor
- Review Logic App diagnostic logs

## Troubleshooting

### Logic App fails to run
- Ensure the Managed Identity has Contributor role on the Fabric capacity
- Check that the Office 365 connection is authorized

### No notifications received
- Verify the email address is correct
- Check Logic App run history for action failures
- Ensure Office 365 connection is authorized

### Scaling not occurring
- Verify metrics are being collected for the Fabric capacity
- Check the scaling conditions in the Logic App workflow
- Ensure the capacity supports the target SKUs

## Security Considerations
- ✅ Uses Managed Identity (no credentials stored)
- ✅ Office 365 connection uses OAuth authentication
- ✅ RBAC permissions follow least-privilege principle

## Cost Considerations
- Logic App: Consumption tier pricing (per action execution)
- Fabric Capacity: Charged based on active SKU size
- API Connections: Minimal cost for Office 365 connector

## Repository Structure
```
.
├── README.md                          # This file
├── Templates/
│   └── fabric-autoscale-template.json # ARM template for Logic App
├── Scripts/
│   ├── deploy-logicapp.ps1           # PowerShell deployment script
│   └── deploy-logicapp.sh            # Bash deployment script
└── Example/
    └── alert-configuration.md        # Azure Monitor alert examples
```

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.

## License
This project is provided as-is for demonstration purposes.

## Support
For issues or questions, please open an issue in the GitHub repository.

