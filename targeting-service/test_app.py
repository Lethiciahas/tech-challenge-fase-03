import os
import pytest

os.environ["DATABASE_URL"] = "postgresql://test:test@localhost:5432/testdb"
os.environ["AUTH_SERVICE_URL"] = "http://localhost:8001"
os.environ["DISABLE_AWS"] = "true"


def get_app():
    from unittest.mock import MagicMock, patch
    with patch("psycopg2.pool.SimpleConnectionPool") as mock_pool:
        mock_pool.return_value = MagicMock()
        import importlib
        import app as app_module
        importlib.reload(app_module)
        return app_module.app


@pytest.fixture
def client():
    app = get_app()
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_create_rule_no_auth(client):
    resp = client.post("/rules", json={"flag_name": "test", "rules": {"type": "PERCENTAGE", "value": 50}})
    assert resp.status_code == 401


def test_get_rule_no_auth(client):
    resp = client.get("/rules/test")
    assert resp.status_code == 401


def test_update_rule_no_auth(client):
    resp = client.put("/rules/test", json={"is_enabled": False})
    assert resp.status_code == 401


def test_delete_rule_no_auth(client):
    resp = client.delete("/rules/test")
    assert resp.status_code == 401
