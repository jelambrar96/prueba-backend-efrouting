"""
Pytest configuration file for Lambda tests
"""

import pytest
import os
import sys

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Set default environment variables for testing
@pytest.fixture(scope="session", autouse=True)
def setup_env():
    """Setup test environment"""
    os.environ["DYNAMODB_TABLE"] = "test-launches-table"
    os.environ["ENVIRONMENT"] = "dev"
    os.environ["AWS_REGION"] = "us-east-1"
    yield
