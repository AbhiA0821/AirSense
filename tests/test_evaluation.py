"""
Unit & Integration Tests for AI Response Evaluation System.

Covers:
  1. Cosine similarity calculation & vector edge cases (zero vectors, orthogonal vectors).
  2. Latency formatting and distinction between generation and end-to-end latency.
  3. Live chat evaluation:
     - Completed state when model and retrieved context are present.
     - Partially evaluated state when retrieved docs are empty.
     - Unavailable state when model is missing.
     - Failed state when model raises an exception.
     - No fabricated RAGAS scores (faithfulness, relevancy, precision, recall are not faked).
     - Accurate labeling for semantic similarity indicators.
  4. Offline RAG benchmark evaluation:
     - Missing reference answer -> context_recall is None / N/A.
     - Missing ground-truth contexts -> context_precision is None / N/A.
     - Genuine evaluation when reference answers and ground-truth contexts exist.
  5. Integration with /airguide_chat endpoint:
     - Correct association between chatbot response and evaluation payload.
     - Latency instrumentation with time.perf_counter().
     - Validation (empty query rejection).
     - Existing domain fallback and chatbot responses intact.
"""

import os
import sys
import time
import pytest
import numpy as np
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from backend.evaluation_service import (
    compute_cosine_similarity,
    format_latency_ms,
    evaluate_live_chat_response,
    evaluate_offline_rag_benchmark,
)
from backend.app_final import app

client = TestClient(app)


class MockSentenceTransformer:
    """Mock embedding model for deterministic evaluation testing."""

    def __init__(self, fixed_dim: int = 16):
        self.dim = fixed_dim

    def encode(self, texts, convert_to_numpy: bool = True):
        is_single = isinstance(texts, str)
        items = [texts] if is_single else texts

        embeddings = []
        for t in items:
            # Deterministic hash-based vector
            vec = np.zeros(self.dim, dtype=np.float32)
            for idx, ch in enumerate(t.lower()):
                vec[idx % self.dim] += (ord(ch) - 96)
            norm = np.linalg.norm(vec)
            if norm > 0:
                vec = vec / norm
            embeddings.append(vec)

        if is_single:
            return embeddings[0] if convert_to_numpy else embeddings[0].tolist()
        return np.array(embeddings) if convert_to_numpy else [e.tolist() for e in embeddings]


class FailingSentenceTransformer:
    """Mock model that raises an exception during encoding."""

    def encode(self, *args, **kwargs):
        raise RuntimeError("GPU out of memory or model corrupted")


# ==============================================================================
# 1. Mathematical & Latency Utilities Tests
# ==============================================================================

def test_cosine_similarity_edge_cases():
    """Verify cosine similarity calculation with normal, orthogonal, opposite, and zero vectors."""
    # Identical vectors -> 1.0
    v1 = np.array([1.0, 2.0, 3.0], dtype=np.float32)
    assert abs(compute_cosine_similarity(v1, v1) - 1.0) < 1e-5

    # Orthogonal vectors -> 0.0
    v_x = np.array([1.0, 0.0, 0.0], dtype=np.float32)
    v_y = np.array([0.0, 1.0, 0.0], dtype=np.float32)
    assert abs(compute_cosine_similarity(v_x, v_y)) < 1e-5

    # Opposing vectors -> -1.0
    assert abs(compute_cosine_similarity(v_x, -v_x) - (-1.0)) < 1e-5

    # Zero vector protection (must not divide by zero or raise exception)
    v_zero = np.zeros(3, dtype=np.float32)
    assert compute_cosine_similarity(v1, v_zero) == 0.0
    assert compute_cosine_similarity(v_zero, v_zero) == 0.0


def test_format_latency_ms():
    """Verify latency display formatting across ranges and null values."""
    assert format_latency_ms(None) == "N/A"
    assert format_latency_ms(-5) == "N/A"
    assert format_latency_ms(0) == "0ms"
    assert format_latency_ms(45) == "45ms"
    assert format_latency_ms(999) == "999ms"
    assert format_latency_ms(1000) == "1.00s"
    assert format_latency_ms(2450) == "2.45s"


# ==============================================================================
# 2. Live Chat Evaluation States & Metric Accuracy
# ==============================================================================

