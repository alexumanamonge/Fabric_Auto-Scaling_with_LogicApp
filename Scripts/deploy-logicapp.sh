#!/bin/bash#!/bin/bash#!/bin/bash



# Deploy Fabric Auto-Scaling Solution with Function App and Logic App# Deploy Fabric Auto-Scaling Solution with Function App and Logic App# Deploy Logic App for Fabric Auto-Scaling using Azure CLI



# Function to display usage

usage() {

    echo "Usage: $0 -g RESOURCE_GROUP -c CAPACITY_NAME -e EMAIL -w WORKSPACE_ID [-l LOCATION] [-n LOGIC_APP_NAME]"# Function to display usage# Function to display usage

    echo ""

    echo "Required arguments:"usage() {usage() {

    echo "  -g    Resource group name"

    echo "  -c    Fabric capacity name"    echo "Usage: $0 -g RESOURCE_GROUP -c CAPACITY_NAME -e EMAIL -w WORKSPACE_ID [-l LOCATION] [-n LOGIC_APP_NAME]"    echo "Usage: $0 -g RESOURCE_GROUP -c CAPACITY_NAME -e EMAIL [-l LOCATION] [-n LOGIC_APP_NAME]"

    echo "  -e    Notification email address"

    echo "  -w    Fabric workspace ID where Capacity Metrics App is installed"    echo ""    echo ""

    echo ""

    echo "Optional arguments:"    echo "Required arguments:"    echo "Required arguments:"

    echo "  -l    Azure region (default: eastus)"

    echo "  -n    Logic App name (default: FabricAutoScaleLogicApp)"    echo "  -g    Resource group name"    echo "  -g    Resource group name"

    echo "  -u    Scale up SKU (default: F128)"

    echo "  -d    Scale down SKU (default: F64)"    echo "  -c    Fabric capacity name"    echo "  -c    Fabric capacity name"

    echo "  -s    Sustained minutes threshold (default: 15)"

    exit 1    echo "  -e    Notification email address"    echo "  -e    Notification email address"

}

    echo "  -w    Fabric workspace ID where Capacity Metrics App is installed"    echo ""

# Default values

LOCATION="eastus"    echo ""    echo "Optional arguments:"

LOGIC_APP_NAME="FabricAutoScaleLogicApp"

SCALE_UP_SKU="F128"    echo "Optional arguments:"    echo "  -l    Azure region (default: eastus)"

SCALE_DOWN_SKU="F64"

SCALE_UP_THRESHOLD=80    echo "  -l    Azure region (default: eastus)"    echo "  -n    Logic App name (default: FabricAutoScaleLogicApp)"

SCALE_DOWN_THRESHOLD=40

SUSTAINED_MINUTES=15    echo "  -n    Logic App name (default: FabricAutoScaleLogicApp)"    echo "  -u    Scale up SKU (default: F128)"



# Parse arguments    echo "  -u    Scale up SKU (default: F128)"    echo "  -d    Scale down SKU (default: F64)"

while getopts "g:c:e:w:l:n:u:d:s:h" opt; do

    case $opt in    echo "  -d    Scale down SKU (default: F64)"    exit 1

        g) RESOURCE_GROUP="$OPTARG" ;;

        c) CAPACITY_NAME="$OPTARG" ;;    echo "  -s    Sustained minutes threshold (default: 15)"}

        e) EMAIL="$OPTARG" ;;

        w) WORKSPACE_ID="$OPTARG" ;;    exit 1

        l) LOCATION="$OPTARG" ;;

        n) LOGIC_APP_NAME="$OPTARG" ;;}# Default values

        u) SCALE_UP_SKU="$OPTARG" ;;

        d) SCALE_DOWN_SKU="$OPTARG" ;;LOCATION="eastus"

        s) SUSTAINED_MINUTES="$OPTARG" ;;

        h) usage ;;# Default valuesLOGIC_APP_NAME="FabricAutoScaleLogicApp"

        \?) usage ;;

    esacLOCATION="eastus"SCALE_UP_SKU="F128"

done

LOGIC_APP_NAME="FabricAutoScaleLogicApp"SCALE_DOWN_SKU="F64"

# Validate required arguments

if [ -z "$RESOURCE_GROUP" ] || [ -z "$CAPACITY_NAME" ] || [ -z "$EMAIL" ] || [ -z "$WORKSPACE_ID" ]; thenSCALE_UP_SKU="F128"SCALE_UP_THRESHOLD=80

    echo "Error: Missing required arguments"

    usageSCALE_DOWN_SKU="F64"SCALE_DOWN_THRESHOLD=40

fi

SCALE_UP_THRESHOLD=80

# Get script directory and template path

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"SCALE_DOWN_THRESHOLD=40# Parse arguments

