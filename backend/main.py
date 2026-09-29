"""
AI-Powered Environmental Intelligence System Backend
FastAPI server handling real-time AQI, weather feeds, PyTorch LSTM inference, and OSRM smart routing.
"""

from fastapi import FastAPI, Query, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import requests
import os
import math
import numpy as np
from datetime import datetime
from dotenv import load_dotenv
import concurrent.futures

import sys
from pathlib import Path

# Ensure backend directory is in sys.path regardless of execution working directory
_backend_dir = str(Path(__file__).resolve().parent)
if _backend_dir not in sys.path:
    sys.path.insert(0, _backend_dir)

# Import prediction engine & routing engine
from prediction_service import prediction_engine
from routing_service import routing_engine
from spatial_interpolation import spatial_engine
from health_advisory import get_group_advisories
from notification_service import notification_service

load_dotenv()

app = FastAPI(
    title="AI-Powered Environmental Intelligence System Backend",
    description="Real-time AQI, Weather, Deep Neural Network Air Quality Prediction, and OSRM Smart Mobility Routing API",
    version="2.0.0"
)

# CORS Setup for Web Application Dashboard
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

WAQI_API_KEY = os.getenv("WAQI_API_KEY", "fa08291095089e154037576e5d42012b878c5c04")

# -----------------------------------------
# WEATHER CODE INTERPRETER (OPEN-METEO WMO)
# -----------------------------------------
def get_weather_description(code: int) -> str:
    weather_codes = {
        0: "Clear Sky",
        1: "Mainly Clear",
        2: "Partly Cloudy",
        3: "Overcast",
        45: "Foggy",
        48: "Depositing Rime Fog",
        51: "Light Drizzle",
        53: "Moderate Drizzle",
        55: "Dense Drizzle",
        61: "Slight Rain",
        63: "Moderate Rain",
        65: "Heavy Rain",
        71: "Slight Snow",
        73: "Moderate Snow",
        75: "Heavy Snow",
        80: "Slight Rain Showers",
        81: "Moderate Rain Showers",
        82: "Violent Rain Showers",
        95: "Thunderstorm",
        96: "Thunderstorm with Slight Hail",
        99: "Thunderstorm with Heavy Hail"
    }
    return weather_codes.get(code, "Clear / Variable")


def get_aqi_category(aqi):
    if aqi is None:
        return "Unknown"
    elif aqi <= 50:
        return "Good"
    elif aqi <= 100:
        return "Moderate"
    elif aqi <= 150:
        return "Unhealthy for Sensitive Groups"
    elif aqi <= 200:
        return "Unhealthy"
    elif aqi <= 300:
        return "Very Unhealthy"
    else:
        return "Hazardous"


def parse_waqi_response(data):
    if not isinstance(data, dict) or data.get("status") != "ok":
        return {
            "error": True,
            "message": "AQI data unavailable for selected location",
            "aqi": 115,
            "category": "Moderate",
            "pm25": 42.0,
            "pm10": 85.0,
            "no2": 22.0,
            "o3": 28.0,
            "co": 0.9,
            "so2": 7.5
        }

    aqi_data = data.get("data", {})
    iaqi = aqi_data.get("iaqi", {})
    raw_aqi = aqi_data.get("aqi")

    return {
        "city": aqi_data.get("city", {}).get("name"),
        "station_geo": aqi_data.get("city", {}).get("geo"),
        "aqi": raw_aqi,
        "category": get_aqi_category(raw_aqi),
        "pm25": iaqi.get("pm25", {}).get("v"),
        "pm10": iaqi.get("pm10", {}).get("v"),
        "no2": iaqi.get("no2", {}).get("v"),
        "o3": iaqi.get("o3", {}).get("v"),
        "co": iaqi.get("co", {}).get("v"),
        "so2": iaqi.get("so2", {}).get("v"),
        "temperature": iaqi.get("t", {}).get("v"),
        "humidity": iaqi.get("h", {}).get("v")
    }

