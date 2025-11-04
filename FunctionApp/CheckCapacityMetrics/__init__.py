"""
Fabric Capacity Auto-Scale Function
Reads metrics from Fabric Capacity Metrics App and determines if scaling is needed
"""
import logging
import json
import os
from datetime import datetime, timedelta
import azure.functions as func
from typing import Dict, List, Any
import requests
from azure.identity import DefaultAzureCredential


def main(req: func.HttpRequest) -> func.HttpResponse:
    """
    HTTP trigger function to check Fabric capacity utilization and recommend scaling actions.
    
    Expected query parameters:
    - capacityName: Name of the Fabric capacity
    - workspaceId: Fabric workspace ID where Capacity Metrics App is installed
    - scaleUpThreshold: Utilization percentage to trigger scale up (default: 80)
    - scaleDownThreshold: Utilization percentage to trigger scale down (default: 40)
    - sustainedMinutes: Minutes the threshold must be sustained (default: 15)
    - currentSku: Current capacity SKU (e.g., F64)
    - scaleUpSku: Target SKU for scale up (e.g., F128)
    - scaleDownSku: Target SKU for scale down (e.g., F32)
    """
    logging.info('Fabric Auto-Scale Function triggered')

    try:
        # Parse request parameters
        capacity_name = req.params.get('capacityName')
        workspace_id = req.params.get('workspaceId')
        scale_up_threshold = int(req.params.get('scaleUpThreshold', 80))
        scale_down_threshold = int(req.params.get('scaleDownThreshold', 40))
        sustained_minutes = int(req.params.get('sustainedMinutes', 15))
        current_sku = req.params.get('currentSku')
        scale_up_sku = req.params.get('scaleUpSku')
        scale_down_sku = req.params.get('scaleDownSku')

        # Validate required parameters
        if not capacity_name or not workspace_id:
            return func.HttpResponse(
                json.dumps({"error": "capacityName and workspaceId are required parameters"}),
                status_code=400,
                mimetype="application/json"
            )

        # Get metrics from Fabric Capacity Metrics App
        metrics_data = get_capacity_metrics(workspace_id, capacity_name, sustained_minutes)
        
        if not metrics_data:
            return func.HttpResponse(
                json.dumps({"error": "Failed to retrieve capacity metrics"}),
                status_code=500,
                mimetype="application/json"
            )

        # Calculate current utilization
        current_utilization = metrics_data.get('currentUtilization', 0)
        
        # Check sustained threshold
        utilization_history = metrics_data.get('history', [])
        sustained_high_count = sum(1 for record in utilization_history if record >= scale_up_threshold)
        sustained_low_count = sum(1 for record in utilization_history if record <= scale_down_threshold)
        
        # Determine scaling action
        should_scale_up = (
            sustained_high_count >= 3 and 
            current_utilization >= scale_up_threshold and 
            current_sku != scale_up_sku
        )
        
        should_scale_down = (
            sustained_low_count >= 3 and 
            current_utilization <= scale_down_threshold and 
            current_sku != scale_down_sku and
            not should_scale_up  # Priority to scale up
        )

        # Prepare response
        response = {
            "shouldScaleUp": should_scale_up,
            "shouldScaleDown": should_scale_down,
            "currentUtilization": round(current_utilization, 2),
            "currentSku": current_sku,
            "scaleUpSku": scale_up_sku,
            "scaleDownSku": scale_down_sku,
            "sustainedHighCount": sustained_high_count,
            "sustainedLowCount": sustained_low_count,
            "thresholds": {
                "scaleUp": scale_up_threshold,
                "scaleDown": scale_down_threshold
            },
            "metrics": {
                "averageUtilization": round(sum(utilization_history) / len(utilization_history), 2) if utilization_history else 0,
                "maxUtilization": round(max(utilization_history), 2) if utilization_history else 0,
                "minUtilization": round(min(utilization_history), 2) if utilization_history else 0,
                "recordCount": len(utilization_history)
            },
            "timestamp": datetime.utcnow().isoformat()
        }

        logging.info(f"Scaling decision: ScaleUp={should_scale_up}, ScaleDown={should_scale_down}, Utilization={current_utilization}%")

        return func.HttpResponse(
            json.dumps(response),
            status_code=200,
            mimetype="application/json"
        )

    except ValueError as e:
        logging.error(f"Parameter validation error: {str(e)}")
        return func.HttpResponse(
            json.dumps({"error": f"Invalid parameter value: {str(e)}"}),
            status_code=400,
            mimetype="application/json"
        )
    except Exception as e:
        logging.error(f"Function execution error: {str(e)}", exc_info=True)
        return func.HttpResponse(
            json.dumps({"error": f"Internal server error: {str(e)}"}),
            status_code=500,
            mimetype="application/json"
        )