TEMPLATE_FILE="$SCRIPT_DIR/../Templates/fabric-autoscale-template.json"

FUNCTION_APP_DIR="$SCRIPT_DIR/../FunctionApp"SUSTAINED_MINUTES=15while getopts "g:c:e:l:n:u:d:h" opt; do



echo "========================================"    case $opt in

echo "Fabric Auto-Scaling Deployment"

echo "========================================"# Parse arguments        g) RESOURCE_GROUP="$OPTARG" ;;

echo "Resource Group: $RESOURCE_GROUP"

echo "Capacity Name: $CAPACITY_NAME"while getopts "g:c:e:w:l:n:u:d:s:h" opt; do        c) CAPACITY_NAME="$OPTARG" ;;

echo "Workspace ID: $WORKSPACE_ID"

echo "Email: $EMAIL"    case $opt in        e) EMAIL="$OPTARG" ;;

echo "Location: $LOCATION"

echo "Template: $TEMPLATE_FILE"        g) RESOURCE_GROUP="$OPTARG" ;;        l) LOCATION="$OPTARG" ;;

echo "========================================"

        c) CAPACITY_NAME="$OPTARG" ;;        n) LOGIC_APP_NAME="$OPTARG" ;;

# Deploy ARM template

echo ""        e) EMAIL="$OPTARG" ;;        u) SCALE_UP_SKU="$OPTARG" ;;

echo "Deploying Azure resources (Function App, Logic App, connections)..."

az deployment group create \        w) WORKSPACE_ID="$OPTARG" ;;        d) SCALE_DOWN_SKU="$OPTARG" ;;

  --resource-group "$RESOURCE_GROUP" \

  --template-file "$TEMPLATE_FILE" \        l) LOCATION="$OPTARG" ;;        h) usage ;;

  --parameters \

    logicAppName="$LOGIC_APP_NAME" \        n) LOGIC_APP_NAME="$OPTARG" ;;        \?) usage ;;

    location="$LOCATION" \

    fabricCapacityName="$CAPACITY_NAME" \        u) SCALE_UP_SKU="$OPTARG" ;;    esac

    fabricWorkspaceId="$WORKSPACE_ID" \

    notificationEmail="$EMAIL" \        d) SCALE_DOWN_SKU="$OPTARG" ;;done

    scaleUpSku="$SCALE_UP_SKU" \

    scaleDownSku="$SCALE_DOWN_SKU" \        s) SUSTAINED_MINUTES="$OPTARG" ;;

    scaleUpThreshold=$SCALE_UP_THRESHOLD \

    scaleDownThreshold=$SCALE_DOWN_THRESHOLD \        h) usage ;;# Validate required arguments

    sustainedMinutes=$SUSTAINED_MINUTES

        \?) usage ;;if [ -z "$RESOURCE_GROUP" ] || [ -z "$CAPACITY_NAME" ] || [ -z "$EMAIL" ]; then

if [ $? -ne 0 ]; then

    echo ""    esac    echo "Error: Missing required arguments"

    echo "ARM template deployment failed. Please check the error messages above."

    exit 1done    usage

fi

fi

echo ""

echo "ARM template deployment completed successfully!"# Validate required arguments



# Get deployment outputsif [ -z "$RESOURCE_GROUP" ] || [ -z "$CAPACITY_NAME" ] || [ -z "$EMAIL" ] || [ -z "$WORKSPACE_ID" ]; then# Get script directory and template path

DEPLOYMENT_NAME=$(basename "$TEMPLATE_FILE" .json)

FUNCTION_APP_NAME=$(az deployment group show --resource-group "$RESOURCE_GROUP" --name "$DEPLOYMENT_NAME" --query properties.outputs.functionAppName.value -o tsv)    echo "Error: Missing required arguments"SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LOGIC_APP_PRINCIPAL_ID=$(az deployment group show --resource-group "$RESOURCE_GROUP" --name "$DEPLOYMENT_NAME" --query properties.outputs.logicAppPrincipalId.value -o tsv)

FUNCTION_APP_PRINCIPAL_ID=$(az deployment group show --resource-group "$RESOURCE_GROUP" --name "$DEPLOYMENT_NAME" --query properties.outputs.functionAppPrincipalId.value -o tsv)    usageTEMPLATE_FILE="$SCRIPT_DIR/../Templates/fabric-autoscale-template.json"



# Deploy Function App codefi

echo ""

echo "Deploying Function App code..."echo "========================================"

