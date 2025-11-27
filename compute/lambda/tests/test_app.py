import unittest
import json
import sys
import os
from datetime import datetime, timedelta, timezone
from unittest.mock import patch, MagicMock

# Add parent directory to path so we can import app
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import lambda_handler, launch_data


class TestLaunchDataFunction(unittest.TestCase):
    """Test the launch_data helper function"""

    def setUp(self):
        """Set up test fixtures"""
        self.sample_json = {
            "launched_id": "5eb87d04ffd86e000604b353",
            "flight_number": 42,
            "mission_name": "BulgariaSat-1",
            "rocket": "Falcon 9",
            "date_utc": "2017-06-23T19:10:00.000Z",
            "date_precision": "hour",
            "static_fire_date_utc": "2017-06-15T22:25:00.000Z",
            "window": 7200,
            "upcoming": False,
            "success": True,
            "launchpad": "5e9e4502f509094188566f88",
            "crew": [],
            "capsules": [],
            "details": "Test launch details",
            "fairings": {
                "reused": False,
                "recovery_attempt": False,
                "recovered": False,
            }
        }

    def test_launch_data_structure(self):
        """Test that launch_data returns correct structure"""
        result = launch_data(self.sample_json)
        
        self.assertIn("id", result)
        self.assertIn("flight_number", result)
        self.assertIn("mission_name", result)
        self.assertIn("rocket_name", result)
        self.assertIn("launch_date", result)
        self.assertIn("lauch_status", result)
        self.assertIn("crew", result)
        self.assertIn("capsules", result)

    def test_launch_data_values(self):
        """Test that launch_data correctly extracts values"""
        result = launch_data(self.sample_json)
        
        self.assertEqual(result["flight_number"], 42)
        self.assertEqual(result["mission_name"], "BulgariaSat-1")
        self.assertEqual(result["rocket_name"], "Falcon 9")
        self.assertEqual(result["lauch_status"], "success")
        self.assertEqual(result["crew"], False)
        self.assertEqual(result["capsules"], False)

    def test_launch_data_status_upcoming(self):
        """Test launch status for upcoming launch"""
        self.sample_json["upcoming"] = True
        self.sample_json["success"] = False
        result = launch_data(self.sample_json)
        self.assertEqual(result["lauch_status"], "upcoming")

    def test_launch_data_status_failed(self):
        """Test launch status for failed launch"""
        self.sample_json["upcoming"] = False
        self.sample_json["success"] = False
        result = launch_data(self.sample_json)
        self.assertEqual(result["lauch_status"], "failed")


