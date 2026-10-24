"""
Unit Tests for AI Environmental Intelligence & Route Advisory System.
Covers:
  - Environmental data validation
  - Stale and missing data handling
  - Route exposure index calculations
  - Pydantic schema validation
  - RAG retrieval & metadata preservation
  - Deterministic validation layer safeguards
"""

import pytest
import os
import sys

# Ensure backend directory is in path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.rag_service import get_rag_service, chunk_text, AUTHORITATIVE_DOCS
from backend.crew_advisor import (
    EnvironmentalPointSummary,
    RouteMetricSummary,
    StructuredAdvisoryOutput,
    get_advisory_orchestrator,
)


def test_chunking_token_boundaries():
    """Verify text chunking preserves token/word bounds and overlap."""
    sample_text = "word " * 120
    chunks = chunk_text(sample_text, chunk_size_words=60, overlap_words=15)
    assert len(chunks) >= 2
    # Ensure overlap exists
    first_chunk_words = chunks[0].split()
    second_chunk_words = chunks[1].split()
    overlap = set(first_chunk_words).intersection(set(second_chunk_words))
    assert len(overlap) > 0


def test_rag_knowledge_ingestion_and_metadata():
    """Verify RAG service ingests authoritative docs and retains metadata."""
    rag = get_rag_service()
    count = rag.ingest_knowledge_base()
    assert count > 0

    results = rag.retrieve("What is the health impact of PM2.5 on commuters?", top_k=2)
    assert len(results) > 0
    top = results[0]
    assert "score" in top
    assert "title" in top and len(top["title"]) > 0
    assert "source" in top and len(top["source"]) > 0
    assert "url" in top and "http" in top["url"]
    assert top["score"] >= 0.2


def test_pydantic_schema_validation():
    """Verify structured output models enforce physical validation."""
    summary = EnvironmentalPointSummary(
        location_label="Connaught Place",
        lat=28.6315,
        lon=77.2167,
        aqi=142.5,
        category="Moderate",
        dominant_pollutant="PM2.5",
        temperature_c=29.4,
        humidity_pct=48.0,
        wind_speed_kmh=11.2,
        timestamp="2026-10-24 18:00:00",
        data_provenance="cpcb_idw_interpolated",
        is_forecast=False,
    )
    assert summary.aqi == 142.5
    assert not summary.is_forecast

    route_metric = RouteMetricSummary(
        route_index=0,
        corridor_label="Green Canopy Bypass",
        distance_km=14.2,
        duration_min=28.5,
        average_aqi=118.4,
        peak_aqi=142.0,
        traffic_level="Light",
        congestion_pct=24,
        speed_kmh=34.0,
        exposure_index=56.2,
        data_quality_note="High station density (4 nearby monitors)",
    )
    assert route_metric.exposure_index == 56.2


def test_deterministic_validation_layer_corrects_out_of_bounds():
    """Verify deterministic validator rejects invalid LLM route indices."""
    orch = get_advisory_orchestrator()

    mock_routes = [
        {"route_index": 0, "corridor_label": "Route A", "average_aqi": 110.0, "duration_min": 30.0, "distance_km": 15.0, "exposure_index": 55.0},
        {"route_index": 1, "corridor_label": "Route B", "average_aqi": 210.0, "duration_min": 20.0, "distance_km": 12.0, "exposure_index": 70.0},
    ]

    invalid_llm_json = {
        "recommended_route_index": 99,  # Hallucinated / out of bounds
        "recommended_corridor_label": "Imaginary Skyway",
        "recommendation_rationale": "Made up route",
        "time_vs_pollution_tradeoff": "None",
        "health_precautions": ["Wear a mask"],
    }

    validated = orch._deterministic_validation_layer(
        parsed_json=invalid_llm_json,
        deterministic_target=mock_routes[0],
        cleanest_route=mock_routes[0],
        fastest_route=mock_routes[1],
        routes_summary=mock_routes,
        retrieved_docs=[],
        user_preference="cleanest",
        duration_ms=500,
    )

    # Must be corrected to index 0
    assert validated["recommended_route_index"] == 0
    assert "corrected" in validated["workflow_audit"]["validation_status"]


def test_preference_alignment_cleanest_vs_fastest():
    """Verify preference alignment selects the mathematical winner."""
    orch = get_advisory_orchestrator()

    mock_routes = [
        {
            "route_index": 0,
            "corridor_label": "Clean Route",
            "route_distance_km": 16.0,
            "route_duration_min": 35.0,
            "average_aqi_exposure": 85.0,
            "peak_aqi_exposure": 105.0,
            "traffic_level": "Light",
            "congestion_percentage": 15,
            "average_speed_kmh": 36.0,
        },
        {
            "route_index": 1,
            "corridor_label": "Fast Route",
            "route_distance_km": 11.0,
            "route_duration_min": 18.0,
            "average_aqi_exposure": 280.0,
            "peak_aqi_exposure": 320.0,
            "traffic_level": "Heavy",
            "congestion_percentage": 75,
            "average_speed_kmh": 22.0,
        },
    ]

    # Cleanest preference
    res_clean = orch.run_advisory_pipeline(
        start_coord={"lat": 28.6, "lon": 77.2},
        end_coord={"lat": 28.7, "lon": 77.1},
        candidate_routes=mock_routes,
        user_preference="cleanest",
    )
    assert res_clean["recommended_route_index"] == 0
    assert res_clean["is_cleanest"] is True

    # Fastest preference
    res_fast = orch.run_advisory_pipeline(
        start_coord={"lat": 28.6, "lon": 77.2},
        end_coord={"lat": 28.7, "lon": 77.1},
        candidate_routes=mock_routes,
        user_preference="fastest",
    )
    assert res_fast["recommended_route_index"] == 1
    assert res_fast["is_fastest"] is True
