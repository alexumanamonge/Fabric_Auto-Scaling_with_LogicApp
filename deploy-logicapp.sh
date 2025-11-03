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