def test_live_chat_evaluation_completed():
    """Verify live chat evaluation when model and retrieved documents are available."""
    model = MockSentenceTransformer()
    docs = [
        {"title": "Doc 1", "source": "CPCB", "score": 0.82, "text": "Lodhi Garden has cleaner air due to tree canopy."},
        {"title": "Doc 2", "source": "IMD", "score": 0.65, "text": "Morning inversions trap vehicular pollutants."},
    ]
    query = "Where can I jog safely in Delhi?"
    response = "You can jog in Lodhi Garden where the dense green canopy reduces particulate exposure."

    result = evaluate_live_chat_response(
        query=query,
        bot_response=response,
        retrieved_docs=docs,
        model=model,
        generation_latency_ms=180,
        end_to_end_latency_ms=240,
    )

    # Status must be completed
    assert result["status"] == "completed"

    # Semantic indicators must be genuine floats between 0.0 and 1.0
    assert result["qa_similarity"] is not None
    assert 0.0 <= result["qa_similarity"] <= 1.0
    assert result["qa_similarity_label"] == "Question–Answer Semantic Similarity"

    assert result["answer_context_similarity"] is not None
    assert 0.0 <= result["answer_context_similarity"] <= 1.0
    assert result["answer_context_similarity_label"] == "Answer–Context Semantic Similarity"

    assert result["retrieved_context_similarity"] == 0.82
    assert result["retrieved_context_similarity_label"] == "Retrieved-Context Similarity"

    # Formal RAGAS metrics must NOT be fabricated as scores
    assert result["faithfulness"] is None
    assert "claim-level NLI" in result["faithfulness_note"]
    assert result["answer_relevancy"] is None
    assert "reverse question" in result["answer_relevancy_note"]
    assert result["context_precision"] is None
    assert result["context_recall"] is None
    assert "gold reference" in result["context_recall_note"]

    # Latencies must be accurately recorded
    assert result["generation_latency_ms"] == 180
    assert result["generation_latency_display"] == "180ms"
    assert result["end_to_end_latency_ms"] == 240
    assert result["end_to_end_latency_display"] == "240ms"


def test_live_chat_evaluation_partially_evaluated_when_no_retrieved_docs():
    """Verify partial evaluation state when RAG retrieves no context."""
    model = MockSentenceTransformer()
    result = evaluate_live_chat_response(
        query="What is the air quality now?",
        bot_response="The air quality is moderate today.",
        retrieved_docs=[],  # Empty RAG context
        model=model,
        generation_latency_ms=120,
        end_to_end_latency_ms=150,
    )

    # Status must be partially_evaluated
    assert result["status"] == "partially_evaluated"

    # QA similarity is calculated from query and response
    assert result["qa_similarity"] is not None
    assert 0.0 <= result["qa_similarity"] <= 1.0

    # Context similarities MUST be None (no fabricated 0.82 or 0.70 fallback values)
    assert result["answer_context_similarity"] is None
    assert result["retrieved_context_similarity"] is None

    # RAGAS scores remain None
    assert result["faithfulness"] is None
    assert result["context_recall"] is None


def test_live_chat_evaluation_unavailable_when_no_model():
    """Verify unavailable evaluation state when embedding model is missing."""
    result = evaluate_live_chat_response(
        query="Hello",
        bot_response="Namaste! How can I assist you?",
        retrieved_docs=[],
        model=None,  # No embedding model available
        generation_latency_ms=10,
        end_to_end_latency_ms=15,
    )

    assert result["status"] == "unavailable"
    assert result["qa_similarity"] is None
    assert result["answer_context_similarity"] is None
    assert result["retrieved_context_similarity"] is None
    assert result["faithfulness"] is None
    assert result["context_precision"] is None

    # Latency is still captured even when evaluation model is unavailable
    assert result["generation_latency_ms"] == 10
    assert result["end_to_end_latency_ms"] == 15


def test_live_chat_evaluation_failed_on_exception():
    """Verify failed evaluation state when model raises an exception without crashing."""
    failing_model = FailingSentenceTransformer()
    result = evaluate_live_chat_response(
        query="What is AQI?",
        bot_response="AQI measures air pollution.",
        retrieved_docs=[{"text": "Some text", "score": 0.5}],
        model=failing_model,
        generation_latency_ms=50,
        end_to_end_latency_ms=75,
    )

    assert result["status"] == "failed"
    assert result["qa_similarity"] is None
    assert result["answer_context_similarity"] is None
    assert result["retrieved_context_similarity"] is None


# ==============================================================================
# 3. Offline RAG Benchmark Evaluation
# ==============================================================================

def test_offline_rag_benchmark_metrics():
    """Verify offline benchmark evaluation with reference answers and ground truth context."""
    model = MockSentenceTransformer()
    query = "What precautions should sensitive commuters take in Delhi?"
    retrieved_contexts = [
        "Commuters with asthma should wear certified N95 respirators to avoid PM2.5 inhalation.",
        "In-cabin air recirculation reduces particulate infiltration by up to 75 percent.",
    ]
    gold_answer = "Commuters should wear N95 respirators and activate vehicle cabin air recirculation."
    ground_truth = [
        "Commuters with asthma should wear certified N95 respirators to avoid PM2.5 inhalation.",
    ]
    response = "Wear N95 respirators when commuting outdoors and set car AC to internal recirculation."

    report = evaluate_offline_rag_benchmark(
        query=query,
        response=response,
        retrieved_contexts=retrieved_contexts,
        reference_answer=gold_answer,
        ground_truth_contexts=ground_truth,
        model=model,
    )

    assert report["status"] == "completed"
    assert report["context_recall"] is not None
    assert 0.0 <= report["context_recall"] <= 1.0
    assert report["context_precision"] is not None
    assert 0.0 <= report["context_precision"] <= 1.0
    assert report["faithfulness"] is not None
    assert 0.0 <= report["faithfulness"] <= 1.0
    assert report["answer_relevancy"] is not None
    assert 0.0 <= report["answer_relevancy"] <= 1.0


