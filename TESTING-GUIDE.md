# Testing Guide - Fabric Auto-Scaling Logic App

This guide will help you test the deployed Logic App to ensure it's working correctly.

## Pre-Testing Checklist

Before testing, ensure:
- [x] Logic App has been deployed successfully
- [x] Office 365 API connection is authorized
- [x] Managed Identity has Contributor role on Fabric capacity
- [x] Logic App is enabled (not disabled)

## Test 1: Manual Logic App Trigger

### Purpose
Verify the Logic App can run without errors.

### Steps

1. **Navigate to the Logic App in Azure Portal**
   ```
   Azure Portal → Resource Groups → [Your RG] → FabricAutoScaleLogicApp
   ```

2. **Trigger a manual run**
   - Click **Overview** in the left menu
   - Click **Run Trigger** at the top
   - Select **Recurrence**
   - Click **Run**

3. **Monitor the execution**
   - The run will appear in the **Runs history** section
   - Wait for the run to complete (usually 30-60 seconds)
   - Status should show as **Succeeded** (green checkmark)

4. **Review the run details**
   - Click on the completed run
   - Verify each action completed successfully:
     - ✅ Get_Current_Capacity_Info
     - ✅ Parse_Capacity_Info
     - ✅ Get_Capacity_Metrics
     - ✅ Parse_Metrics
     - ✅ Check_Scale_Up_Condition

### Expected Results
- All actions show green checkmarks
- No red error indicators
- The condition check evaluates correctly (may scale or not based on current metrics)

### Troubleshooting
If the run fails:
- Click on the failed action to see error details
- Common issues:
  - **401 Unauthorized**: Managed Identity permissions not set
  - **404 Not Found**: Capacity name is incorrect
  - **Connection error**: API connection not authorized

---

## Test 2: Verify Metrics Collection

### Purpose
Ensure the Logic App can successfully retrieve Fabric capacity metrics.

### Steps

1. **Open the most recent successful run**
2. **Click on the "Get_Capacity_Metrics" action**
3. **Review the Outputs**
   - Click **Show raw outputs**
   - Look for the `body` section
   - Verify it contains metric data

### Expected Results
```json
{
  "cost": 0,
  "timespan": "...",
  "interval": "PT1M",
  "value": [
    {
      "id": "...",
      "type": "Microsoft.Insights/metrics",
      "name": {
        "value": "Overload",
        "localizedValue": "Overload"
      },
      "unit": "Count",
      "timeseries": [...]
    }
  ]
}
```

### Troubleshooting
- If `value` array is empty, check that the Fabric capacity is actively processing workloads
- Metrics may not be available for new/idle capacities

---

## Test 3: Email Notification Test

### Purpose
Verify email notifications are sent when scaling occurs.

### Prerequisites
- The capacity must be in a state where scaling will occur
- Or, temporarily modify the template to always send test emails

### Steps

1. **Modify the Logic App for testing** (optional)
   - Go to Logic App Designer
   - Find the "Check_Scale_Up_Condition"
   - Temporarily change the condition to always be true for testing
   - Save the Logic App

2. **Trigger a run**
   - Use Test 1 steps to run the Logic App

3. **Check your email**
   - Look for an email with subject: "Fabric Capacity Scaled Up" or "Fabric Capacity Scaled Down"
   - Verify the email contains:
     - Capacity name
     - New SKU
     - Previous SKU
     - Timestamp

4. **Revert the Logic App changes**
   - Restore the original condition logic

### Expected Results
- Email received within 1-2 minutes of scaling action
- Email contains accurate capacity information
- Email is formatted correctly (HTML formatting intact)

### Troubleshooting
- **No email received**: 
  - Check Logic App run history for "Send_Email_Scale_Up" action status
  - Verify Office 365 connection is authorized
  - Check spam/junk folder
  - Verify email address is correct

---

## Test 4: Email Notification Test

### Purpose
Verify email notifications are sent when scaling occurs.

### Steps

1. **Trigger a scaling event** (see Test 3)

