# SpaceX API Example
import os
import json

from datetime import datetime, timedelta, timezone
from dateutil import parser

import boto3
import requests

# from model import SpaceXResponse

URL = "https://api.spacexdata.com/v5/launches/query"




def launch_data(json_data):
    return {
        "id": json_data.get("launched_id"),
        "flight_number": json_data.get("flight_number"),
        "mission_name": json_data.get("mission_name"),
        "rocket_name": json_data.get("rocket"),

        "launch_date": json_data.get("date_utc"),
        "launch_date_precision": json_data.get("date_precision"),
        "static_fire_date": json_data.get("static_fire_date_utc"),
        "launch_window": json_data.get("window"),

        "lauch_status": "upcoming" if json_data.get("upcoming") else ("success" if json_data.get("success", False) else "failed"),
        "launchpad_id": json_data.get("launchpad"),

        "crew": len(json_data.get("crew")) > 0,
        "capsules": len(json_data.get("capsules")) > 0,
        "fairings_reused": json_data.get("fairings", {}).get("reused") if json_data.get("fairings") else None,
        "fairings_recovery_attempt": json_data.get("fairings", {}).get("recovery_attempt") if json_data.get("fairings") else None,
        "fairings_recovered": json_data.get("fairings", {}).get("recovered") if json_data.get("fairings") else None,

        "details": json_data.get("details"),
    }


def lambda_handler(event, context):

    # --- Leer parámetros ---
    utc_date_str = event.get("utc_date")
    offset_seconds = event.get("offset_seconds", 6 * 3600)  # 24 horas por defecto

    # --- Convertir la fecha UTC ---
    if utc_date_str:
        try:
            # end_time = datetime.fromisoformat(utc_date_str.replace("Z", "+00:00"))
            end_time = parser.isoparse(utc_date_str)
        except Exception as e:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": f"Formato de fecha no válido: {str(e)}"})
            }
    else:
        end_time = datetime.now(timezone.utc)

    # --- Calcular start_time ---
    start_time = end_time - timedelta(seconds=offset_seconds)

    # Formatos en ISO para la API
    start_iso = start_time.isoformat()
    end_iso = end_time.isoformat()

    payload = {
        "query": {
            "date_utc": {
                "$gte": start_iso,
                "$lte": end_iso
            }
        },
        "options": {
            "sort": {"date_utc": "asc"}
        }
    }

    try:
        response = requests.post(URL, json=payload)
        data = response.json()
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": f"Error llamando a SpaceX API: {str(e)}"})
        }

    dynamo_items = [ launch_data(item) for item in data.get("docs", []) ]

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])

    with table.batch_writer() as batch:
        for item in dynamo_items:
            batch.put_item(Item=item)

    body = {
        "inserted_items": len(dynamo_items)
    }

    DEV_MODE = os.environ.get("ENVIRONMENT", "dev").lower() == "dev"
    if DEV_MODE:
        body["start_time"] = start_iso
        body["end_time"] = end_iso
        body["lauch_items"] = dynamo_items

    return {
        "statusCode": 200,
        "body": json.dumps(body)
    }