# -----------------------------------------
# ROOT ENDPOINT
# -----------------------------------------
@app.get("/")
def home():
    return {
        "title": "AI-Powered Environmental Intelligence System",
        "status": "online",
        "milestones": "Milestone 1 + Milestone 2 Connected System",
        "prediction_model": "PyTorch LSTM Neural Network",
        "routing_engine": "OSRM Driving",
        "endpoints": [
            "/environment/current",
            "/aqi/geo",
            "/aqi/{city}",
            "/weather",
            "/reverse-geocode",
            "/prediction/aqi",
            "/route/analyze",
            "/aqi/historical",
            "/spatial/interpolate",
            "/advisory/groups",
            "/notifications/status"
        ]
    }

# -----------------------------------------
# MILESTONE 1 API INTEGRATIONS (PRESERVED)
# -----------------------------------------
@app.get("/aqi/geo")
def get_aqi_by_geo(latitude: float = Query(...), longitude: float = Query(...)):
    url = f"https://api.waqi.info/feed/geo:{latitude};{longitude}/?token={WAQI_API_KEY}"
    try:
        response = requests.get(url, timeout=6)
        data = response.json()
        return parse_waqi_response(data)
    except Exception as e:
        return {"error": True, "message": str(e), "aqi": None}


@app.get("/aqi/historical")
def get_historical_aqi(current_aqi: float = Query(120.0)):
    """
    Returns realistic past 24-hour AQI trend to plot continuous curve leading into AI forecast.
    """
    now = datetime.now()
    trend = []
    
    # Generate past 24 hours trend leading up to current_aqi
    for h in range(24, 0, -1):
        time_str = f"-{h}h"
        # Diurnal peak pattern simulation
        hour_val = (now.hour - h) % 24
        diurnal_factor = 1.0 + 0.15 * math.sin((hour_val - 8) * math.pi / 12)
        val = max(10.0, round(current_aqi * diurnal_factor + np.random.uniform(-5, 5), 1))
        trend.append({"hour": time_str, "aqi": val})
        
    trend.append({"hour": "Now", "aqi": current_aqi})
    return {"historical_trend": trend}


@app.get("/aqi/{city}")
def get_aqi(city: str):
    url = f"https://api.waqi.info/feed/{city}/?token={WAQI_API_KEY}"
    try:
        response = requests.get(url, timeout=10)
        data = response.json()
        return parse_waqi_response(data)
    except Exception as e:
        return {"error": True, "message": str(e), "aqi": None}


@app.get("/weather")
def get_weather(latitude: float = Query(...), longitude: float = Query(...)):
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": latitude,
        "longitude": longitude,
        "current": "temperature_2m,relative_humidity_2m,surface_pressure,wind_speed_10m,weather_code"
    }
    
    try:
        response = requests.get(url, params=params, timeout=6)
        data = response.json()
        current = data.get("current", {})
        
        return {
            "temperature": current.get("temperature_2m"),
            "humidity": current.get("relative_humidity_2m"),
            "wind_speed": current.get("wind_speed_10m"),
            "pressure": current.get("surface_pressure"),
            "weather_code": current.get("weather_code"),
            "condition": get_weather_description(current.get("weather_code", 0))
        }
    except Exception as e:
        return {
            "error": "Failed to fetch real-time weather from Open-Meteo",
            "details": str(e)
        }


@app.get("/reverse-geocode")
def reverse_geocode(latitude: float, longitude: float):
    url = "https://nominatim.openstreetmap.org/reverse"
    params = {
        "lat": latitude,
        "lon": longitude,
        "format": "json"
    }
    headers = {
        "User-Agent": "AI-Environmental-Intelligence-System/2.0"
    }

    try:
        response = requests.get(url, params=params, headers=headers, timeout=6)
        data = response.json()
        address = data.get("address", {})

        city_name = (
            address.get("city")
            or address.get("town")
            or address.get("village")
            or address.get("county")
            or address.get("state_district")
            or "Unknown Area"
        )

        return {
            "location": data.get("display_name"),
            "city": city_name
        }
    except Exception as e:
        return {
            "location": "Location Lookup Error",
            "city": "Unknown",
            "error": str(e)
        }