2. **Check your email inbox**
   - Check the email address configured during deployment
   - Look for an email with subject containing "Fabric Capacity Scaled"
   - Verify the email contains:
     - Scaling direction (UP or DOWN)
     - Capacity name
     - Old and new SKUs
     - Timestamp

### Expected Results
- Email is received at the configured address
- Contains accurate capacity details
- Formatted properly with all relevant information

### Troubleshooting
- **No email received**:
  - Check spam/junk folder
  - Verify the email address is correct in deployment parameters
  - Ensure Office 365 connection is authorized (see DEPLOYMENT-GUIDE.md Step 3.1)
  - Check Logic App run history for email action errors
  - Verify your Office 365 account has permission to send emails

---

## Test 5: Managed Identity Authentication

### Purpose
Verify the Managed Identity can authenticate to Azure Management API.

### Steps

1. **Check the "Get_Current_Capacity_Info" action**
   - Open a successful Logic App run
   - Click on "Get_Current_Capacity_Info"
   - Review the request headers
   - Verify `authentication` is set to `ManagedServiceIdentity`

2. **Verify role assignments**
   ```bash
   # Get the Logic App's Managed Identity Principal ID
   PRINCIPAL_ID=$(az resource show \
     --resource-group YOUR_RG \
     --name FabricAutoScaleLogicApp \
     --resource-type Microsoft.Logic/workflows \
     --query identity.principalId -o tsv)
   
   # List role assignments
   az role assignment list \
     --assignee $PRINCIPAL_ID \
     --output table
   ```

3. **Verify output includes**
   - Role: **Contributor**
   - Scope: Contains your Fabric capacity resource path

### Expected Results
- Managed Identity has Contributor role
- API calls succeed without authentication errors

### Troubleshooting
- **401 errors**: Role assignment missing or incorrect
- **403 errors**: Insufficient permissions (need Contributor, not Reader)

---

## Test 6: Scaling Operation Test

### Purpose
Verify the Logic App can successfully scale the Fabric capacity.

### ⚠️ WARNING
This test will actually change your Fabric capacity SKU. Ensure you understand the cost implications.

### Steps

1. **Record current capacity SKU**
   ```bash
   az fabric capacity show \
     --resource-group YOUR_RG \
     --name YOUR_CAPACITY \
     --query sku.name -o tsv
   ```

2. **Temporarily modify scale conditions**
   - Edit the Logic App in Designer
   - Change the threshold to force a scale operation
   - Save

3. **Run the Logic App**
   - Trigger manually
   - Wait for completion

4. **Verify the capacity was scaled**
   ```bash
   az fabric capacity show \
     --resource-group YOUR_RG \
     --name YOUR_CAPACITY \
     --query sku.name -o tsv
   ```

5. **Scale back if needed**
   ```bash
   az fabric capacity update \
     --resource-group YOUR_RG \
     --name YOUR_CAPACITY \
     --sku ORIGINAL_SKU
   ```

6. **Revert Logic App changes**

### Expected Results
- Capacity SKU changes successfully
- "Scale_Up" or "Scale_Down" action shows success
- Notifications are sent
- Capacity is operational after scaling

### Troubleshooting
- **409 Conflict**: Capacity is already at target SKU or currently updating
- **400 Bad Request**: Invalid SKU name
- **Timeout**: Large capacity changes may take several minutes

---

## Test 7: Recurrence Trigger Test

### Purpose
Verify the Logic App runs automatically on schedule.

### Steps

1. **Ensure Logic App is enabled**
   - Go to Logic App Overview
   - Status should show as "Enabled"

2. **Wait for the next scheduled run** (5 minutes)

3. **Check Runs history**
   - Refresh the page
   - A new run should appear automatically
   - Timestamp should match the recurrence interval

4. **Monitor for 15-30 minutes**
   - Verify multiple runs occur
   - Each run should be ~5 minutes apart

### Expected Results
- Runs occur every 5 minutes automatically
- No manual intervention needed
- Consistent execution pattern

### Troubleshooting
- **No automatic runs**: Check if Logic App is disabled
- **Irregular timing**: Check trigger configuration
- **Runs stopped**: Check for quota limits or billing issues

---

## Test 8: Error Handling Test

