#!/bin/bash
# Deploy Logic App for Fabric Auto-Scaling using Azure CLI

# Function to display usage
usage() {
    echo "Usage: $0 -g RESOURCE_GROUP -c CAPACITY_NAME -e EMAIL [-l LOCATION] [-n LOGIC_APP_NAME]"
    echo ""
    echo "Required arguments:"
    echo "  -g    Resource group name"
    echo "  -c    Fabric capacity name"
    echo "  -e    Notification email address"
    echo ""
    echo "Optional arguments:"
    echo "  -l    Azure region (default: eastus)"
    echo "  -n    Logic App name (default: FabricAutoScaleLogicApp)"
    echo "  -u    Scale up SKU (default: F128)"
    echo "  -d    Scale down SKU (default: F64)"
    exit 1
}

# Default values
LOCATION="eastus"
LOGIC_APP_NAME="FabricAutoScaleLogicApp"
SCALE_UP_SKU="F128"
SCALE_DOWN_SKU="F64"
SCALE_UP_THRESHOLD=80
SCALE_DOWN_THRESHOLD=40

# Parse arguments
while getopts "g:c:e:l:n:u:d:h" opt; do
    case $opt in
        g) RESOURCE_GROUP="$OPTARG" ;;
        c) CAPACITY_NAME="$OPTARG" ;;
        e) EMAIL="$OPTARG" ;;
        l) LOCATION="$OPTARG" ;;
        n) LOGIC_APP_NAME="$OPTARG" ;;
        u) SCALE_UP_SKU="$OPTARG" ;;
        d) SCALE_DOWN_SKU="$OPTARG" ;;
        h) usage ;;
        \?) usage ;;
    esac
done

# Validate required arguments
if [ -z "$RESOURCE_GROUP" ] || [ -z "$CAPACITY_NAME" ] || [ -z "$EMAIL" ]; then
    echo "Error: Missing required arguments"
    usage
fi

# Get script directory and template path
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMPLATE_FILE="$SCRIPT_DIR/../Templates/fabric-autoscale-template.json"

echo "========================================"
echo "Deploying Fabric Auto-Scaling Logic App"
echo "========================================"
echo "Resource Group: $RESOURCE_GROUP"
echo "Capacity Name: $CAPACITY_NAME"
echo "Location: $LOCATION"
echo "Template File: $TEMPLATE_FILE"
echo "========================================"

# Deploy the ARM template
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters \
    logicAppName="$LOGIC_APP_NAME" \
    location="$LOCATION" \
    fabricCapacityName="$CAPACITY_NAME" \
    notificationEmail="$EMAIL" \
    scaleUpSku="$SCALE_UP_SKU" \
    scaleDownSku="$SCALE_DOWN_SKU" \
    scaleUpThreshold=$SCALE_UP_THRESHOLD \
    scaleDownThreshold=$SCALE_DOWN_THRESHOLD

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment completed successfully!"
    echo ""
    echo "⚠️  IMPORTANT: Post-deployment steps:"
    echo "1. Go to the Azure Portal and navigate to the Logic App: $LOGIC_APP_NAME"
    echo "2. Authorize the Office 365 connection under 'API connections'"
    echo "3. Assign 'Contributor' role to the Logic App's Managed Identity on the Fabric capacity"
    echo ""
    
    # Get the Logic App's principal ID
    PRINCIPAL_ID=$(az resource show \
      --resource-group "$RESOURCE_GROUP" \
      --name "$LOGIC_APP_NAME" \
      --resource-type Microsoft.Logic/workflows \
      --query identity.principalId -o tsv)
    
    if [ -n "$PRINCIPAL_ID" ]; then
        echo "Logic App Managed Identity Principal ID: $PRINCIPAL_ID"
        echo ""
        echo "Run this command to assign the Contributor role:"
        SUBSCRIPTION_ID=$(az account show --query id -o tsv)
        echo "az role assignment create \\"
        echo "  --assignee $PRINCIPAL_ID \\"
        echo "  --role Contributor \\"
        echo "  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Fabric/capacities/$CAPACITY_NAME"
    fi
else
    echo ""
    echo "❌ Deployment failed. Please check the error messages above."
    exit 1
fi