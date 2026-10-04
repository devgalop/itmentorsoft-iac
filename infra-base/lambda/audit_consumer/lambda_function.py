import json
import os
import time
import uuid

import boto3

table = boto3.resource("dynamodb").Table(os.environ["AUDIT_TABLE_NAME"])


def lambda_handler(event, context):
    for record in event.get("Records", []):
        body = json.loads(record["body"])

        event_id = str(body.get("event_id") or uuid.uuid4())
        item = {
            "event_id": event_id,
            "timestamp": body.get("timestamp", int(time.time())),
            "actor_id": body.get("actor_id", "system"),
            "action": body.get("action", "UNKNOWN"),
            "resource_type": body.get("resource_type", "UNKNOWN"),
            "resource_id": body.get("resource_id", "UNKNOWN"),
            "payload": body.get("payload", {}),
            "source": body.get("source", "UNKNOWN"),
            "message": body.get("message", ""),
            "ttl": int(time.time()) + 60 * 60 * 24 * 30,
        }

        table.put_item(Item=item)

    return {"statusCode": 200}