if [ -d "$FUNCTION_APP_DIR" ]; then

    # Check if Azure Functions Core Tools is installed# Get script directory and template pathecho "Deploying Fabric Auto-Scaling Logic App"

    if command -v func &> /dev/null; then

        cd "$FUNCTION_APP_DIR"SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"echo "========================================"

        func azure functionapp publish "$FUNCTION_APP_NAME" --python

        TEMPLATE_FILE="$SCRIPT_DIR/../Templates/fabric-autoscale-template.json"echo "Resource Group: $RESOURCE_GROUP"

        if [ $? -eq 0 ]; then

            echo "Function App code deployed successfully!"FUNCTION_APP_DIR="$SCRIPT_DIR/../FunctionApp"echo "Capacity Name: $CAPACITY_NAME"

        else

            echo "Function App code deployment failed. You may need to deploy it manually."echo "Location: $LOCATION"

        fi

        cd - > /dev/nullecho "========================================"echo "Template File: $TEMPLATE_FILE"

    else

        echo "Azure Functions Core Tools not found. Please install it to deploy Function App code."echo "Deploying Fabric Auto-Scaling Solution"echo "========================================"

        echo "Install from: https://docs.microsoft.com/azure/azure-functions/functions-run-local"

    fiecho "========================================"

else

    echo "Function App directory not found: $FUNCTION_APP_DIR"echo "Resource Group: $RESOURCE_GROUP"# Deploy the ARM template

    echo "Please deploy the Function App code manually."

fiecho "Capacity Name: $CAPACITY_NAME"az deployment group create \



echo ""echo "Workspace ID: $WORKSPACE_ID"  --resource-group "$RESOURCE_GROUP" \

echo "========================================"

echo "DEPLOYMENT COMPLETED!"echo "Location: $LOCATION"  --template-file "$TEMPLATE_FILE" \

echo "========================================"

echo "Template File: $TEMPLATE_FILE"  --parameters \

echo ""

echo "IMPORTANT: Post-deployment steps:"echo "========================================"    logicAppName="$LOGIC_APP_NAME" \

echo ""

echo "1. AUTHORIZE OFFICE 365 CONNECTION"    location="$LOCATION" \

echo "   - Go to Azure Portal > Resource Groups > $RESOURCE_GROUP"

echo "   - Find the API Connection resource (office365-$LOGIC_APP_NAME)"# Deploy the ARM template    fabricCapacityName="$CAPACITY_NAME" \

echo "   - Click 'Edit API connection' > 'Authorize' > Sign in with your Office 365 account"

echo ""    notificationEmail="$EMAIL" \

echo ""

echo "2. ASSIGN PERMISSIONS TO LOGIC APP"echo "Deploying Azure resources (Function App, Logic App, connections)..."    scaleUpSku="$SCALE_UP_SKU" \

echo "   Principal ID: $LOGIC_APP_PRINCIPAL_ID"

echo "   Run this command:"az deployment group create \    scaleDownSku="$SCALE_DOWN_SKU" \

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "   az role assignment create --assignee $LOGIC_APP_PRINCIPAL_ID --role Contributor --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Fabric/capacities/$CAPACITY_NAME"  --resource-group "$RESOURCE_GROUP" \    scaleUpThreshold=$SCALE_UP_THRESHOLD \



echo ""  --template-file "$TEMPLATE_FILE" \    scaleDownThreshold=$SCALE_DOWN_THRESHOLD

echo "3. ASSIGN PERMISSIONS TO FUNCTION APP"

echo "   Principal ID: $FUNCTION_APP_PRINCIPAL_ID"  --parameters \

echo "   The Function App needs:"

echo "   - Reader access to Fabric workspace containing Capacity Metrics App"    logicAppName="$LOGIC_APP_NAME" \if [ $? -eq 0 ]; then

echo "   - You may need to grant access via Power BI Admin Portal or Fabric workspace settings"

    location="$LOCATION" \    echo ""

echo ""

echo "4. INSTALL FABRIC CAPACITY METRICS APP"    fabricCapacityName="$CAPACITY_NAME" \    echo "✅ Deployment completed successfully!"

echo "   - Go to your Fabric workspace (ID: $WORKSPACE_ID)"

echo "   - Install the Microsoft Fabric Capacity Metrics App from AppSource"    fabricWorkspaceId="$WORKSPACE_ID" \    echo ""

echo "   - Configure it to track your capacity: $CAPACITY_NAME"

    notificationEmail="$EMAIL" \    echo "⚠️  IMPORTANT: Post-deployment steps:"

echo ""

echo "Deployment summary saved. Enjoy your auto-scaling solution! 🚀"    scaleUpSku="$SCALE_UP_SKU" \    echo "1. Go to the Azure Portal and navigate to the Logic App: $LOGIC_APP_NAME"


    scaleDownSku="$SCALE_DOWN_SKU" \    echo "2. Authorize the Office 365 connection under 'API connections'"

    scaleUpThreshold=$SCALE_UP_THRESHOLD \    echo "3. Assign 'Contributor' role to the Logic App's Managed Identity on the Fabric capacity"

    scaleDownThreshold=$SCALE_DOWN_THRESHOLD \    echo ""

    sustainedMinutes=$SUSTAINED_MINUTES    

    # Get the Logic App's principal ID

