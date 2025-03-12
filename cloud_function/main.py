import json
from google.cloud import bigquery
import base64
from google.auth import default

credentials, PROJECT_ID = default()

def process_log_data(event, context):
    pubsub_message = json.loads(base64.b64decode(event['data']).decode("utf-8"))
    
    timestamp = context.timestamp 
    log_level = pubsub_message.get("log_level", "INFO")
    message = pubsub_message.get("message", "")
    
    rows_to_insert = [{
        "timestamp": timestamp,
        "log_level": log_level,
        "message": message
    }]
    
    client = bigquery.Client()
    dataset_id = f'{PROJECT_ID}.logs_dataset'
    table_id = 'logs_table'

    errors = client.insert_rows_json(f"{dataset_id}.{table_id}", rows_to_insert)
    
    if errors == []:
        print("Data successfully inserted into BigQuery.")
    else:
        print(f"Errors occurred: {errors}")
