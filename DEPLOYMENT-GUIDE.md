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

**IMPORTANT: Member Role Required**

> The Logic App requires **Member** role (not Viewer) to execute DAX queries via the Power BI REST API. Viewer access will result in authorization errors.

**Primary Method: Workspace Access (Recommended)**

1. Go to **Power BI Service**: https://app.powerbi.com
2. Navigate to the workspace where you installed Capacity Metrics App
3. Click the **Workspace settings** (gear icon)
4. Click **Manage access**
5. Click **+ Add people or groups**
6. In the search box, paste the **Logic App's Principal ID** (from deployment output)
7. The Logic App will appear (named `fabricautoscale-*`)
8. Assign it the **Member** role
9. Click **Add**

**✅ Success indicator:** Logic App appears in the workspace members list with Member role.

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
            {
              "Usage Summary (Last 1 hour)[Timestamp]": "2024-01-15T10:15:00",
              "Usage Summary (Last 1 hour)[Average CU %]": 45.2
            },
            {
              "Usage Summary (Last 1 hour)[Timestamp]": "2024-01-15T10:14:30",
              "Usage Summary (Last 1 hour)[Average CU %]": 43.8
            },
            {
              "Usage Summary (Last 1 hour)[Timestamp]": "2024-01-15T10:14:00",
              "Usage Summary (Last 1 hour)[Average CU %]": 47.1
            }
          ]
        }
      ]
    }
  ]
}
```

**Notes:**
- Data points are at 30-second intervals (perfect granularity for monitoring)
- Query returns last 40 data points (20 minutes of history)
- Each row contains timestamp and utilization percentage

**Troubleshooting if empty:**
- Dataset ID may be incorrect → See [Troubleshooting: Invalid Dataset ID](#invalid-dataset-id)
- Capacity Metrics App may not have data yet → Wait 24-48 hours after app installation
- Workspace access insufficient → Ensure Member role assigned (see Step 2.3)

---

## Troubleshooting

### Invalid Dataset ID

**Error:** `"Dataset '{dataset-id}' not found"` or `"PowerBIEntityNotFound"`

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

### Authorization Errors

**Error:** `"PowerBIEntityNotFound"` or `"Authorization has been denied"`

**Solution:**
1. Verify Logic App has **Member** role in Power BI workspace (not Viewer)
2. Go to Power BI Service > Workspace > Manage access
3. Find the Logic App (by Principal ID)
4. Change role to **Member**
5. Wait 2-3 minutes for permissions to propagate
6. Retry the Logic App run

### Office 365 Connection Failed

**Error:** `"The API connection 'office365' is not authorized"`

**Solution:** Re-authorize the connection (see [Step 2.1](#21-authorize-office-365-connection))

### No Metrics Data Returned

**Possible Causes:**
1. **Capacity Metrics App not installed** → Install from Power BI AppSource
2. **App installed recently** → Wait 24-48 hours for data collection
3. **Capacity name mismatch** → Verify exact name (case-sensitive)
4. **Wrong workspace ID** → Double-check from workspace URL

### Error: Calculate_ScaleUp_Cutoff_Time - Invalid Datetime String

**Error Message:**
```
InvalidTemplate: Unable to process template language expressions in action 'Calculate_ScaleUp_Cutoff_Time'
inputs at line '0' and column '0': 'In function 'addMinutes', the value provided for date time string '' 
was not valid. The datetime string must match ISO 8601 format.'
```

**Cause**: 
This occurs when the Capacity Metrics dataset has no data available, typically right after:
- Resuming a paused capacity
- First deployment before capacity has generated metrics
- Capacity was inactive/paused overnight

When there's no data, the `maxTimestamp` variable remains empty, and the cutoff time calculation fails.

**Solution**:
- **Wait 5-10 minutes** after resuming the capacity for metrics data to populate
- The error will resolve automatically on the next Logic App run once data is available
- For **always-running production capacities**, this error should not occur
- If persistent, verify the Capacity Metrics App is properly installed and collecting data

**Note**: This is a known limitation when working with paused/resumed capacities and does not affect normal operations.

### Scaling Not Happening

**Checklist:**
- [ ] Threshold conditions met:
  - **Scale-UP**: Average utilization ≥ 100% over last 5 minutes
  - **Scale-DOWN**: Average utilization ≤ 45% over last 15 minutes (AND scale-up NOT triggered)
- [ ] Current SKU is different from target SKU (won't scale if already at target)
- [ ] Contributor role assigned on Fabric capacity (see Step 2.2)
- [ ] Check Logic App run history:
  - Expand **Determine_Scaling_Action** to see decision: "SCALE_UP", "SCALE_DOWN", or "NONE"
  - Expand **Calculate_ScaleUp_Average** to see 5-minute average
  - Expand **Calculate_ScaleDown_Average** to see 15-minute average
  - Check **scaleUpCount** and **scaleDownCount** variables for data points evaluated

**Understanding the Logic:**
- The Logic App queries the last hour of capacity metrics data
- It finds the newest timestamp and calculates two evaluation windows:
  - **Scale-up window**: Last 5 minutes from newest data point
  - **Scale-down window**: Last 15 minutes from newest data point
- Calculates average utilization for each window
- **Decision logic**:
  - IF scale-up average ≥ 100% → **SCALE UP** (priority)
  - ELSE IF scale-down average ≤ 45% → **SCALE DOWN**
  - ELSE → **DO NOTHING**
- This prevents flip-flopping by giving scale-up priority over scale-down

---

## Known Issues & Limitations

### Empty Data After Capacity Resume

**Issue**: If you run the Logic App immediately after resuming a paused capacity, you may see this error:

```
InvalidTemplate: Unable to process template language expressions in action 'Calculate_ScaleUp_Cutoff_Time'... 
The datetime string must match ISO 8601 format.
```

**Cause**: When a capacity is paused, no metrics data is collected. The Capacity Metrics App needs time to populate data after resuming.

**Solution**: 
- Wait 5-10 minutes after resuming the capacity before the Logic App runs
- The error will resolve automatically once data is available
- This typically only affects capacities that are frequently paused/resumed
- For always-running production capacities, this is not an issue

### Data Latency

Capacity Metrics data typically has a 5-6 minute lag. This is normal and factored into the evaluation logic (already noted in the "How It Works" section of the README).

---

## Customization Examples

### Different Thresholds for Business Hours

You can edit the Logic App to add time-based conditions for more aggressive scaling during business hours:

**Example approach:**
- Add a **Condition** action to check current time
- **Business hours path** (e.g., 8 AM - 6 PM weekdays):
  - Scale up threshold: 70%
  - Scale up window: 3 minutes
  - More aggressive scaling when users are active
- **Off-hours path** (evenings, weekends):
  - Scale up threshold: 85%
  - Scale up window: 10 minutes
  - More conservative scaling to save costs

**Implementation:**
1. Open Logic App Designer
2. Add a **Condition** action before `Determine_Scaling_Action`
3. Use expression: `@less(utcNow('HH'), 18)` to check if before 6 PM
4. Duplicate scaling logic in each branch with different parameters

### Multi-Tier Scaling

Add nested conditions to scale to different SKUs based on utilization levels:

**Example tiered scaling:**
- Utilization ≥ 90% → Scale to F256 (high demand)
- Utilization ≥ 80% → Scale to F128 (moderate demand)
- Utilization ≥ 70% → Scale to F64 (normal demand)
- Utilization < 40% → Scale down to F32 (low demand)

**Implementation:**
1. Modify the `Execute_Scaling_Decision` Switch action
2. Add additional cases for different utilization ranges
3. Calculate multiple threshold averages
4. Create more granular scaling rules

**Considerations:**
- More tiers = more complexity in monitoring
- Ensure sufficient time windows to prevent rapid tier hopping
- Consider cost vs. performance trade-offs for each tier

---

## Configuration Reference

### Default Parameters

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `scaleUpThreshold` | 100 | CPU % to trigger scale up |
| `scaleDownThreshold` | 45 | CPU % to trigger scale down |
| `scaleUpSku` | F128 | SKU to scale up to |
| `scaleDownSku` | F64 | SKU to scale down to |
| `scaleUpMinutes` | 5 | Evaluation window for scale-UP (max: 15) |
| `scaleDownMinutes` | 15 | Evaluation window for scale-DOWN (max: 30) |
| `checkIntervalMinutes` | 5 | How often to check metrics |

**Note on Timing:**
- `scaleUpMinutes = 5` evaluates the last 5 minutes of data (~10 data points at 30-second intervals)
- `scaleDownMinutes = 15` evaluates the last 15 minutes of data (~30 data points)
- Longer scale-down window provides more conservative behavior
- **Intelligent decision logic** prevents flip-flopping:
  - Scale-up takes priority when both conditions are met
  - Scale-down only triggers when scale-up is NOT triggered
  - Separate windows allow quick response to demand but conservative scale-down

### Customizing Parameters

**After deployment**, you can change parameters in the Azure Portal:

1. Go to **Logic App** > **Parameters** (left menu under Settings)
2. Edit parameter values directly:
   - `scaleUpThreshold`, `scaleDownThreshold`
   - `scaleUpSku`, `scaleDownSku`
   - `scaleUpMinutes`, `scaleDownMinutes`
3. Click **Save**

**Or** via Logic App Designer:
1. Go to **Logic App** > **Logic app designer**
2. Parameters are referenced as `@parameters('parameterName')`
3. To view/change: **Workflow settings** (top toolbar)
4. Click **Save**

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
- **Action**: SCALED UP / SCALED DOWN
- **Capacity**: my-capacity
- **Previous SKU**: F64
- **New SKU**: F128
- **Trigger Analysis**:
  - Evaluation Window: Last 5 minutes (scale-up) or Last 15 minutes (scale-down)
  - Data Points Evaluated: 10 points (scale-up) or 30 points (scale-down)
  - Average Utilization: 105.3%
  - Threshold: 100% (scale-up) or 45% (scale-down)
- **Data Window**:
  - Cutoff Time: 2024-11-06T14:35:00 (earliest data point in evaluation window)
  - Newest Data Point: 2024-11-06T14:40:00 (most recent data available)
  - Total Data Points Retrieved: 119 (full hour of data)

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
- Actions per run: ~10 (query, parse, conditions, etc.)
- Total actions: ~86,400/month
- **Estimated cost: ~$5-6/month**
  - Logic App: ~$2-3/month ($0.000025 per action after first 4,000 free)
  - Storage: ~$0.02/month
  - Application Insights: ~$2.88/month (first 5GB free)

**To reduce costs:**

1. **Increase check interval** to 10 minutes:
   - Halves the number of runs (4,320 runs/month)
   - Reduces Logic App cost to ~$1-2/month
   - **Total: ~$4/month**
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
- GitHub Issues: [Create an issue](https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp/issues)
- Documentation: See README.md and this DEPLOYMENT-GUIDE.md

**Common Questions:**

**Q: How long after high load will scaling occur?**  
A: With default settings (5-minute check interval, 5-minute scale-up window): 0-10 minutes total. The Logic App must run, detect the high utilization over the 5-minute window, and trigger scaling.

**Q: Will it scale down immediately when load drops?**  
A: No, requires sustained low utilization for 15 minutes (default scale-down window) AND the scale-up condition must NOT be met. This prevents flip-flopping.

**Q: What prevents the system from flip-flopping between scale-up and scale-down?**  
A: Intelligent decision logic: Scale-up always takes priority when its threshold is met. Scale-down only happens when scale-up is NOT triggered. Plus, separate time windows (5 min vs 15 min) make scale-up responsive but scale-down conservative.

**Q: Can I scale multiple capacities?**  
A: Currently, each deployment monitors one capacity. Deploy multiple Logic Apps for multiple capacities.

**Q: What if I need to pause auto-scaling?**  
A: Disable the Logic App: Azure Portal > Logic App > Overview > **Disable** button.

**Q: What happens if my capacity was paused and I just resumed it?**  
A: You may see a temporary error about invalid datetime format. Wait 5-10 minutes for the Capacity Metrics App to collect data, then the error will resolve on the next run.

---

**Deployment complete! Your Fabric capacity will now auto-scale based on utilization. 🚀**