### Purpose
Verify the Logic App handles errors gracefully.

### Steps

1. **Introduce a temporary error**
   - Option A: Revoke Managed Identity permissions temporarily
   - Option B: Change capacity name to an invalid value
   - Option C: Disable Office 365 connection authorization

2. **Run the Logic App**

3. **Verify error is logged**
   - Check Runs history
   - Status should show as "Failed"
   - Click on the run to see which action failed

4. **Review error details**
   - Click on failed action
   - Review error message and status code

5. **Fix the error**
   - Restore permissions/configuration
   - Run again to verify it succeeds

### Expected Results
- Errors are clearly logged
- Error messages are descriptive
- Logic App can recover after fix

---

## Test 9: Performance Test

### Purpose
Verify the Logic App completes execution within acceptable time.

### Steps

1. **Run the Logic App 5 times**

2. **Record execution times**
   - Click on each run in Runs history
   - Note the duration at the top

3. **Calculate average duration**

### Expected Results
- Average duration: 15-45 seconds
- No timeout errors
- Consistent performance across runs

### Troubleshooting
- **Slow execution**: Check API response times
- **Timeouts**: Increase timeout settings in HTTP actions

---

## Test 10: End-to-End Integration Test

### Purpose
Complete workflow test simulating real-world scenario.

### Scenario
Monitor the Logic App during a period of high Fabric capacity usage.

### Steps

1. **Ensure Logic App is running on schedule**

2. **Generate load on Fabric capacity** (if possible)
   - Run reports, queries, or other Fabric workloads
   - Increase utilization to trigger scaling

3. **Monitor for 1-2 hours**
   - Watch Runs history
   - Check for scaling events
   - Verify notifications

4. **Document the behavior**
   - When did scaling occur?
   - Was it appropriate?
   - Did notifications arrive?
   - Did capacity stabilize?

### Expected Results
- Logic App responds to actual load changes
- Scaling occurs at appropriate thresholds
- Notifications are timely and accurate
- System remains stable

---

## Validation Checklist

After testing, verify:

- [ ] Logic App runs successfully on schedule
- [ ] Metrics are collected correctly
- [ ] Scaling operations work (tested or verified capable)
- [ ] Email notifications are received
- [ ] Managed Identity authentication works
- [ ] Error handling is appropriate
- [ ] Performance is acceptable
- [ ] All configurations are documented
- [ ] Rollback procedures are tested

---

## Monitoring Dashboard Setup

Create a dashboard to monitor the Logic App:

1. **Go to Azure Portal → Dashboard → New dashboard**
2. **Add tiles**:
   - Logic App runs (success/failure)
   - Fabric capacity metrics
   - Logic App performance
   - Cost analysis

3. **Pin the dashboard** for quick access

---

## Continuous Monitoring

Set up regular checks:

### Daily
- Review Logic App Runs history for failures
- Check email for unexpected scaling events

### Weekly
- Review scaling patterns
- Analyze capacity utilization trends
- Validate cost vs. performance

### Monthly
- Review and adjust thresholds if needed
- Update documentation
- Review and renew API connections if needed

---

## Test Results Template

Document your test results:

```markdown
## Test Results - [Date]

### Test 1: Manual Trigger
- Status: ✅ PASS / ❌ FAIL
- Notes: 

### Test 2: Metrics Collection
- Status: ✅ PASS / ❌ FAIL
- Notes:

### Test 3: Email Notifications
- Status: ✅ PASS / ❌ FAIL
- Notes:

### Test 4: Email Notifications
- Status: ✅ PASS / ❌ FAIL
- Notes:

### Test 5: Managed Identity Auth
- Status: ✅ PASS / ❌ FAIL
- Notes:

### Test 6: Scaling Operation
- Status: ✅ PASS / ⚠️ SKIPPED / ❌ FAIL
- Notes:

### Overall Status
- Deployment Ready: YES / NO
- Issues Identified:
- Recommendations:
```

---

## Support

For issues during testing:
1. Check the [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md) troubleshooting section
2. Review Azure Logic App documentation
3. Open an issue on GitHub with test results and logs