def get_capacity_metrics(workspace_id: str, capacity_name: str, lookback_minutes: int) -> Dict[str, Any]:
    """
    Query Fabric Capacity Metrics App for utilization data.
    
    Args:
        workspace_id: Fabric workspace ID where Capacity Metrics App is installed
        capacity_name: Name of the capacity to monitor
        lookback_minutes: How many minutes of history to retrieve
        
    Returns:
        Dictionary with current utilization and historical data
    """
    try:
        # Get access token using Managed Identity
        credential = DefaultAzureCredential()
        token = credential.get_token("https://analysis.windows.net/powerbi/api/.default")
        
        headers = {
            "Authorization": f"Bearer {token.token}",
            "Content-Type": "application/json"
        }
        
        # Calculate time range
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(minutes=lookback_minutes)
        
        # Query Capacity Metrics App using Power BI REST API
        # This assumes the Capacity Metrics App has a semantic model with utilization data
        dax_query = f"""
        EVALUATE
        SUMMARIZECOLUMNS(
            'Timepoint'[Datetime],
            FILTER(
                'Capacities',
                'Capacities'[Capacity Name] = "{capacity_name}"
                && 'Timepoint'[Datetime] >= DATETIME({start_time.year}, {start_time.month}, {start_time.day}, {start_time.hour}, {start_time.minute}, {start_time.second})
                && 'Timepoint'[Datetime] <= DATETIME({end_time.year}, {end_time.month}, {end_time.day}, {end_time.hour}, {end_time.minute}, {end_time.second})
            ),
            "Utilization", [Utilization %]
        )
        ORDER BY 'Timepoint'[Datetime] DESC
        """
        
        # Execute DAX query against the Capacity Metrics semantic model
        # Note: You'll need to get the dataset ID from the Capacity Metrics App workspace
        api_url = f"https://api.powerbi.com/v1.0/myorg/groups/{workspace_id}/datasets/CapacityMetrics/executeQueries"
        
        query_payload = {
            "queries": [
                {
                    "query": dax_query
                }
            ],
            "serializerSettings": {
                "includeNulls": False
            }
        }
        
        response = requests.post(api_url, headers=headers, json=query_payload, timeout=30)
        response.raise_for_status()
        
        result_data = response.json()
        
        # Parse results
        if result_data and "results" in result_data and len(result_data["results"]) > 0:
            rows = result_data["results"][0].get("tables", [{}])[0].get("rows", [])
            
            if rows:
                # Current utilization is the most recent value
                current_utilization = rows[0].get("Utilization %", 0)
                
                # Historical utilization values
                history = [row.get("Utilization %", 0) for row in rows]
                
                return {
                    "currentUtilization": current_utilization,
                    "history": history
                }
        
        # If no data found, return defaults
        logging.warning(f"No metrics data found for capacity {capacity_name}")
        return {
            "currentUtilization": 0,
            "history": []
        }
        
    except requests.exceptions.RequestException as e:
        logging.error(f"Error querying Capacity Metrics App: {str(e)}")
        return None
    except Exception as e:
        logging.error(f"Error in get_capacity_metrics: {str(e)}", exc_info=True)
        return None
