# Deployment Guide - Fabric Auto-Scale Logic App

## Quick Start (5 Minutes)

### Prerequisites Checklist
- [ ] Microsoft Fabric capacity (know the name, resource group, subscription)
- [ ] Power BI workspace with **Microsoft Fabric Capacity Metrics** app installed
- [ ] **Workspace ID** (from URL: `https://app.powerbi.com/groups/{workspace-id}/...`)
- [ ] **Dataset ID** for Capacity Metrics App (see below)
- [ ] Azure subscription with Contributor access
- [ ] Office 365 email account

### ⚠️ How to Get the Dataset ID (REQUIRED)

1. Go to **Power BI Service**: https://app.powerbi.com
2. Navigate to the workspace where you installed the Capacity Metrics App
3. Find the **"Microsoft Fabric Capacity Metrics"** dataset
4. Click ⋯ (More options) > **Settings**
5. Look at the browser URL - it contains the dataset ID:
   ```
   https://app.powerbi.com/groups/{workspaceId}/settings/datasets/{datasetId}
   ```
6. **Copy the `{datasetId}`** - it's a GUID like `87654321-4321-4321-4321-210987654321`
7. You'll need this for the deployment command below

---

## Step 1: Deploy the Template

### Option A: PowerShell (Recommended)

```powershell
# Clone or download this repository
git clone https://github.com/YOUR_USERNAME/Fabric-AutoScale-LogicApp.git
cd Fabric-AutoScale-LogicApp/Scripts

# Run deployment
.\deploy-logicapp.ps1 `
    -ResourceGroupName "rg-fabricautoscale" `
    -FabricCapacityName "my-fabric-capacity" `
    -FabricResourceGroup "rg-fabric-prod" `
    -FabricWorkspaceId "12345678-1234-1234-1234-123456789abc" `
    -CapacityMetricsDatasetId "87654321-4321-4321-4321-210987654321" `
    -EmailRecipient "admin@company.com" `
    -Location "eastus"
```

**Expected Output:**
```
✓ Deployment successful!
Logic App Name: fabricautoscale-xyz123
Managed Identity Principal ID: abc-def-ghi-123
```

### Option B: Azure CLI

```bash
cd Fabric-AutoScale-LogicApp

az deployment group create \
  --resource-group rg-fabricautoscale \
  --template-file Templates/fabric-autoscale-template.json \
  --parameters \
    fabricCapacityName="my-fabric-capacity" \
    fabricResourceGroup="rg-fabric-prod" \
    fabricWorkspaceId="12345678-1234-1234-1234-123456789abc" \
    capacityMetricsDatasetId="87654321-4321-4321-4321-210987654321" \
    emailRecipient="admin@company.com"
```

### Option C: Azure Portal

1. Go to **Azure Portal** > **Create a resource** > **Template deployment**
2. Click **Build your own template in the editor**
3. Copy/paste contents of `Templates/fabric-autoscale-template.json`
4. Click **Save**
5. Fill in parameters:
   - **Fabric Capacity Name**: Your capacity name
   - **Fabric Resource Group**: RG containing the capacity
   - **Fabric Workspace ID**: From Power BI workspace URL
   - **Capacity Metrics Dataset ID**: The dataset GUID you copied earlier
   - **Email Recipient**: Your email
   - **Scale Up SKU**: F128 (or your choice)
   - **Scale Down SKU**: F64 (or your choice)
6. Click **Review + create** > **Create**

---

## Step 2: Post-Deployment Configuration (REQUIRED)

### 2.1 Authorize Office 365 Connection

**Why:** The Logic App needs permission to send emails on your behalf.

1. Go to **Azure Portal** > Navigate to your resource group
2. Find the resource named **office365-{logicAppName}** (Type: API Connection)
3. Click on it
4. Click **Edit API connection** (left menu)
5. Click the **Authorize** button
6. Sign in with your **Office 365 account** (the one that will send emails)
7. Click **Save**

**✅ Success indicator:** The connection status shows a green checkmark.

### 2.2 Assign Fabric Capacity Permissions

**Why:** The Logic App's managed identity needs Contributor role to scale the capacity.

#### Method 1: Azure Portal (GUI)

1. Go to **Azure Portal** > Navigate to your **Fabric capacity** resource
2. Click **Access control (IAM)** (left menu)
3. Click **+ Add** > **Add role assignment**
4. **Role tab:**
   - Select **Contributor**
   - Click **Next**
5. **Members tab:**
   - Select **Managed identity**
   - Click **+ Select members**
   - **Subscription:** Your subscription
   - **Managed identity:** Logic App
   - Select your Logic App (named `fabricautoscale-*`)
   - Click **Select**
   - Click **Next**
6. Click **Review + assign**

#### Method 2: Azure CLI (Scripted)

```bash
# Get the Logic App's principal ID from deployment output
PRINCIPAL_ID="<from-deployment-output>"

