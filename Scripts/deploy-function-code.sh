#!/bin/bash

# Deploy Function App Code using Kudu API
# This script works reliably regardless of WEBSITE_RUN_FROM_PACKAGE setting

set -e

# Function to display usage
usage() {
    echo "Usage: $0 -g RESOURCE_GROUP -n FUNCTION_APP_NAME"
    echo ""
    echo "Required arguments:"
    echo "  -g    Resource group name"
    echo "  -n    Function App name"
    exit 1
}

# Parse arguments
while getopts "g:n:h" opt; do
    case $opt in
        g) RESOURCE_GROUP="$OPTARG" ;;
        n) FUNCTION_APP_NAME="$OPTARG" ;;
        h) usage ;;
        \?) usage ;;
    esac
done

# Validate required arguments
if [ -z "$RESOURCE_GROUP" ] || [ -z "$FUNCTION_APP_NAME" ]; then
    echo "Error: Missing required arguments"
    usage
fi

echo "========================================"
echo "Function App Code Deployment"
echo "========================================"
echo "Resource Group: $RESOURCE_GROUP"
echo "Function App: $FUNCTION_APP_NAME"
echo "========================================"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FUNCTION_APP_DIR="$SCRIPT_DIR/../FunctionApp"
ZIP_PATH="$SCRIPT_DIR/../functionapp.zip"

# Create zip file
echo ""
echo "Creating deployment package..."
cd "$FUNCTION_APP_DIR"
zip -r "$ZIP_PATH" . -x "*.pyc" -x "__pycache__/*" -x ".git/*"

if [ ! -f "$ZIP_PATH" ]; then
    echo "Error: Failed to create deployment package"
    exit 1
fi

echo "Package created: $ZIP_PATH"

# Get publishing credentials
echo ""
echo "Retrieving publishing credentials..."
CREDS=$(az functionapp deployment list-publishing-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$FUNCTION_APP_NAME" \
    --query "{username:publishingUserName, password:publishingPassword}" -o json)

if [ -z "$CREDS" ]; then
    echo "Error: Failed to retrieve publishing credentials"
    exit 1
fi

USERNAME=$(echo $CREDS | jq -r .username)
PASSWORD=$(echo $CREDS | jq -r .password)

# Deploy using Kudu API
echo ""
echo "Deploying to Function App..."
KUDU_URL="https://$FUNCTION_APP_NAME.scm.azurewebsites.net/api/zipdeploy"

HTTP_CODE=$(curl -X POST \
    -u "$USERNAME:$PASSWORD" \
    --data-binary @"$ZIP_PATH" \
    -H "Content-Type: application/zip" \
    -w "%{http_code}" \
    -o /dev/null \
    -s \
    "$KUDU_URL")

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 202 ]; then
    echo ""
    echo "✅ Deployment successful!"
else
    echo ""
    echo "❌ Deployment failed with HTTP code: $HTTP_CODE"
    exit 1
fi

# Verify deployment
echo ""
echo "Verifying deployment..."
sleep 5

FUNCTIONS=$(az functionapp function list \
    --resource-group "$RESOURCE_GROUP" \
    --name "$FUNCTION_APP_NAME" \
    --query "[].name" -o tsv)

if echo "$FUNCTIONS" | grep -q "CheckCapacityMetrics"; then
    echo "✅ Function 'CheckCapacityMetrics' deployed successfully!"
else
    echo "⚠️  Warning: Function not found. Please verify in Azure Portal."
fi

# Cleanup
rm -f "$ZIP_PATH"

echo ""
echo "Deployment completed!"
echo "You can view your function at: https://$FUNCTION_APP_NAME.azurewebsites.net"
