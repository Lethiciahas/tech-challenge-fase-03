import os
import pytest

os.environ["DISABLE_AWS"] = "true"
os.environ["AWS_REGION"] = "us-east-1"
os.environ["AWS_SQS_URL"] = "https://sqs.us-east-1.amazonaws.com/000/test"
os.environ["AWS_DYNAMODB_TABLE"] = "test-table"


@pytest.fixture
def client():
    from app import app
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_process_message_invalid_json():
    os.environ["DISABLE_AWS"] = "true"
    from app import process_message
    msg = {"MessageId": "test-123", "Body": "not-json", "ReceiptHandle": "rh"}
    process_message(msg)


def test_process_message_valid_json():
    import json
    os.environ["DISABLE_AWS"] = "true"
    from app import process_message
    body = json.dumps({
        "user_id": "u1",
        "flag_name": "f1",
        "result": True,
        "timestamp": "2024-01-01T00:00:00Z"
    })
    msg = {"MessageId": "test-456", "Body": body, "ReceiptHandle": "rh"}
    process_message(msg)