if [ $? -ne 0 ]; then    PRINCIPAL_ID=$(az resource show \

    echo ""      --resource-group "$RESOURCE_GROUP" \

    echo "❌ ARM template deployment failed. Please check the error messages above."      --name "$LOGIC_APP_NAME" \

    exit 1      --resource-type Microsoft.Logic/workflows \

fi      --query identity.principalId -o tsv)

    

echo ""    if [ -n "$PRINCIPAL_ID" ]; then

echo "✅ ARM template deployment completed successfully!"        echo "Logic App Managed Identity Principal ID: $PRINCIPAL_ID"

        echo ""

# Get deployment outputs        echo "Run this command to assign the Contributor role:"

DEPLOYMENT_NAME=$(basename "$TEMPLATE_FILE" .json)        SUBSCRIPTION_ID=$(az account show --query id -o tsv)

FUNCTION_APP_NAME=$(az deployment group show \        echo "az role assignment create \\"

  --resource-group "$RESOURCE_GROUP" \        echo "  --assignee $PRINCIPAL_ID \\"

  --name "$DEPLOYMENT_NAME" \        echo "  --role Contributor \\"

  --query properties.outputs.functionAppName.value -o tsv)        echo "  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Fabric/capacities/$CAPACITY_NAME"

      fi

LOGIC_APP_PRINCIPAL_ID=$(az deployment group show \else

  --resource-group "$RESOURCE_GROUP" \    echo ""

  --name "$DEPLOYMENT_NAME" \    echo "❌ Deployment failed. Please check the error messages above."

  --query properties.outputs.logicAppPrincipalId.value -o tsv)    exit 1

  fi
FUNCTION_APP_PRINCIPAL_ID=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --query properties.outputs.functionAppPrincipalId.value -o tsv)

# Deploy Function App code
echo ""
echo "Deploying Function App code..."
if [ -d "$FUNCTION_APP_DIR" ]; then
    # Check if Azure Functions Core Tools is installed
    if command -v func &> /dev/null; then
        cd "$FUNCTION_APP_DIR"
        func azure functionapp publish "$FUNCTION_APP_NAME" --python
        cd "$SCRIPT_DIR"
        
        if [ $? -eq 0 ]; then
            echo "✅ Function App code deployed successfully!"
        else
            echo "⚠️  Function App code deployment failed. You may need to deploy it manually."
        fi
    else
        echo "⚠️  Azure Functions Core Tools not found. Please install it to deploy Function App code."
        echo "Install from: https://docs.microsoft.com/azure/azure-functions/functions-run-local"
    fi
else
    echo "⚠️  Function App directory not found: $FUNCTION_APP_DIR"
    echo "Please deploy the Function App code manually."
fi

echo ""
echo "========================================"
echo "DEPLOYMENT COMPLETED!"
echo "========================================"

echo ""
echo "⚠️  IMPORTANT: Post-deployment steps:"
echo ""
echo "1. AUTHORIZE OFFICE 365 CONNECTION"
echo "   - Go to Azure Portal > Resource Groups > $RESOURCE_GROUP"
echo "   - Find the API Connection resource (office365-$LOGIC_APP_NAME)"
echo "   - Click 'Edit API connection' > 'Authorize' > Sign in with your Office 365 account"
echo ""

echo "2. ASSIGN PERMISSIONS TO LOGIC APP"
echo "   Principal ID: $LOGIC_APP_PRINCIPAL_ID"
echo "   Run this command:"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "   az role assignment create \\"
echo "     --assignee $LOGIC_APP_PRINCIPAL_ID \\"
echo "     --role Contributor \\"
echo "     --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Fabric/capacities/$CAPACITY_NAME"
echo ""

echo "3. ASSIGN PERMISSIONS TO FUNCTION APP"
echo "   Principal ID: $FUNCTION_APP_PRINCIPAL_ID"
echo "   The Function App needs:"
echo "   - Reader access to Fabric workspace containing Capacity Metrics App"
echo "   - You may need to grant access via Power BI Admin Portal or Fabric workspace settings"
echo ""

echo "4. INSTALL FABRIC CAPACITY METRICS APP"
echo "   - Go to your Fabric workspace (ID: $WORKSPACE_ID)"
echo "   - Install the Microsoft Fabric Capacity Metrics App from AppSource"
echo "   - Configure it to track your capacity: $CAPACITY_NAME"
echo ""

echo "Deployment summary saved. Enjoy your auto-scaling solution! 🚀"
