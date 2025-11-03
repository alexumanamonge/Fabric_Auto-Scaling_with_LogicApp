# Microsoft Fabric Auto-Scaling with Azure Logic Apps

## Overview
This solution automates scaling Microsoft Fabric capacity based on CU utilization thresholds using Azure Logic Apps and ARM API.

## Features
- Scale up (e.g., F64 → F128) when CU > 80%.
- Scale down when CU < 40%.
- Email and Teams notifications for scale events.
- Cool-down logic (30 min) to prevent rapid oscillation.
- Easy deployment via Azure CLI or PowerShell.

## Prerequisites
- Azure subscription with Fabric capacity.
- Contributor role on resource group.
- Managed Identity enabled for Logic App.
- Office 365 connector configured for email notifications.
- Teams connector configured for channel notifications.

## Deployment Steps
1. Clone the repo:
   ```bash
   git clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git
   cd fabric-autoscale-logicapp

2. Deploy Logic App using Azure CLI:
   ```bash
   az deployment group create \
     --resource-group <RG_NAME> \
     --template-file templates/fabric-autoscale-template.json \
     --parameters subscriptionId=<SUB_ID> resourceGroup=<RG_NAME> fabricCapacityName=<CAPACITY_NAME> notificationEmail=<EMAIL>

4. Configure Office 365 connector in Logic App designer.


## Customization:

- Modify thresholds in Condition_Scale.
- Adjust cool-down period by changing addMinutes(..., 30) in template.
- Add more notifications or logging as needed.


## Artifacts:
- fabric-autoscale-template.json: ARM template for Logic App.
- Deployment scripts for CLI and PowerShell.
- Example alert configuration for Azure Monitor.

---

### **2. templates/fabric-autoscale-template.json**
Includes:
- **Email notifications** (Office 365 connector).
- **Teams notifications** (Teams connector).
- **Cool-down logic** (30 min delay before next scale).


---

### **3. scripts/deploy-logicapp.sh**
```bash
#!/bin/bash
# Deploy Logic App using Azure CLI
RESOURCE_GROUP=$1
SUBSCRIPTION_ID=$2
CAPACITY_NAME=$3
EMAIL=$4
TEAMS_CHANNEL_ID=$5

az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file templates/fabric-autoscale-template.json \
  --parameters subscriptionId=$SUBSCRIPTION_ID resourceGroup=$RESOURCE_GROUP fabricCapacityName=$CAPACITY_NAME notificationEmail=$EMAIL teamsChannelId=$TEAMS_CHANNEL_ID


### **4. scripts/deploy-logicapp.ps1**
param(
    [string]$ResourceGroup,
    [string]$SubscriptionId,
    [string]$CapacityName,
    [string]$Email,
    [string]$TeamsChannelId
)

az deployment group create `
  --resource-group $ResourceGroup `
  --template-file templates/fabric-autoscale-template.json `
  --parameters subscriptionId=$SubscriptionId resourceGroup=$ResourceGroup fabricCapacityName=$CapacityName notificationEmail=$Email teamsChannelId=$TeamsChannelId