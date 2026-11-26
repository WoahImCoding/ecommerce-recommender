"""API tests: run from the project root with   python -m pytest -q"""
from fastapi.testclient import TestClient

from src.api.main import CUSTOMERS, app

client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["customers"] == len(CUSTOMERS)


def test_known_customer_gets_12_personalised_items():
    r = client.get(f"/recommend/{CUSTOMERS[0]}").json()
    assert r["source"] == "personalised"
    assert len(r["recommendations"]) == 12
    assert len(set(r["recommendations"])) == 12                     # no duplicates
    assert all(len(a) == 10 for a in r["recommendations"])          # 10-digit H&M article IDs


def test_k_limits_the_list():
    r = client.get(f"/recommend/{CUSTOMERS[0]}?k=5").json()
    assert len(r["recommendations"]) == 5


def test_unknown_customer_gets_cold_start():
    r = client.get("/recommend/not-a-real-customer").json()
    assert r["source"] == "cold_start"
    assert len(r["recommendations"]) == 12


def test_invalid_k_is_rejected():
    assert client.get(f"/recommend/{CUSTOMERS[0]}?k=50").status_code == 422