@app.get("/location")
def get_location(latitude: float, longitude: float):
    return {"latitude": latitude, "longitude": longitude}


@app.get("/geocode")
def geocode_location(location: str = Query(...)):
    headers = {"User-Agent": "AI-Environmental-Intelligence-System/2.0"}
    url = "https://nominatim.openstreetmap.org/search"

    queries_to_try = [location]
    loc_lower = location.lower()
    if "delhi" not in loc_lower and "ncr" not in loc_lower and "current" not in loc_lower:
        queries_to_try.insert(0, f"{location}, Delhi, India")

    for q in queries_to_try:
        try:
            res = requests.get(url, params={"q": q, "format": "json", "limit": 1}, headers=headers, timeout=10).json()
            if res and isinstance(res, list) and len(res) > 0:
                first = res[0]
                display_name = first.get("display_name", location)
                parts = display_name.split(",")
                city_label = parts[0].strip()
                if len(parts) > 1:
                    city_label += f", {parts[1].strip()}"
                return {
                    "status": "success",
                    "lat": float(first.get("lat")),
                    "lon": float(first.get("lon")),
                    "display_name": display_name,
                    "city_label": city_label
                }
        except Exception:
            continue

    return {"status": "error", "message": f"Location '{location}' not found."}


# -----------------------------------------
# SPATIAL INTERPOLATION, HEALTH ADVISORY & NOTIFICATION ENDPOINTS
# -----------------------------------------

@app.get("/spatial/interpolate")
def get_spatial_interpolation(
    latitude: float = Query(..., alias="lat"),
    longitude: float = Query(..., alias="lon"),
    power: float = Query(2.0),
    k_nearest: Optional[int] = Query(5)
):
    """
    Computes genuine Inverse Distance Weighting (IDW) spatial AQI interpolation using actual Delhi monitoring stations.
    """
    return spatial_engine.interpolate_aqi(
        lat=latitude,
        lon=longitude,
        power=power,
        k_nearest=k_nearest
    )


@app.get("/advisory/groups")
def get_health_advisories_endpoint(aqi: float = Query(120.0)):
    """
    Returns demographic-specific actionable environmental health advisories for general public, children, elderly, and sensitive groups.
    """
    return get_group_advisories(aqi)


@app.get("/notifications/status")
def get_notification_status():
    """
    Returns honest service status and configuration validation for push notifications (FCM).
    """
    return notification_service.get_service_status()


# -----------------------------------------
# MILESTONE 2 AGGREGATED & AI ENDPOINTS
# -----------------------------------------

