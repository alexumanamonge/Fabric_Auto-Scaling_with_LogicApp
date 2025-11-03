# Example: Azure Monitor Alert for CU Utilization

## Steps:
1. Go to Azure Portal → Monitor → Alerts → New Alert Rule.
2. Select Fabric Capacity resource.
3. Condition:
   - Metric: CU Utilization (%)
   - Operator: Greater than
   - Threshold: 80
   - Aggregation: Average over 10 minutes
4. Action Group:
   - Trigger Logic App or send email.