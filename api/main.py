from fastapi import FastAPI, HTTPException
from google.cloud import pubsub_v1
import json
import logging
import asyncio
from google.auth import default

credentials, PROJECT_ID = default()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(PROJECT_ID, "logs-topic")

@app.post("/logs")
async def ingest_log(log: dict):
    try:
        message = json.dumps(log).encode("utf-8")
        future = publisher.publish(topic_path, message)

        await asyncio.to_thread(future.result)

        return {"status": "Published"}

    except Exception as e:
        logger.error(f"Failed to publish log: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to publish log")