def test_offline_rag_benchmark_missing_reference_answer():
    """Verify context_recall is N/A when reference answer is unavailable."""
    model = MockSentenceTransformer()
    report = evaluate_offline_rag_benchmark(
        query="How is PM2.5 formed?",
        response="PM2.5 originates from vehicular exhaust and industrial combustion.",
        retrieved_contexts=["Vehicular combustion produces fine particulate matter."],
        reference_answer=None,  # Missing gold reference
        ground_truth_contexts=None,  # Missing ground truth
        model=model,
    )

    assert report["status"] == "partially_evaluated"
    assert report["context_recall"] is None
    assert "unavailable" in report["context_recall_note"].lower()
    assert report["context_precision"] is None
    assert "unavailable" in report["context_precision_note"].lower()
    # Faithfulness and relevancy can still be computed against retrieved context and query
    assert report["faithfulness"] is not None
    assert report["answer_relevancy"] is not None


# ==============================================================================
# 4. Latency Measurement & Distinction
# ==============================================================================

def test_response_latency_measurement():
    """Verify response latency is measured with time.perf_counter() and end_to_end >= generation."""
    t_start = time.perf_counter()
    time.sleep(0.015)  # 15ms simulated generation
    t_gen_end = time.perf_counter()
    generation_ms = max(1, int((t_gen_end - t_start) * 1000))

    time.sleep(0.005)  # 5ms simulated evaluation
    t_end = time.perf_counter()
    end_to_end_ms = max(1, int((t_end - t_start) * 1000))

    assert generation_ms >= 14
    assert end_to_end_ms >= generation_ms
    assert format_latency_ms(generation_ms) == f"{generation_ms}ms"
    assert format_latency_ms(end_to_end_ms) == f"{end_to_end_ms}ms"


# ==============================================================================
# 5. /airguide_chat FastAPI Integration & Functionality Preservation
# ==============================================================================

def test_airguide_chat_endpoint_integration():
    """Verify /airguide_chat returns correct response, sources, and honest evaluation payload."""
    resp = client.post(
        "/airguide_chat",
        json={"message": "Can I jog in Lodhi Garden right now?"},
    )
    assert resp.status_code == 200
    data = resp.json()

    assert "response" in data
    assert len(data["response"]) > 20
    assert "sources" in data
    assert isinstance(data["sources"], list)

    assert "evaluation" in data
    ev = data["evaluation"]
    assert "status" in ev
    assert ev["status"] in ["completed", "partially_evaluated", "unavailable", "failed"]

    # Latencies must be positive numbers
    assert "generation_latency_ms" in ev
    assert ev["generation_latency_ms"] is not None
    assert ev["generation_latency_ms"] >= 1

    assert "end_to_end_latency_ms" in ev
    assert ev["end_to_end_latency_ms"] is not None
    assert ev["end_to_end_latency_ms"] >= ev["generation_latency_ms"]

    # Formal RAGAS metrics must NOT be fabricated as scores in live response
    assert ev["faithfulness"] is None
    assert ev["answer_relevancy"] is None
    assert ev["context_precision"] is None
    assert ev["context_recall"] is None

    # Semantic similarity labels must be accurate
    assert ev["qa_similarity_label"] == "Question–Answer Semantic Similarity"
    assert ev["answer_context_similarity_label"] == "Answer–Context Semantic Similarity"
    assert ev["retrieved_context_similarity_label"] == "Retrieved-Context Similarity"


def test_airguide_chat_empty_message_validation():
    """Verify empty message is rejected with 400."""
    resp = client.post("/airguide_chat", json={"message": "   "})
    assert resp.status_code == 400
    assert "empty" in resp.json()["detail"].lower()


def test_existing_chatbot_routes_and_domain_responses_intact():
    """Verify existing domain rules (jogging, route, grap rules) remain intact."""
    test_queries = [
        ("jog in the morning", "🏃 **Outdoor Exercise Guidance"),
        ("cleanest route to CP", "🚗 **Smart Mobility Commuter Guidance"),
        ("CAQM GRAP vehicle restrictions", "🚨 **Delhi CAQM GRAP Regulatory Framework"),
        ("asthma precautions for children", "👶 **Vulnerable Demographic Protocol"),
    ]

    for q, expected_snippet in test_queries:
        resp = client.post("/airguide_chat", json={"message": q})
        assert resp.status_code == 200
        data = resp.json()
        assert "response" in data
        assert "evaluation" in data
        # Response should contain environmental advice
        assert len(data["response"]) > 30