class TestLambdaHandler(unittest.TestCase):
    """Test the main lambda_handler function"""

    def setUp(self):
        """Set up test fixtures"""
        # Mock environment variables
        os.environ["DYNAMODB_TABLE"] = "test-launches-table"
        os.environ["ENVIRONMENT"] = "dev"

    @patch('app.requests.post')
    @patch('app.boto3.resource')
    def test_lambda_handler_success(self, mock_dynamodb, mock_requests):
        """Test successful Lambda execution with SpaceX API response"""
        # Mock SpaceX API response
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "docs": [
                {
                    "id": "5eb87d04ffd86e000604b353",
                    "flight_number": 42,
                    "mission_name": "BulgariaSat-1",
                    "rocket": "Falcon 9",
                    "date_utc": "2017-06-23T19:10:00.000Z",
                    "date_precision": "hour",
                    "upcoming": False,
                    "success": True,
                    "launchpad": "5e9e4502f509094188566f88",
                    "crew": [],
                    "capsules": [],
                    "details": "Test launch",
                    "fairings": {"reused": False, "recovery_attempt": False, "recovered": False}
                }
            ]
        }
        mock_requests.return_value = mock_response

        # Mock DynamoDB
        mock_table = MagicMock()
        mock_dynamodb.return_value.Table.return_value = mock_table

        # Create test event
        event = {
            "offset_seconds": 2592000  # 30 days in seconds
        }

        # Call lambda handler
        response = lambda_handler(event, None)

        # Assertions
        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertIn("inserted_items", body)
        self.assertEqual(body["inserted_items"], 1)
        self.assertIn("start_time", body)  # DEV_MODE includes these
        self.assertIn("end_time", body)
        self.assertIn("lauch_items", body)

    @patch('app.requests.post')
    @patch('app.boto3.resource')
    def test_lambda_handler_with_custom_date(self, mock_dynamodb, mock_requests):
        """Test Lambda with custom UTC date parameter"""
        mock_response = MagicMock()
        mock_response.json.return_value = {"docs": []}
        mock_requests.return_value = mock_response

        mock_table = MagicMock()
        mock_dynamodb.return_value.Table.return_value = mock_table

        # Create test event with custom UTC date
        custom_date = "2025-11-01T00:00:00+00:00"
        event = {
            "utc_date": custom_date,
            "offset_seconds": 604800  # 7 days in seconds
        }

        response = lambda_handler(event, None)

        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertEqual(body["inserted_items"], 0)

    @patch('app.requests.post')
    @patch('app.boto3.resource')
    def test_lambda_handler_api_error(self, mock_dynamodb, mock_requests):
        """Test Lambda when SpaceX API fails"""
        mock_requests.side_effect = Exception("Connection error")

        event = {"offset_seconds": 2592000}

        response = lambda_handler(event, None)

        self.assertEqual(response["statusCode"], 500)
        body = json.loads(response["body"])
        self.assertIn("error", body)

    @patch('app.requests.post')
    @patch('app.boto3.resource')
    def test_lambda_handler_invalid_date(self, mock_dynamodb, mock_requests):
        """Test Lambda with invalid date format"""
        event = {
            "utc_date": "invalid-date",
            "offset_seconds": 2592000
        }

        response = lambda_handler(event, None)

        self.assertEqual(response["statusCode"], 400)
        body = json.loads(response["body"])
        self.assertIn("error", body)
        self.assertIn("Formato de fecha no válido", body["error"])

    @patch('app.requests.post')
    @patch('app.boto3.resource')
    def test_lambda_handler_multiple_launches(self, mock_dynamodb, mock_requests):
        """Test Lambda with multiple launches from API"""
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "docs": [
                {
                    "id": "launch1",
                    "flight_number": 42,
                    "mission_name": "BulgariaSat-1",
                    "rocket": "Falcon 9",
                    "date_utc": "2017-06-23T19:10:00.000Z",
                    "date_precision": "hour",
                    "upcoming": False,
                    "success": True,
                    "launchpad": "5e9e4502f509094188566f88",
                    "crew": [],
                    "capsules": [],
                    "details": "Test launch 1",
                    "fairings": {"reused": False, "recovery_attempt": False, "recovered": False}
                },
                {
                    "id": "launch2",
                    "flight_number": 43,
                    "mission_name": "Test-2",
                    "rocket": "Falcon 9",
                    "date_utc": "2017-07-01T10:00:00.000Z",
                    "date_precision": "hour",
                    "upcoming": False,
                    "success": True,
                    "launchpad": "5e9e4502f509094188566f88",
                    "crew": [],
                    "capsules": [],
                    "details": "Test launch 2",
                    "fairings": {"reused": False, "recovery_attempt": False, "recovered": False}
                }
            ]
        }
        mock_requests.return_value = mock_response

        mock_table = MagicMock()
        mock_dynamodb.return_value.Table.return_value = mock_table

        event = {"offset_seconds": 2592000}
        response = lambda_handler(event, None)

        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertEqual(body["inserted_items"], 2)

    @patch('app.requests.post')
    @patch('app.boto3.resource')
    def test_lambda_handler_prod_mode(self, mock_dynamodb, mock_requests):
        """Test Lambda in production mode (no detailed response)"""
        # Set production environment
        os.environ["ENVIRONMENT"] = "prod"

        mock_response = MagicMock()
        mock_response.json.return_value = {"docs": []}
        mock_requests.return_value = mock_response

        mock_table = MagicMock()
        mock_dynamodb.return_value.Table.return_value = mock_table

        event = {"offset_seconds": 2592000}
        response = lambda_handler(event, None)

        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertNotIn("start_time", body)  # PROD_MODE doesn't include these
        self.assertNotIn("end_time", body)
        self.assertNotIn("lauch_items", body)

        # Reset to dev mode
        os.environ["ENVIRONMENT"] = "dev"


class TestLambdaHandlerWithoutRequestsMock(unittest.TestCase):
    """Test the main lambda_handler function without mocking requests"""

    def setUp(self):
        """Set up test fixtures"""
        # Mock environment variables
        os.environ["DYNAMODB_TABLE"] = "test-launches-table"
        os.environ["ENVIRONMENT"] = "dev"
    
    @patch('app.boto3.resource')
    def test_lambda_handler_real_api_call(self, mock_dynamodb):
        """Test Lambda execution with real SpaceX API call"""
        event = {"offset_seconds": 2592000}  # 30 days in seconds
        response = lambda_handler(event, None)

        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertIn("inserted_items", body)
        self.assertIn("start_time", body)
        self.assertIn("end_time", body)
        self.assertIn("lauch_items", body)


    @patch('app.boto3.resource')
    def test_lambda_handler_real_api_call_endtime(self, mock_dynamodb):
        """Test Lambda execution with real SpaceX API call"""
        event = {"offset_seconds": 2592000, "utc_date": "2017-06-30T00:00:00.000Z"}  # 30 days in seconds
        response = lambda_handler(event, None)

        self.assertEqual(response["statusCode"], 200)
        body = json.loads(response["body"])
        self.assertIn("inserted_items", body)
        self.assertIn("start_time", body)
        self.assertIn("end_time", body)
        self.assertIn("lauch_items", body)



if __name__ == '__main__':
    unittest.main()
