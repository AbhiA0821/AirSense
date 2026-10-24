"""
Integration Tests for FastAPI Backend + CrewAI Multi-Agent System.
Covers:
  - Root and health check endpoints
  - /route_options endpoint stability
  - /route_advisory endpoint with sequential 3-agent CrewAI pipeline
  - /predict_at_location endpoint
"""

import pytest
import os
import sys
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.app_final import app

client = TestClient(app)


def test_api_root():
    """Verify backend root endpoint responds with status and station count."""
    resp = client.get("/")
    assert resp.status_code == 200
    data = resp.json()
    assert "status" in data
    assert data.get("stations_available", 0) >= 30


def test_predict_at_location():
    """Verify spatial IDW interpolation at valid Delhi coordinates."""
    # Connaught Place coordinates
    resp = client.get("/predict_at_location?lat=28.6315&lon=77.2167&n_stations=4")
    assert resp.status_code == 200
    data = resp.json()
    assert "interpolated_aqi" in data
    assert data["interpolated_aqi"] > 0
    assert "latest_weather" in data
    assert "contributing_stations" in data


def test_route_options_backward_compatibility():
    """Verify existing route_options endpoint works without breaking changes."""
    resp = client.get("/route_options?start_lat=28.6139&start_lon=77.2090&end_lat=28.7041&end_lon=77.1025")
    assert resp.status_code == 200
    data = resp.json()
    assert "routes" in data
    routes = data["routes"]
    assert len(routes) >= 2
    for r in routes:
        assert "route_distance_km" in r
        assert "route_duration_min" in r
        assert "average_aqi_exposure" in r
        assert "traffic_level" in r
    assert "recommended_index" in data


def test_route_advisory_endpoint():
    """Verify /route_advisory executes 3-agent CrewAI workflow and returns grounded recommendation."""
    resp = client.get(
        "/route_advisory?start_lat=28.6139&start_lon=77.2090&end_lat=28.7041&end_lon=77.1025&user_preference=cleanest&age_group=adult&health_note=Asthma"
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "routes" in data
    assert "ai_advisory" in data

    adv = data["ai_advisory"]
    assert "recommended_route_index" in adv
    assert "recommended_corridor_label" in adv
    assert "recommendation_rationale" in adv and len(adv["recommendation_rationale"]) > 20
    assert "time_vs_pollution_tradeoff" in adv
    assert "health_precautions" in adv and len(adv["health_precautions"]) >= 1
    assert "supporting_rag_citations" in adv and len(adv["supporting_rag_citations"]) >= 1
    assert "workflow_audit" in adv
    audit = adv["workflow_audit"]
    assert "agents_executed" in audit
    assert len(audit["agents_executed"]) == 3
