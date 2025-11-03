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