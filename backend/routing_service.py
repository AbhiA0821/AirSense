"""
Routing Service Module for AI-Powered Environmental Intelligence System
Integrates Open Source Routing Machine (OSRM) API for real road routing, distance, duration, and route exposure analysis.
"""

import requests
import math

from prediction_service import prediction_engine
from spatial_interpolation import spatial_engine

class OSRMRoutingEngine:
    def __init__(self):
        self.osrm_urls = [
            "http://router.project-osrm.org/route/v1/driving",
            "https://router.project-osrm.org/route/v1/driving"
        ]

    def get_route(self, origin_lat: float, origin_lon: float, dest_lat: float, dest_lon: float, current_aqi: float = 120.0):
        """
        Retrieves real road route polyline geometry, distance, and duration from OSRM for all available alternatives.
        Computes route-level pollution exposure scores and AI predicted AQI for each route independently.
        """
        headers = {"User-Agent": "AI-Environmental-Intelligence-System/2.0"}
        params = {
            "overview": "full",
            "geometries": "geojson",
            "steps": "true",
            "alternatives": "true"
        }

        print(f"\n[OSRMRoutingEngine] Requesting Route: Origin({origin_lat:.4f}, {origin_lon:.4f}) -> Destination({dest_lat:.4f}, {dest_lon:.4f}) | Base AQI: {current_aqi}")

        data = None
        used_url = None

        for base_url in self.osrm_urls:
            url = f"{base_url}/{origin_lon},{origin_lat};{dest_lon},{dest_lat}"
            try:
                response = requests.get(url, params=params, headers=headers, timeout=8)
                if response.status_code == 200:
                    data = response.json()
                    used_url = url
                    break
            except Exception as req_err:
                print(f"[OSRMRoutingEngine] Failed connecting to {base_url}: {req_err}")
                continue

        if not data or data.get("code") != "Ok" or not data.get("routes"):
            print(f"[OSRMRoutingEngine] No valid routes returned by OSRM API. Triggering direct fallback.")
            return self._fallback_route(origin_lat, origin_lon, dest_lat, dest_lon, current_aqi, "OSRM routing service unavailable")

        raw_routes = data["routes"]
        parsed_routes = []
        seen_geometries = set()

        print(f"[OSRMRoutingEngine] Received {len(raw_routes)} route alternative(s) from OSRM.")

        for idx, r in enumerate(raw_routes):
            dist_m = r.get("distance", 0)
            dur_s = r.get("duration", 0)
            coords = r.get("geometry", {}).get("coordinates", [])
            polyline = [[pt[1], pt[0]] for pt in coords]
            dist_km = round(dist_m / 1000.0, 2)
            dur_min = round(dur_s / 60.0)
            geometry_pts = len(polyline)

            # Deduplicate routes with identical distance and point count
            geom_key = (dist_km, dur_min, geometry_pts)
            if geom_key in seen_geometries:
                continue
            seen_geometries.add(geom_key)

            route_idx = len(parsed_routes)

            # Spatial AQI calculation specific to route geometry
            exp = self._calculate_route_exposure(polyline, current_aqi, dist_km, dur_min, route_idx)

            # Route-level AI AQI prediction using trained Deep MLP Neural Network
            ai_pred_res = prediction_engine.predict(current_aqi=exp["average_route_aqi"])
            ai_pred_val = ai_pred_res.get("predicted_aqi", exp["average_route_aqi"])

            route_name = "Direct Primary Route" if route_idx == 0 else f"Alternative Corridor {route_idx}"

            parsed_routes.append({
                "route_index": route_idx + 1,
                "name": route_name,
                "distance_km": dist_km,
                "duration_minutes": dur_min,
                "geometry_point_count": geometry_pts,
                "polyline": polyline,
                "average_aqi": exp["average_route_aqi"],
                "ai_predicted_aqi": ai_pred_val,
                "exposure_level": exp["exposure_level"],
                "estimated_inhaled_dose": exp["estimated_inhaled_dose"],
                "traffic_status": "Live traffic unavailable (OSRM)",
                "recommendation": exp["recommendation"],
                "exposure_analysis": exp,
                "is_recommended": False
            })

            print(f"   Route {route_idx + 1}: distance={dist_km} km, duration={dur_min} mins, geometry_points={geometry_pts}, route_aqi={exp['average_route_aqi']}, ai_predicted_aqi={ai_pred_val}, exposure={exp['exposure_level']}")

            if len(parsed_routes) >= 3:
                break

        # Select Lowest Exposure Route
        lowest_idx = min(range(len(parsed_routes)), key=lambda i: (parsed_routes[i]["average_aqi"], parsed_routes[i]["duration_minutes"]))
        parsed_routes[lowest_idx]["is_recommended"] = True
        parsed_routes[lowest_idx]["recommendation_tag"] = "✓ RECOMMENDED - LOWEST EXPOSURE"

        rec_route = parsed_routes[lowest_idx]
        reason_msg = (
            f"Recommended because {rec_route['name']} offers the lowest estimated pollution exposure "
            f"(Average AQI: {rec_route['average_aqi']}, Estimated PM2.5 Dose: {rec_route['estimated_inhaled_dose']}) "
            f"among available road corridors."
        )
        rec_route["exposure_analysis"]["recommendation_reason"] = reason_msg

        # Construct structured multi-route comparison
        comparison_list = []
        for idx, r in enumerate(parsed_routes):
            comparison_list.append({
                "route_index": idx + 1,
                "name": r["name"],
                "distance_km": r["distance_km"],
                "duration_minutes": r["duration_minutes"],
                "average_aqi": r["average_aqi"],
                "ai_predicted_aqi": r["ai_predicted_aqi"],
                "pm25_exposure_dose": r["estimated_inhaled_dose"],
                "exposure_level": r["exposure_level"],
                "is_recommended": (idx == lowest_idx)
            })

        smart_rec = {
            "recommended_route": rec_route["name"],
            "environmental_exposure": "Lower",
            "distance_km": rec_route["distance_km"],
            "duration_minutes": rec_route["duration_minutes"],
            "average_aqi": rec_route["average_aqi"],
            "ai_predicted_aqi": rec_route["ai_predicted_aqi"],
            "pm25_exposure": rec_route["estimated_inhaled_dose"],
            "exposure_level": rec_route["exposure_level"],
            "selection_rationale": reason_msg,
            "traffic_limitation": "Live vehicular traffic data is unavailable from OSRM; travel duration reflects standard road speed profiles."
        }

        print(f"[OSRMRoutingEngine] Selection Complete: Recommended Route {lowest_idx + 1} ({rec_route['name']})\n")

        route_availability_note = f"{len(parsed_routes)} route option{'s' if len(parsed_routes) > 1 else ''} available"
        if len(parsed_routes) == 1:
            route_availability_note = "1 route available from routing service"

        return {
            "status": "success",
            "routing_provider": f"Open Source Routing Machine ({route_availability_note})",
            "total_routes_found": len(parsed_routes),
            "recommended_route_index": lowest_idx + 1,
            "recommended_route_name": rec_route["name"],
            "smart_recommendation": smart_rec,
            "route_comparison": comparison_list,
            "routes": parsed_routes,
            "distance_km": rec_route["distance_km"],
            "duration_minutes": rec_route["duration_minutes"],
            "polyline": rec_route["polyline"],
            "traffic_status": "Live traffic unavailable (OSRM)",
            "traffic_limitation": "Live vehicular traffic data is unavailable from OSRM; travel duration reflects standard road speed profiles.",
            "traffic_delay_minutes": 0,
            "origin": {"lat": origin_lat, "lon": origin_lon},
            "destination": {"lat": dest_lat, "lon": dest_lon},
            "exposure_analysis": rec_route["exposure_analysis"]
        }

    def _calculate_route_exposure(self, polyline, base_aqi, distance_km, duration_min, route_idx=0):
        """
        Calculates genuine spatial route AQI and estimated inhaled dose along route polyline geometry
        using Inverse Distance Weighting (IDW) against real Delhi monitoring stations.
        """
        if not polyline:
            return {
                "average_route_aqi": base_aqi,
                "exposure_level": "Moderate Exposure",
                "estimated_inhaled_dose": "N/A",
                "recommendation": "Standard mobility advisory."
            }

        num_points = len(polyline)
        
        # Select up to 20 evenly spaced sample points along the route polyline for efficient computation
        max_samples = 20
        if num_points <= max_samples:
            sampled_coords = polyline
        else:
            step = max(1, num_points // max_samples)
            sampled_coords = [polyline[i] for i in range(0, num_points, step)]
            if polyline[-1] not in sampled_coords:
                sampled_coords.append(polyline[-1])

        sample_aqis = []
        station_influences = []

        for lat, lon in sampled_coords:
            # Genuine IDW interpolation using real Delhi stations from dataset
            idw_res = spatial_engine.interpolate_aqi(
                lat=lat,
                lon=lon,
                power=2.0,
                k_nearest=5,
                base_aqi_scale=base_aqi
            )
            pt_aqi = idw_res.get("interpolated_aqi", base_aqi)
            sample_aqis.append(pt_aqi)
            if "nearest_station" in idw_res and idw_res["nearest_station"]:
                st_val = idw_res["nearest_station"]
                station_influences.append(st_val if isinstance(st_val, str) else st_val.get("name", str(st_val)))

        avg_route_aqi = round(sum(sample_aqis) / len(sample_aqis), 1)

        # Inhaled PM2.5 dose estimation: PM2.5 conc (ug/m3) * duration (min) * breathing rate (~0.012 m3/min)
        estimated_pm25 = avg_route_aqi * 0.4  # approximate PM2.5 ug/m3 scale factor
        inhaled_dose_ug = round(estimated_pm25 * duration_min * 0.012, 1)

        if avg_route_aqi <= 50:
            exp_level = "Low Exposure"
            recom = "Optimal air quality along this corridor. Safe for travel."
        elif avg_route_aqi <= 100:
            exp_level = "Moderate Exposure"
            recom = "Acceptable air quality. Vehicle ventilation recommended."
        elif avg_route_aqi <= 150:
            exp_level = "Elevated Exposure"
            recom = "Elevated pollution zone. Use cabin air recirculation."
        elif avg_route_aqi <= 200:
            exp_level = "High Exposure"
            recom = "High pollution corridor. Keep windows closed and wear N95 mask if outdoors."
        else:
            exp_level = "Severe Exposure"
            recom = "Severe pollution zone. Minimize travel duration."

        # Unique stations sampled
        unique_stations = list(dict.fromkeys(station_influences))

        return {
            "avg_route_aqi": avg_route_aqi,
            "average_route_aqi": avg_route_aqi,
            "min_route_aqi": min(sample_aqis),
            "max_route_aqi": max(sample_aqis),
            "sampling_points": len(sampled_coords),
            "total_geometry_points": num_points,
            "exposure_level": exp_level,
            "estimated_inhaled_dose": f"{inhaled_dose_ug} µg PM2.5",
            "spatial_method": "Inverse Distance Weighting (IDW, p=2, 27 CPCB stations)",
            "key_monitoring_corridors": unique_stations[:3],
            "recommendation": recom
        }

    def _fallback_route(self, origin_lat, origin_lon, dest_lat, dest_lon, current_aqi, error_msg):
        R = 6371.0  # Earth radius km
        dlat = math.radians(dest_lat - origin_lat)
        dlon = math.radians(dest_lon - origin_lon)
        a = math.sin(dlat / 2)**2 + math.cos(math.radians(origin_lat)) * math.cos(math.radians(dest_lat)) * math.sin(dlon / 2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        distance_km = round(R * c, 2)
        duration_min = round((distance_km / 30.0) * 60)

        exp = self._calculate_route_exposure([[origin_lat, origin_lon], [dest_lat, dest_lon]], current_aqi, distance_km, duration_min)

        return {
            "status": "fallback",
            "routing_provider": f"Direct Distance Interpolation ({error_msg})",
            "total_routes_found": 1,
            "recommended_route_index": 1,
            "routes": [{
                "route_index": 1,
                "name": "Direct Interpolated Route",
                "distance_km": distance_km,
                "duration_minutes": duration_min,
                "polyline": [[origin_lat, origin_lon], [dest_lat, dest_lon]],
                "average_aqi": current_aqi,
                "exposure_level": exp["exposure_level"],
                "estimated_inhaled_dose": exp["estimated_inhaled_dose"],
                "recommendation": exp["recommendation"],
                "exposure_analysis": exp,
                "is_recommended": True,
                "recommendation_tag": "✓ LOWEST EXPOSURE"
            }],
            "distance_km": distance_km,
            "duration_minutes": duration_min,
            "polyline": [[origin_lat, origin_lon], [dest_lat, dest_lon]],
            "traffic_status": "Live traffic data unavailable",
            "traffic_delay_minutes": 0,
            "origin": {"lat": origin_lat, "lon": origin_lon},
            "destination": {"lat": dest_lat, "lon": dest_lon},
            "exposure_analysis": exp
        }

routing_engine = OSRMRoutingEngine()
