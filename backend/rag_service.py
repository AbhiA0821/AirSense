"""
RAG Service for Environmental Intelligence & Route Advisory.

Uses:
  - Vector DB: Qdrant (persistent disk or memory mode)
  - Embedding Model: sentence-transformers/all-MiniLM-L6-v2 (dim 384)
  - Authoritative Knowledge Base: CPCB, WHO, IMD, MoHFW guidelines on AQI,
    particulate matter, meteorology, route exposure, and health precautions.
"""

import os
import uuid
from typing import List, Dict, Any, Optional
from qdrant_client import QdrantClient
from qdrant_client.models import (
    VectorParams,
    Distance,
    PointStruct,
    Filter,
    FieldCondition,
    MatchValue,
)
from sentence_transformers import SentenceTransformer

COLLECTION_NAME = "environmental_knowledge"
EMBEDDING_MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
EMBEDDING_DIM = 384

# Authoritative knowledge base corpus
AUTHORITATIVE_DOCS = [
    {
        "id": "cpcb_aqi_scale",
        "title": "CPCB National Air Quality Index (NAQI) Standard and Health Criteria",
        "source": "Central Pollution Control Board (CPCB), Ministry of Environment, Forest & Climate Change, Govt. of India",
        "url": "https://cpcb.nic.in/national-air-quality-index/",
        "date": "2023-08-15",
        "topic": "AQI Categories & Health Impacts",
        "content": (
            "The Central Pollution Control Board (CPCB) defines India's National Air Quality Index (AQI) "
            "across six distinct categories: "
            "1. Good (0-50): Minimal health impact; clean ambient air safe for all demographics. "
            "2. Satisfactory (51-100): Minor breathing discomfort to sensitive individuals with preexisting asthma or lung disease. "
            "3. Moderate (101-200): Breathing discomfort to people with lung disease, asthma, heart conditions, children, and elderly. "
            "4. Poor (201-300): Breathing discomfort on prolonged exposure to most people; pronounced aggravation of heart and lung conditions. "
            "5. Very Poor (301-400): Significant respiratory illness on prolonged exposure; outdoor physical exertion should be avoided. "
            "6. Severe (401-500): Affects healthy individuals severely and causes serious respiratory and cardiovascular impacts on vulnerable populations. "
            "AQI computation is governed by the sub-index of the dominant pollutant among PM2.5, PM10, NO2, SO2, CO, O3, NH3, and Pb."
        ),
    },
    {
        "id": "pm_health_mechanisms",
        "title": "Particulate Matter (PM2.5 & PM10) Size Fraction Dynamics and Physiological Risks",
        "source": "World Health Organization (WHO) & Indian Council of Medical Research (ICMR)",
        "url": "https://www.who.int/news-room/fact-sheets/detail/ambient-(outdoor)-air-quality-and-health",
        "date": "2024-01-10",
        "topic": "Particulate Matter Inhalation Risks",
        "content": (
            "Particulate matter comprises coarse particles (PM10, aerodynamic diameter ≤ 10 µm) and fine particles (PM2.5, diameter ≤ 2.5 µm). "
            "Coarse particles (PM10) typically originate from road dust, mechanical abrasion, construction, and windblown soil. "
            "They deposit primarily in the upper thoracic airways, causing mucous membrane irritation, coughing, and bronchospasm. "
            "Fine particles (PM2.5) stem primarily from combustion processes, vehicular exhaust, and secondary atmospheric reactions. "
            "Because of their minute size, PM2.5 penetrates deep into the pulmonary alveoli and can cross the air-blood barrier into the systemic circulation, "
            "triggering vascular endothelial dysfunction, arterial plaque instability, systemic inflammation, and microvascular clotting. "
            "During stop-and-go traffic on congested urban arterial roads, in-cabin concentration of PM2.5 and ultrafine particles can surge rapidly without air recirculation."
        ),
    },
    {
        "id": "meteorology_air_quality",
        "title": "Meteorological Influences on Urban Atmospheric Dispersion and Smog Formation",
        "source": "India Meteorological Department (IMD) & Atmospheric Sciences Division",
        "url": "https://mausam.imd.gov.in/",
        "date": "2023-11-20",
        "topic": "Meteorology & Pollution Dispersion",
        "content": (
            "Urban air quality in the Indo-Gangetic Plain and Delhi NCR is strongly governed by boundary-layer meteorology. "
            "During nocturnal and early morning hours, radiative surface cooling produces strong thermal temperature inversions, "
            "trapping vehicular exhaust and industrial particulates within a compressed mixing layer (often under 100-200 meters). "
            "This inversion causes sharp morning AQI spikes (7:00 AM - 10:30 AM). "
            "After midday (1:00 PM - 4:00 PM), strong solar insolation induces deep vertical convective mixing, elevating the planetary boundary layer "
            "to 1,500-2,000 meters and dispersing ground-level particulate matter, creating a daily pollution valley. "
            "Low wind speeds (< 5 km/h) prevent horizontal ventilation, causing pollutant pooling along high-density transit corridors, "
            "whereas higher sustained wind velocities (> 15 km/h) accelerate advective clearing."
        ),
    },
    {
        "id": "traffic_route_exposure",
        "title": "Commuter Pollution Exposure Mitigation and Urban Corridor Optimization",
        "source": "United Nations Environment Programme (UNEP) & Urban Transport Research Center",
        "url": "https://www.unep.org/explore-topics/transport",
        "date": "2024-03-05",
        "topic": "Route Exposure & Commuter Protection",
        "content": (
            "Direct tailpipe emissions create an intense near-road micro-environment extending 50 to 150 meters from highway centerlines. "
            "Commuters traveling along congested arterial highways experience up to 40% higher cumulative exposure to black carbon, nitrogen dioxide, "
            "and PM2.5 compared to alternative routes traversing green buffers, urban forest corridors, or low-density collector roads. "
            "Choosing an alternative bypass with 5-10% longer physical distance can reduce total inhaled pollutant dose by 20-35% if vehicular congestion "
            "and transit idling are significantly lower. In vehicular transit, setting climate control to interior air recirculation reduces cabin particulate intrusion "
            "by 50% to 75% relative to outside ventilation."
        ),
    },
    {
        "id": "vulnerable_populations_protocol",
        "title": "Clinical Advisory Protocol for Vulnerable Demographics During Poor Air Quality",
        "source": "Ministry of Health & Family Welfare (MoHFW), National Programme on Climate Change and Human Health (NPCCHH)",
        "url": "https://mohfw.gov.in/",
        "date": "2023-12-01",
        "topic": "Vulnerable Demographics & Clinical Precautions",
        "content": (
            "Special clinical considerations apply to pediatric, geriatric, pregnant, and cardiopulmonary sensitive groups when AQI exceeds 150: "
            "1. Children have higher minute ventilation rates per unit body mass and developing lung parenchyma, making them exceptionally vulnerable to PM2.5-induced asthma exacerbations. "
            "2. Elderly individuals and those with coronary artery disease or COPD face elevated risks of ischemic events and acute desaturation during Poor (201-300) and Very Poor (301-400) air days. "
            "3. Certified particulate respirators (N95 or FFP2 standard) provide effective filtration (>95% efficiency for 0.3 µm particles) when tightly fitted, whereas standard cloth masks offer minimal sub-micron protection. "
            "4. Non-motorized travelers (pedestrians, cyclists, two-wheeler riders) experience maximum direct lung deposition and should preferentially schedule travel during midday convective windows rather than morning inversion peaks."
        ),
    },
]