# Or retrieve it
PRINCIPAL_ID=$(az logicapp show \
  --resource-group rg-fabricautoscale \
  --name fabricautoscale-xyz123 \
  --query identity.principalId -o tsv)

# Assign Contributor role on the Fabric capacity
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role Contributor \
  --scope /subscriptions/<subscription-id>/resourceGroups/<fabric-rg>/providers/Microsoft.Fabric/capacities/<capacity-name>
```

**✅ Success indicator:** Command completes without errors.

### 2.3 Grant Power BI Workspace Access

**Why:** The Logic App needs to read capacity metrics from the Capacity Metrics App dataset.

**Primary Method: Workspace Access (Recommended)**

1. Go to **Power BI Service**: https://app.powerbi.com
2. Navigate to the workspace where you installed Capacity Metrics App
3. Click the **Workspace settings** (gear icon)
4. Click **Manage access**
5. Click **+ Add people or groups**
6. In the search box, paste the **Logic App's Principal ID** (from deployment output)
7. The Logic App will appear (named `fabricautoscale-*`)
8. Assign it the **Viewer** role (or Member if you prefer)
9. Click **Add**

**✅ Success indicator:** Logic App appears in the workspace members list.

**Alternative Method: Enterprise Application Permissions (If Required by Organization)**

If your organization requires explicit API permissions:

1. Go to **Azure Portal** > **Azure Active Directory** > **Enterprise applications**
2. **Remove all filters** (click the X next to "Application type == Enterprise Applications")
3. Search for the **Principal ID** from deployment output
4. Click on the matching application
5. Click **Permissions** (under Security) > **+ Add a permission**
6. Click **APIs my organization uses** > Search for **Power BI Service**
7. Click **Application permissions** (NOT Delegated)
8. Check: **Dataset.Read.All** and **Workspace.Read.All**
9. Click **Add permissions**
10. Click **Grant admin consent for {your-tenant}** > **Yes**

**✅ Success indicator:** Permissions show "Granted for {your-tenant}" in green.

---

## Step 3: Verify Deployment

### 3.1 Check Logic App Run History

1. Go to **Azure Portal** > Your resource group > Logic App resource
2. Click **Overview** (left menu)
3. Wait 5 minutes (the recurrence trigger interval)
4. Click **Refresh** to see new runs
5. Click on the most recent run
6. Expand each action to see:
   - ✅ **Get_Current_Capacity_Info**: Should show your capacity details
   - ✅ **Query_Capacity_Metrics**: Should return utilization data
   - ✅ **For_Each_Metric_Row**: Should loop through data points

**Expected Result:** All actions show green checkmarks (succeeded).

### 3.2 Verify Metrics Query

In the run history, expand **Query_Capacity_Metrics** action:

**Output should look like:**
```json
{
  "results": [
    {
      "tables": [
        {
          "rows": [
            ["2024-01-15T10:15:00", 45.2],
            ["2024-01-15T10:10:00", 43.8],
            ["2024-01-15T10:05:00", 47.1]
          ]
        }
      ]
    }
  ]
}
```

**Troubleshooting if empty:**
- Dataset ID may be incorrect → See [Troubleshooting: Invalid Dataset ID](#invalid-dataset-id)
- Capacity Metrics App may not have data yet → Wait 24-48 hours after app installation

---

## Troubleshooting

### Invalid Dataset ID

**Error:** `"Dataset 'CFafbeb4-7a8b-43d7-a3d3-0a8f8c6b0e85' not found"`

**Solution:**
1. Go to **Power BI Service** > Your workspace
2. Find **Microsoft Fabric Capacity Metrics** dataset
3. Click **⋮** (More options) > **Settings**
4. Copy the **Dataset ID** from the URL: `https://app.powerbi.com/groups/{workspace-id}/datasets/{dataset-id}/...`
5. Go to **Azure Portal** > Logic App > **Logic app designer**
6. Expand **Query_Capacity_Metrics** action
7. In the URI field, replace the dataset ID:
   ```
   https://api.powerbi.com/v1.0/myorg/groups/@{parameters('fabricWorkspaceId')}/datasets/YOUR-DATASET-ID/executeQueries
   ```
8. Click **Save**

### Office 365 Connection Failed

**Error:** `"The API connection 'office365' is not authorized"`