@app.get("/environment/current")
def get_current_environment(latitude: float = Query(...), longitude: float = Query(...)):
    """
    Aggregates reverse geocoding, live WAQI AQI, live Open-Meteo weather, and PyTorch LSTM AI forecast.
    """
    # Fetch Reverse Geocode, Live AQI Feed, and Live Weather Feed concurrently
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
        f_geo = executor.submit(reverse_geocode, latitude, longitude)
        f_aqi = executor.submit(get_aqi_by_geo, latitude, longitude)
        f_weather = executor.submit(get_weather, latitude, longitude)
        
        geo = f_geo.result()
        aqi_res = f_aqi.result()
        weather_res = f_weather.result()

    # Clean numeric parameters for AI model prediction
    curr_aqi = aqi_res.get("aqi") or 110.0
    pm25 = aqi_res.get("pm25") or 40.0
    pm10 = aqi_res.get("pm10") or 85.0
    no2 = aqi_res.get("no2") or 22.0
    co = aqi_res.get("co") or 0.8
    so2 = aqi_res.get("so2") or 7.0
    o3 = aqi_res.get("o3") or 26.0
    
    temp = weather_res.get("temperature") or 26.0
    hum = weather_res.get("humidity") or 55.0
    wind = weather_res.get("wind_speed") or 10.0
    press = weather_res.get("pressure") or 1012.0

    now = datetime.now()

    # 4. Execute PyTorch LSTM Model Inference
    ai_prediction = prediction_engine.predict(
        current_aqi=curr_aqi,
        pm25=pm25,
        pm10=pm10,
        no2=no2,
        co=co,
        so2=so2,
        o3=o3,
        temperature=temp,
        humidity=hum,
        wind_speed=wind,
        pressure=press,
        hour=now.hour,
        dayofweek=now.weekday(),
        month=now.month
    )

    # 5. Inverse Distance Weighting (IDW) ground station interpolation for exact coordinates
    spatial_res = spatial_engine.interpolate_aqi(
        lat=latitude,
        lon=longitude,
        power=2.0,
        k_nearest=5,
        base_aqi_scale=curr_aqi
    )

    # 6. Multi-pollutant analysis & atmospheric dispersion condition
    dispersion = "Favorable (Good Ventilation)" if wind >= 15.0 else ("Moderate Dispersion" if wind >= 7.0 else "Stagnant (Poor Dispersion, Low Wind)")
    pollutant_ranks = [
        ("PM2.5", pm25 / 60.0),
        ("PM10", pm10 / 100.0),
        ("NO2", no2 / 80.0),
        ("SO2", so2 / 80.0),
        ("CO", co / 4.0),
        ("O3", o3 / 100.0)
    ]
    dominant = max(pollutant_ranks, key=lambda x: x[1])[0]

    env_intel = {
        "dominant_pollutant": dominant,
        "atmospheric_dispersion": dispersion,
        "wind_speed_kmh": wind,
        "surface_pressure_hpa": press,
        "spatial_interpolated_aqi": spatial_res.get("interpolated_aqi"),
        "nearest_station": spatial_res.get("nearest_station"),
        "monitoring_stations_count": len(spatial_res.get("contributing_stations", []))
    }

    return {
        "location": geo,
        "coordinates": {"latitude": latitude, "longitude": longitude},
        "live_aqi": aqi_res,
        "live_weather": weather_res,
        "environmental_intelligence": env_intel,
        "spatial_interpolation": spatial_res,
        "ai_prediction": ai_prediction,
        "timestamp": now.strftime("%Y-%m-%d %H:%M:%S")
    }


class PredictionRequest(BaseModel):
    current_aqi: float
    pm25: Optional[float] = 40.0
    pm10: Optional[float] = 85.0
    no2: Optional[float] = 22.0
    co: Optional[float] = 0.8
    so2: Optional[float] = 7.0
    o3: Optional[float] = 26.0
    temperature: Optional[float] = 26.0
    humidity: Optional[float] = 55.0
    wind_speed: Optional[float] = 10.0
    pressure: Optional[float] = 1012.0
    hour: Optional[int] = None
    dayofweek: Optional[int] = None
    month: Optional[int] = None


@app.post("/prediction/aqi")
def predict_aqi_endpoint(req: PredictionRequest):
    now = datetime.now()
    req_hour = req.hour if req.hour is not None else now.hour
    req_dow = req.dayofweek if req.dayofweek is not None else now.weekday()
    req_month = req.month if req.month is not None else now.month

    return prediction_engine.predict(
        current_aqi=req.current_aqi,
        pm25=req.pm25,
        pm10=req.pm10,
        no2=req.no2,
        co=req.co,
        so2=req.so2,
        o3=req.o3,
        temperature=req.temperature,
        humidity=req.humidity,
        wind_speed=req.wind_speed,
        pressure=req.pressure,
        hour=req_hour,
        dayofweek=req_dow,
        month=req_month
    )


class RouteRequest(BaseModel):
    origin: Optional[str] = None          # e.g. "Delhi Airport", "Connaught Place"
    origin_lat: Optional[float] = None
    origin_lon: Optional[float] = None
    destination: str                      # e.g. "India Gate", "Red Fort"
    dest_lat: Optional[float] = None
    dest_lon: Optional[float] = None
    current_aqi: Optional[float] = 120.0


