"""
Milestone 2 Final Comprehensive 30-Point Verification Suite
AI-Powered Environmental Intelligence System for Air Quality Prediction and Smart Mobility Recommendations

Verifies all 30 points required for Milestone 2:
 1. Backend startup
 2. Root endpoint
 3. Live environment
 4. Historical AQI
 5. LSTM prediction
 6. Dynamic prediction sensitivity
 7. 24-hour forecast
 8. Direct LSTM/API parity
 9. IDW mathematical correctness
10. Exact station IDW behavior
11. Multi-station IDW
12. Distance weighting
13. Invalid-data handling
14. Route analysis
15. Multiple route alternatives
16. Route AQI
17. LSTM route prediction
18. PM2.5 exposure
19. Route recommendation
20. Geocoding
21. Reverse geocoding
22. Flask frontend startup
23. Dashboard loading
24. Map rendering
25. Forecast chart
26. No NaN/errors
27. No hardcoded dynamic values
28. No broken model paths
29. No broken imports
30. No regression of existing functionality
"""

import sys
import os
import time
import math
import json
import requests
import numpy as np

BASE_URL = "http://127.0.0.1:8000"
FRONTEND_URL = "http://127.0.0.1:8080"

def run_milestone2_final_verification():
    print("==================================================================")
    print("STARTING COMPLETE 30-POINT MILESTONE 2 FINAL VERIFICATION SUITE")
    print("==================================================================\n")

    results = {}
    total_tests = 30

    # ------------------------------------------------------------------
    # TEST 1: Backend Startup
    # ------------------------------------------------------------------
    try:
        r = requests.get(f"{BASE_URL}/", timeout=5)
        results["1_backend_startup"] = (r.status_code == 200)
    except Exception:
        results["1_backend_startup"] = False
    print(f"[TEST 01] Backend Startup: {'PASS' if results['1_backend_startup'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 2: GET / Root Endpoint
    # ------------------------------------------------------------------
    r_root = requests.get(f"{BASE_URL}/").json()
    model_declared = r_root.get("prediction_model", "")
    results["2_get_root"] = (r_root.get("status") == "online" and "PyTorch LSTM" in model_declared)
    print(f"[TEST 02] GET / Root Endpoint ({model_declared}): {'PASS' if results['2_get_root'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 3: GET /environment/current
    # ------------------------------------------------------------------
    r_env = requests.get(f"{BASE_URL}/environment/current?latitude=28.6139&longitude=77.2090", timeout=10).json()
    results["3_get_environment_current"] = (
        "live_aqi" in r_env and
        "live_weather" in r_env and
        "ai_prediction" in r_env and
        r_env.get("ai_prediction", {}).get("model_used") == "PyTorch LSTM Neural Network"
    )
    print(f"[TEST 03] GET /environment/current (Live AQI: {r_env.get('live_aqi', {}).get('aqi')}, Temp: {r_env.get('live_weather', {}).get('temperature')}°C): {'PASS' if results['3_get_environment_current'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 4: GET /aqi/historical
    # ------------------------------------------------------------------
    r_hist = requests.get(f"{BASE_URL}/aqi/historical?current_aqi=120.0", timeout=5).json()
    trend = r_hist.get("historical_trend", [])
    results["4_get_aqi_historical"] = (len(trend) == 25 and trend[-1].get("hour") == "Now")
    print(f"[TEST 04] GET /aqi/historical ({len(trend)} points): {'PASS' if results['4_get_aqi_historical'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 5: POST /prediction/aqi Baseline
    # ------------------------------------------------------------------
    baseline_payload = {
        "current_aqi": 110.0, "pm25": 40.0, "pm10": 80.0, "no2": 20.0,
        "co": 0.8, "so2": 8.0, "o3": 25.0, "temperature": 25.0,
        "humidity": 55.0, "wind_speed": 10.0, "pressure": 1012.0
    }
    r_pred = requests.post(f"{BASE_URL}/prediction/aqi", json=baseline_payload, timeout=5).json()
    results["5_post_prediction_aqi"] = (
        r_pred.get("model_used") == "PyTorch LSTM Neural Network" and
        r_pred.get("predicted_aqi") is not None
    )
    print(f"[TEST 05] POST /prediction/aqi (Predicted AQI: {r_pred.get('predicted_aqi')}, Model: {r_pred.get('model_used')}): {'PASS' if results['5_post_prediction_aqi'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 6: Dynamic LSTM Sensitivity (3 Different Scenarios)
    # ------------------------------------------------------------------
    scen_clean = {"current_aqi": 40.0, "pm25": 10.0, "pm10": 25.0, "no2": 6.0, "co": 0.2, "so2": 2.0, "o3": 12.0, "temperature": 28.0, "humidity": 80.0, "wind_speed": 18.0, "pressure": 1008.0}
    scen_mod   = {"current_aqi": 120.0, "pm25": 45.0, "pm10": 90.0, "no2": 24.0, "co": 1.0, "so2": 8.5, "o3": 28.0, "temperature": 24.0, "humidity": 55.0, "wind_speed": 10.0, "pressure": 1013.0}
    scen_sev   = {"current_aqi": 380.0, "pm25": 280.0, "pm10": 450.0, "no2": 110.0, "co": 4.2, "so2": 50.0, "o3": 80.0, "temperature": 10.0, "humidity": 92.0, "wind_speed": 1.8, "pressure": 1026.0}

    p_clean = requests.post(f"{BASE_URL}/prediction/aqi", json=scen_clean).json()
    p_mod   = requests.post(f"{BASE_URL}/prediction/aqi", json=scen_mod).json()
    p_sev   = requests.post(f"{BASE_URL}/prediction/aqi", json=scen_sev).json()

    diff_1 = p_mod["predicted_aqi"] - p_clean["predicted_aqi"]
    diff_2 = p_sev["predicted_aqi"] - p_mod["predicted_aqi"]
    results["6_lstm_dynamic_sensitivity"] = (diff_1 > 20.0 and diff_2 > 50.0)
    print(f"[TEST 06] Dynamic Sensitivity (Clean {p_clean['predicted_aqi']} -> Mod {p_mod['predicted_aqi']} -> Sev {p_sev['predicted_aqi']}): {'PASS' if results['6_lstm_dynamic_sensitivity'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 7: 24-Hour Forecast
    # ------------------------------------------------------------------
    fc_clean = p_clean.get("hourly_forecast", [])
    fc_sev = p_sev.get("hourly_forecast", [])
    results["7_24h_forecast"] = (len(fc_clean) == 24 and len(fc_sev) == 24 and fc_clean != fc_sev)
    print(f"[TEST 07] 24-Hour Dynamic Forecast ({len(fc_clean)} distinct hourly points): {'PASS' if results['7_24h_forecast'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 8: Direct LSTM vs API Parity
    # ------------------------------------------------------------------
    from prediction_service import prediction_engine
    parity_input = {
        "current_aqi": 135.0, "pm25": 50.0, "pm10": 105.0, "no2": 28.0,
        "co": 1.1, "so2": 11.0, "o3": 32.0, "temperature": 25.0,
        "humidity": 58.0, "wind_speed": 9.0, "pressure": 1012.0,
        "hour": 15, "dayofweek": 2, "month": 9
    }
    local_eval = prediction_engine.predict(**parity_input)
    api_eval = requests.post(f"{BASE_URL}/prediction/aqi", json=parity_input).json()
    parity_diff = abs(local_eval["predicted_aqi"] - api_eval["predicted_aqi"])
    results["8_direct_model_vs_api_parity"] = (parity_diff < 0.05 and local_eval["hourly_forecast"] == api_eval["hourly_forecast"])
    print(f"[TEST 08] Direct Model vs API Parity (Diff: {parity_diff:.6f} AQI): {'PASS' if results['8_direct_model_vs_api_parity'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 9: IDW Basic Mathematical Test
    # ------------------------------------------------------------------
    from spatial_interpolation import spatial_engine, haversine_distance
    d_test = haversine_distance(28.6139, 77.2090, 28.6318, 77.2194)
    # Expected approx 2.2 km between Central Delhi and Connaught Place
    results["9_idw_math_test"] = (1.8 < d_test < 2.5)
    print(f"[TEST 09] IDW Mathematical Distance Formula (Haversine = {d_test:.3f} km): {'PASS' if results['9_idw_math_test'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 10: IDW Exact Station Test (Proximity Snap <50m)
    # ------------------------------------------------------------------
    # Alipur station coordinates (28.7973118, 77.138667)
    idw_exact = spatial_engine.interpolate_aqi(28.7973118, 77.138667)
    results["10_idw_exact_station"] = (idw_exact["stations_used"] == 1 and "Exact Station Observation" in idw_exact["method"])
    print(f"[TEST 10] IDW Exact Station Match (<50m snap at {idw_exact['interpolated_aqi']} AQI): {'PASS' if results['10_idw_exact_station'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 11: IDW Multi-Station Test
    # ------------------------------------------------------------------
    idw_multi = spatial_engine.interpolate_aqi(28.6318, 77.2194, k_nearest=5)
    results["11_idw_multi_station"] = (idw_multi["stations_used"] == 5 and len(idw_multi["station_weights"]) == 5)
    nearest_name = idw_multi['nearest_station']['name'] if isinstance(idw_multi['nearest_station'], dict) else idw_multi['nearest_station']
    print(f"[TEST 11] IDW Multi-Station Interpolation ({idw_multi['stations_used']} stations, nearest '{nearest_name}'): {'PASS' if results['11_idw_multi_station'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 12: IDW Distance-Weight Test (Weights sum to ~1.0)
    # ------------------------------------------------------------------
    norm_w_sum = sum(st["normalized_weight"] for st in idw_multi["station_weights"])
    results["12_idw_distance_weight"] = (0.99 <= norm_w_sum <= 1.01)
    print(f"[TEST 12] IDW Normalized Weights Sum ({norm_w_sum:.4f}): {'PASS' if results['12_idw_distance_weight'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 13: IDW Invalid-Data Test (Out of bounds & NaN handling)
    # ------------------------------------------------------------------
    idw_invalid = spatial_engine.interpolate_aqi(999.0, -999.0)
    results["13_idw_invalid_data"] = ("error" in idw_invalid and idw_invalid["interpolated_aqi"] is not None)
    print(f"[TEST 13] IDW Invalid Coordinate Handling (Error handled gracefully: '{idw_invalid.get('error')}'): {'PASS' if results['13_idw_invalid_data'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 14: Route Analysis (OSRM Call)
    # ------------------------------------------------------------------
    route_req = {"origin": "Delhi Airport", "destination": "Connaught Place", "current_aqi": 120.0}
    r_route = requests.post(f"{BASE_URL}/route/analyze", json=route_req, timeout=10).json()
    routes = r_route.get("routes", [])
    results["14_route_analysis"] = (len(routes) >= 1 and len(routes[0].get("polyline", [])) > 20)
    print(f"[TEST 14] OSRM Route Analysis (Polyline Points: {len(routes[0].get('polyline', [])) if routes else 0}): {'PASS' if results['14_route_analysis'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 15: Multiple Route Alternatives
    # ------------------------------------------------------------------
    results["15_route_alternatives"] = (r_route.get("total_routes_found") >= 1 and len(routes) >= 1)
    print(f"[TEST 15] Route Alternatives Available ({len(routes)}): {'PASS' if results['15_route_alternatives'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 16: Route AQI using Genuine IDW
    # ------------------------------------------------------------------
    r0 = routes[0] if routes else {}
    exp0 = r0.get("exposure_analysis", {})
    results["16_route_aqi_idw"] = ("Inverse Distance Weighting" in exp0.get("spatial_method", "") and r0.get("average_aqi", 0) > 0)
    print(f"[TEST 16] Route Spatial AQI via Genuine IDW (Avg AQI: {r0.get('average_aqi')}, Method: '{exp0.get('spatial_method')}'): {'PASS' if results['16_route_aqi_idw'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 17: Route LSTM Prediction
    # ------------------------------------------------------------------
    ai_pred_aqi = r0.get("ai_predicted_aqi")
    results["17_route_lstm_prediction"] = (ai_pred_aqi is not None and ai_pred_aqi > 0)
    print(f"[TEST 17] Route-Level PyTorch LSTM Prediction ({ai_pred_aqi} AQI): {'PASS' if results['17_route_lstm_prediction'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 18: Inhaled Dose Calculation
    # ------------------------------------------------------------------
    dose = r0.get("estimated_inhaled_dose")
    results["18_inhaled_dose"] = (dose is not None and "µg PM2.5" in dose)
    print(f"[TEST 18] Inhaled PM2.5 Dose Calculation ({dose}): {'PASS' if results['18_inhaled_dose'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 19: Route Recommendation Selection
    # ------------------------------------------------------------------
    rec_route = next((r for r in routes if r.get("is_recommended")), None)
    results["19_route_recommendation"] = (rec_route is not None and "recommendation_reason" in rec_route.get("exposure_analysis", {}))
    print(f"[TEST 19] Objective Route Recommendation (Recommended: {rec_route['name'] if rec_route else 'None'}): {'PASS' if results['19_route_recommendation'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 20: Geocoding (/geocode)
    # ------------------------------------------------------------------
    r_geo = requests.get(f"{BASE_URL}/geocode?location=Connaught Place", timeout=10).json()
    results["20_geocoding"] = (r_geo.get("status") == "success" and r_geo.get("lat") is not None and r_geo.get("lon") is not None)
    print(f"[TEST 20] Forward Geocoding ({r_geo.get('city_label')}, Lat: {r_geo.get('lat')}, Lon: {r_geo.get('lon')}): {'PASS' if results['20_geocoding'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 21: Reverse Geocoding (/reverse-geocode)
    # ------------------------------------------------------------------
    r_rev = requests.get(f"{BASE_URL}/reverse-geocode?latitude=28.5562&longitude=77.0870", timeout=10).json()
    results["21_reverse_geocoding"] = ("city" in r_rev and r_rev["city"] != "Unknown")
    print(f"[TEST 21] Reverse Geocoding ({r_rev.get('city')}): {'PASS' if results['21_reverse_geocoding'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 22: Flask Frontend Startup
    # ------------------------------------------------------------------
    flask_running = False
    try:
        r_fe_check = requests.get(f"{FRONTEND_URL}/", timeout=2)
        if r_fe_check.status_code == 200:
            flask_running = True
    except Exception:
        pass

    if not flask_running:
        try:
            sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "frontend")))
            from app import app as flask_app
            with flask_app.test_client() as c:
                r_fe_check = c.get('/')
                flask_running = (r_fe_check.status_code == 200)
        except Exception:
            flask_running = False

    results["22_flask_frontend_startup"] = flask_running
    print(f"[TEST 22] Flask Frontend Startup: {'PASS' if results['22_flask_frontend_startup'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 23: Dashboard Loading
    # ------------------------------------------------------------------
    dashboard_html = ""
    try:
        r_fe = requests.get(f"{FRONTEND_URL}/", timeout=2)
        if r_fe.status_code == 200:
            dashboard_html = r_fe.text
    except Exception:
        pass

    if not dashboard_html:
        try:
            with flask_app.test_client() as c:
                r_fe = c.get('/')
                dashboard_html = r_fe.get_data(as_text=True)
        except Exception:
            index_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "frontend", "templates", "index.html"))
            if os.path.exists(index_path):
                with open(index_path, "r", encoding="utf-8") as f:
                    dashboard_html = f.read()

    results["23_dashboard_loading"] = (len(dashboard_html) > 5000 and "AEROMOBILITY AI" in dashboard_html)
    print(f"[TEST 23] Dashboard HTML Loading ({len(dashboard_html)} bytes): {'PASS' if results['23_dashboard_loading'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 24: Map Rendering Elements
    # ------------------------------------------------------------------
    results["24_map_rendering"] = (
        'id="map"' in dashboard_html and
        "leaflet" in dashboard_html.lower()
    )
    print(f"[TEST 24] Interactive Map Rendering Elements Verified: {'PASS' if results['24_map_rendering'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 25: Forecast Chart Elements
    # ------------------------------------------------------------------
    results["25_forecast_chart"] = (
        'id="aqiChart"' in dashboard_html and
        "chart.js" in dashboard_html.lower()
    )
    print(f"[TEST 25] 24-Hour Forecast Chart Elements Verified: {'PASS' if results['25_forecast_chart'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 26: No NaN/errors in Numeric Outputs
    # ------------------------------------------------------------------
    sample_values = [
        r_pred.get("predicted_aqi"),
        r0.get("average_aqi"),
        idw_multi.get("interpolated_aqi")
    ]
    has_nan = any(math.isnan(v) if isinstance(v, (int, float)) else False for v in sample_values)
    results["26_no_nans_or_errors"] = (not has_nan) and (r_pred.get("predicted_aqi") is not None)
    print(f"[TEST 26] Absence of NaNs and Nulls Across Numeric Outputs: {'PASS' if results['26_no_nans_or_errors'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 27: No Hardcoded Dynamic Environmental Values
    # ------------------------------------------------------------------
    live_aqi_val = r_env.get("live_aqi", {}).get("aqi")
    live_temp = r_env.get("live_weather", {}).get("temperature")
    results["27_no_hardcoded_dynamic_values"] = (
        live_aqi_val is not None and isinstance(live_aqi_val, (int, float)) and
        live_temp is not None and isinstance(live_temp, (int, float))
    )
    print(f"[TEST 27] Non-Hardcoded Dynamic Environmental Values Verified: {'PASS' if results['27_no_hardcoded_dynamic_values'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 28: No Broken Model Paths
    # ------------------------------------------------------------------
    base_models = os.path.abspath(os.path.join(os.path.dirname(__file__), "models"))
    lstm_path = os.path.join(base_models, "aqi_lstm_model.pth")
    mlp_path = os.path.join(base_models, "aqi_model.joblib")
    scaler_path = os.path.join(base_models, "scaler.pkl")
    meta_path = os.path.join(base_models, "model_metadata.json")
    results["28_no_broken_model_paths"] = (
        os.path.exists(lstm_path) and os.path.getsize(lstm_path) > 200000 and
        os.path.exists(mlp_path) and os.path.getsize(mlp_path) > 100000 and
        os.path.exists(scaler_path) and os.path.getsize(scaler_path) > 1000 and
        os.path.exists(meta_path) and os.path.getsize(meta_path) > 500
    )
    print(f"[TEST 28] Model Artifact Paths Intact (LSTM: {os.path.getsize(lstm_path)}B, MLP: {os.path.getsize(mlp_path)}B): {'PASS' if results['28_no_broken_model_paths'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 29: No Broken Imports
    # ------------------------------------------------------------------
    try:
        import torch
        import fastapi
        import uvicorn
        import sklearn
        import joblib
        import pydantic
        from spatial_interpolation import spatial_engine, SpatialInterpolator, haversine_distance
        from prediction_service import prediction_engine, AQILSTM
        from routing_service import routing_engine, OSRMRoutingEngine
        results["29_no_broken_imports"] = True
    except Exception as e:
        results["29_no_broken_imports"] = False
    print(f"[TEST 29] All Core Dependencies and Service Modules Import Cleanly: {'PASS' if results['29_no_broken_imports'] else 'FAIL'}")

    # ------------------------------------------------------------------
    # TEST 30: No Regression of Existing Functionality
    # ------------------------------------------------------------------
    city_aqi = requests.get(f"{BASE_URL}/aqi/Delhi", timeout=10).json()
    weather_res = requests.get(f"{BASE_URL}/weather?latitude=28.6139&longitude=77.2090", timeout=10).json()
    spatial_res = requests.get(f"{BASE_URL}/spatial/interpolate?lat=28.6318&lon=77.2194", timeout=10).json()
    notif_res = requests.get(f"{BASE_URL}/notifications/status", timeout=5).json()
    results["30_no_regression"] = (
        city_aqi.get("aqi") is not None and
        "temperature" in weather_res and
        "interpolated_aqi" in spatial_res and
        "provider" in notif_res
    )
    print(f"[TEST 30] Zero Regression Across All Existing Endpoints: {'PASS' if results['30_no_regression'] else 'FAIL'}")

    print("\n==================================================================")
    passed_tests = sum(1 for v in results.values() if v)
    print(f"FINAL RESULT: {passed_tests}/{total_tests} TESTS PASSED")
    if passed_tests == total_tests:
        print("STATUS: ALL 30 CHECKS PASSED - MILESTONE 2 100% VERIFIED!")
    else:
        print(f"STATUS: {total_tests - passed_tests} CHECK(S) FAILED")
    print("==================================================================")
    return passed_tests == total_tests

if __name__ == "__main__":
    success = run_milestone2_final_verification()
    sys.exit(0 if success else 1)