def chunk_text(text: str, chunk_size_words: int = 60, overlap_words: int = 15) -> List[str]:
    """
    Split text into chunks of approx 200-250 tokens (~60 words) with 30-40 token overlap (~15 words).
    """
    words = text.split()
    if len(words) <= chunk_size_words:
        return [text]

    chunks = []
    start = 0
    while start < len(words):
        end = min(start + chunk_size_words, len(words))
        chunk = " ".join(words[start:end])
        chunks.append(chunk)
        if end == len(words):
            break
        start += (chunk_size_words - overlap_words)
    return chunks


class EnvironmentalRAGService:
    """
    Lightweight, deterministic RAG service for environmental and route advisory intelligence.
    """

    def __init__(self, storage_path: Optional[str] = None):
        self.storage_path = storage_path or os.environ.get("QDRANT_PATH")
        self.qdrant_url = os.environ.get("QDRANT_URL")
        self.qdrant_api_key = os.environ.get("QDRANT_API_KEY")

        # Initialize Qdrant Client (supports Qdrant Cloud, local disk, and in-memory)
        if self.qdrant_url:
            try:
                self.client = QdrantClient(url=self.qdrant_url, api_key=self.qdrant_api_key)
            except Exception as _cloud_err:
                print(f"Notice: Qdrant Cloud connection failed ({_cloud_err}), utilizing in-memory vector database.")
                self.client = QdrantClient(":memory:")
        elif self.storage_path:
            if self.storage_path == ":memory:":
                self.client = QdrantClient(":memory:")
            else:
                os.makedirs(self.storage_path, exist_ok=True)
                try:
                    self.client = QdrantClient(path=self.storage_path)
                except Exception as _lock_err:
                    print(f"Notice: Storage path locked ({_lock_err}), utilizing in-memory vector database.")
                    self.client = QdrantClient(":memory:")
        else:
            default_path = os.path.join(os.path.dirname(__file__), "qdrant_data")
            os.makedirs(default_path, exist_ok=True)
            try:
                self.client = QdrantClient(path=default_path)
            except Exception as _lock_err:
                print(f"Notice: Qdrant local folder locked ({_lock_err}), utilizing in-memory vector database.")
                self.client = QdrantClient(":memory:")

        self._model = None
        self._ensure_collection()

    @property
    def model(self) -> SentenceTransformer:
        if self._model is None:
            self._model = SentenceTransformer(EMBEDDING_MODEL_NAME)
        return self._model

    def _ensure_collection(self):
        try:
            collections = self.client.get_collections().collections
            exists = any(c.name == COLLECTION_NAME for c in collections)
            if not exists:
                self.client.create_collection(
                    collection_name=COLLECTION_NAME,
                    vectors_config=VectorParams(size=EMBEDDING_DIM, distance=Distance.COSINE),
                )
                self.ingest_knowledge_base()
        except Exception as e:
            print(f"Notice: Qdrant collection check: {e}")

    def ingest_knowledge_base(self, force: bool = False) -> int:
        """
        Ingest the authoritative environmental documents into Qdrant.
        Idempotent by checking point counts.
        """
        try:
            info = self.client.get_collection(COLLECTION_NAME)
            if info.points_count > 0 and not force:
                return info.points_count
        except Exception:
            pass

        points = []
        pt_counter = 1
        for doc in AUTHORITATIVE_DOCS:
            chunks = chunk_text(doc["content"], chunk_size_words=65, overlap_words=15)
            for chunk_idx, chunk in enumerate(chunks):
                # Generate embedding
                vector = self.model.encode(chunk).tolist()
                payload = {
                    "doc_id": doc["id"],
                    "title": doc["title"],
                    "source": doc["source"],
                    "url": doc["url"],
                    "date": doc["date"],
                    "topic": doc["topic"],
                    "chunk_index": chunk_idx,
                    "text": chunk,
                }
                points.append(
                    PointStruct(
                        id=pt_counter,
                        vector=vector,
                        payload=payload,
                    )
                )
                pt_counter += 1

        if points:
            self.client.upsert(collection_name=COLLECTION_NAME, points=points)
            print(f"RAG Knowledge Base ingested: {len(points)} chunks into '{COLLECTION_NAME}'.")
        return len(points)

    def retrieve(self, query: str, top_k: int = 3, min_score: float = 0.25) -> List[Dict[str, Any]]:
        """
        Semantic similarity search in Qdrant with source attribution.
        """
        try:
            query_vector = self.model.encode(query).tolist()
            if hasattr(self.client, "query_points"):
                response = self.client.query_points(
                    collection_name=COLLECTION_NAME,
                    query=query_vector,
                    limit=top_k,
                    score_threshold=min_score,
                )
                hits = response.points
            else:
                hits = self.client.search(
                    collection_name=COLLECTION_NAME,
                    query_vector=query_vector,
                    limit=top_k,
                    score_threshold=min_score,
                )

            results = []
            for hit in hits:
                results.append({
                    "score": round(hit.score, 3),
                    "text": hit.payload.get("text", ""),
                    "title": hit.payload.get("title", ""),
                    "source": hit.payload.get("source", ""),
                    "url": hit.payload.get("url", ""),
                    "topic": hit.payload.get("topic", ""),
                })
            return results
        except Exception as e:
            print(f"Notice: RAG retrieval fallback: {e}")
            # Fallback to local lexical match if vector search fails
            q_lower = query.lower()
            fallbacks = []
            for doc in AUTHORITATIVE_DOCS:
                if any(w in doc["content"].lower() for w in q_lower.split() if len(w) > 3):
                    fallbacks.append({
                        "score": 0.5,
                        "text": doc["content"][:300] + "...",
                        "title": doc["title"],
                        "source": doc["source"],
                        "url": doc["url"],
                        "topic": doc["topic"],
                    })
                if len(fallbacks) >= top_k:
                    break
            return fallbacks


# Global singleton
_rag_instance: Optional[EnvironmentalRAGService] = None

def get_rag_service() -> EnvironmentalRAGService:
    global _rag_instance
    if _rag_instance is None:
        _rag_instance = EnvironmentalRAGService()
    return _rag_instance