**Solution:** Re-authorize the connection (see [Step 2.1](#21-authorize-office-365-connection))

### No Metrics Data Returned

**Possible Causes:**
1. **Capacity Metrics App not installed** → Install from Power BI AppSource
2. **App installed recently** → Wait 24-48 hours for data collection
3. **Capacity name mismatch** → Verify exact name (case-sensitive)
4. **Wrong workspace ID** → Double-check from workspace URL

### Scaling Not Happening

**Checklist:**
- [ ] At least 3 data points exceed threshold in sustained period
- [ ] Current SKU is different from target SKU (won't scale if already at target)
- [ ] Contributor role assigned on Fabric capacity
- [ ] Check Logic App run history for condition evaluation results

---

## Configuration Reference

### Default Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `scaleUpThreshold` | 80 | CPU % to trigger scale up |
| `scaleDownThreshold` | 30 | CPU % to trigger scale down |
| `scaleUpSku` | F128 | SKU to scale up to |
| `scaleDownSku` | F64 | SKU to scale down to |
| `sustainedMinutes` | 15 | Minutes threshold must be sustained |
| `checkIntervalMinutes` | 5 | How often to check metrics |

### Customizing Parameters

**After deployment**, you can change parameters:

1. Go to **Logic App** > **Logic app designer**
2. Click on any action that uses a parameter (e.g., **Check_Scale_Up_Condition**)
3. Parameters are shown as `@parameters('scaleUpThreshold')`
4. To change values:
   - Go to **Logic App** > **Overview** > **JSON View** (top toolbar)
   - Find the `"parameters"` section at the bottom
   - Update the `"value"` fields
   - Click **Save**

**Or** redeploy with new parameter values.

### Available Fabric SKUs

Valid values for `scaleUpSku` and `scaleDownSku`:
- F2, F4, F8, F16, F32, F64, F128, F256, F512, F1024, F2048

**Note:** Can only scale between SKUs in the same family (Fabric F SKUs).

---

## Monitoring

### View Scaling History

1. Go to **Logic App** > **Overview**
2. Filter runs by **Status: Succeeded**
3. Look for runs where scaling occurred:
   - Expand **Send_ScaleUp_Email** or **Send_ScaleDown_Email** actions
   - These only appear when scaling happened

### Email Notifications

After scaling, you'll receive an email:

**Subject:** `Fabric Capacity Scaled UP - my-capacity`

**Contents:**
- Action: SCALED UP / SCALED DOWN
- Previous SKU: F64
- New SKU: F128
- Trigger: 4 violations over 15 minutes
- Average Utilization: 87.3%
- Threshold: 80%
- Timestamp: 2024-01-15 10:15:00 UTC

### Application Insights

Advanced monitoring:
1. Go to **Application Insights** resource (in same resource group)
2. Click **Logs** (left menu)
3. Query example:
   ```kql
   requests
   | where timestamp > ago(24h)
   | summarize count() by name, resultCode
   ```

---

## Cost Optimization

**Current configuration:**
- Check interval: 5 minutes
- Monthly runs: 8,640 runs
- Estimated cost: ~$89/month

**To reduce costs:**

1. **Increase check interval** to 10 minutes:
   - Halves the number of runs
   - Reduces cost to ~$45/month
   - Trade-off: Slower response to capacity changes

2. **Disable during off-hours:**
   - Add a condition to the trigger
   - Only run during business hours (e.g., 8am-6pm Mon-Fri)
   - Can reduce costs by 60-70%

---

## Uninstall

To remove all resources:

```bash
# Delete the resource group (removes everything)
az group delete --name rg-fabricautoscale --yes --no-wait

# Or delete individual resources
az logic workflow delete --resource-group rg-fabricautoscale --name fabricautoscale-xyz123
```

**Don't forget to:**
- Remove role assignment from Fabric capacity (if resource group still exists)
- Delete the Office 365 API connection

---

## Next Steps

1. ✅ Monitor run history for 24 hours
2. ✅ Verify scaling works during high load
3. ✅ Adjust thresholds based on your workload patterns
4. ✅ Consider adding more SKU tiers for granular scaling
5. ✅ Set up alerts in Application Insights for failures

---

## Support

**Issues:**
- GitHub Issues: [Create an issue](https://github.com/YOUR_USERNAME/Fabric-AutoScale-LogicApp/issues)
- Documentation: See README.md and ARCHITECTURE-CHANGE.md

**Common Questions:**

**Q: How long after high load will scaling occur?**  
A: Minimum 15 minutes (default sustained period) + up to 5 minutes (check interval) = 15-20 minutes total.

**Q: Will it scale down immediately when load drops?**  
A: No, same sustained logic applies. Must stay below threshold for 15 minutes with ≥3 violations.

**Q: Can I scale multiple capacities?**  
A: Currently, each deployment monitors one capacity. Deploy multiple Logic Apps for multiple capacities.

**Q: What if I need to pause auto-scaling?**  
A: Disable the Logic App: Azure Portal > Logic App > Overview > **Disable** button.

---

**Deployment complete! Your Fabric capacity will now auto-scale based on utilization. 🚀**