DELHI_KNOWN_LOCATIONS = {
    "delhi airport": (28.560344, 77.088720),
    "indira gandhi international airport": (28.560344, 77.088720),
    "terminal 1, delhi airport": (28.5583, 77.1147),
    "terminal 2, delhi airport": (28.5542, 77.0850),
    "terminal 3, delhi airport": (28.5562, 77.0870),
    "new delhi railway station": (28.640281, 77.220410),
    "old delhi railway station": (28.6616, 77.2307),
    "hazrat nizamuddin railway station": (28.5891, 77.2530),
    "anand vihar railway terminal": (28.6508, 77.3152),
    "connaught place": (28.631769, 77.219380),
    "india gate": (28.612933, 77.229492),
    "red fort": (28.656081, 77.240795),
    "qutub minar": (28.5245, 77.1855),
    "lotus temple": (28.5535, 77.2588),
    "humayun's tomb": (28.5933, 77.2507),
    "rashtrapati bhavan": (28.6143, 77.1994),
    "parliament house": (28.6172, 77.2081),
    "akshardham temple": (28.6127, 77.2773),
    "jantar mantar": (28.6271, 77.2166),
    "chandni chowk": (28.6506, 77.2303),
    "raj ghat": (28.6406, 77.2495),
    "new delhi": (28.6139, 77.2090),
    "central delhi": (28.6318, 77.2194),
    "south delhi": (28.5400, 77.2100),
    "north delhi": (28.7000, 77.2100),
    "east delhi": (28.6300, 77.2800),
    "west delhi": (28.6500, 77.1200),
    "dwarka": (28.5921, 77.0460),
    "rohini": (28.7324, 77.1197),
    "saket": (28.5244, 77.2066),
    "vasant kunj": (28.5292, 77.1543),
    "karol bagh": (28.6514, 77.1907),
    "lajpat nagar": (28.5677, 77.2433),
    "hauz khas": (28.5494, 77.2001),
    "greater kailash": (28.5463, 77.2425),
    "janakpuri": (28.6219, 77.0878),
    "pitampura": (28.6987, 77.1384),
    "mayur vihar": (28.6080, 77.2952)
}

def _helper_geocode(query: str):
    q_clean = query.strip().lower()
    if q_clean in DELHI_KNOWN_LOCATIONS:
        return DELHI_KNOWN_LOCATIONS[q_clean]
    
    headers = {"User-Agent": "AI-Environmental-Intelligence-System/2.0"}
    url = "https://nominatim.openstreetmap.org/search"
    queries = [query]
    if "delhi" not in query.lower() and "ncr" not in query.lower() and "current" not in query.lower():
        queries.insert(0, f"{query}, Delhi, India")
    for q in queries:
        try:
            res = requests.get(url, params={"q": q, "format": "json", "limit": 1}, headers=headers, timeout=10).json()
            if res and isinstance(res, list) and len(res) > 0:
                return float(res[0]["lat"]), float(res[0]["lon"])
        except Exception:
            continue
    return None, None


@app.post("/route/analyze")
def analyze_route(req: RouteRequest):
    orig_lat = req.origin_lat
    orig_lon = req.origin_lon
    dest_lat = req.dest_lat
    dest_lon = req.dest_lon

    # 1. Geocode Origin if explicit coordinates not supplied
    if (orig_lat is None or orig_lon is None) and req.origin:
        orig_lat, orig_lon = _helper_geocode(req.origin)

    if orig_lat is None or orig_lon is None:
        orig_lat, orig_lon = 28.6139, 77.2090  # Default Delhi

    # 2. Geocode Destination if explicit coordinates not supplied
    if (dest_lat is None or dest_lon is None) and req.destination:
        dest_lat, dest_lon = _helper_geocode(req.destination)

    if dest_lat is None or dest_lon is None:
        dest_lat, dest_lon = orig_lat + 0.03, orig_lon + 0.03

    route_res = routing_engine.get_route(
        origin_lat=orig_lat,
        origin_lon=orig_lon,
        dest_lat=dest_lat,
        dest_lon=dest_lon,
        current_aqi=req.current_aqi or 120.0
    )

    route_res["origin"] = req.origin or "Origin"
    route_res["destination"] = req.destination or "Destination"
    route_res["origin_coords"] = {"lat": orig_lat, "lon": orig_lon}
    route_res["destination_coords"] = {"lat": dest_lat, "lon": dest_lon}

    return route_res

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)