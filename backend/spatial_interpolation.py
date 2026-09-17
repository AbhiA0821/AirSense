import json
import math
import os
from typing import Dict, List, Optional, Tuple, Any

EARTH_RADIUS_KM = 6371.0088

class SpatialInterpolator:
    """
    Inverse Distance Weighting (IDW) spatial interpolation engine for Air Quality Index.
    Uses real geospatial coordinates from CPCB/DPCC/IMD monitoring stations in Delhi-NCR.
    """

    def __init__(self, stations_file: Optional[str] = None):
        if stations_file is None:
            base_dir = os.path.dirname(os.path.abspath(__file__))
            stations_file = os.path.join(base_dir, "models", "delhi_stations.json")
        
        self.stations_file = stations_file
        self.stations = self._load_stations()

    def _load_stations(self) -> List[Dict[str, Any]]:
        if os.path.exists(self.stations_file):
            with open(self.stations_file, "r") as f:
                return json.load(f)
        return []

    @staticmethod
    def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """
        Calculates great-circle distance between two geographic coordinates in kilometers.
        Formula:
            a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
            c = 2 * atan2(√a, √(1-a))
            d = R * c
        """
        phi1 = math.radians(lat1)
        phi2 = math.radians(lat2)
        delta_phi = math.radians(lat2 - lat1)
        delta_lambda = math.radians(lon2 - lon1)

        a = (math.sin(delta_phi / 2.0) ** 2 +
             math.cos(phi1) * math.cos(phi2) * (math.sin(delta_lambda / 2.0) ** 2))
        
        # Clamp a within [0, 1] to avoid floating point domain errors in sqrt
        a = min(1.0, max(0.0, a))
        c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
        return EARTH_RADIUS_KM * c

    def interpolate_aqi(
        self,
        lat: float,
        lon: float,
        current_base_aqi: Optional[float] = None,
        base_aqi_scale: Optional[float] = None,
        station_observations: Optional[List[Dict[str, Any]]] = None,
        power: float = 2.0,
        k_nearest: Optional[int] = 5
    ) -> Dict[str, Any]:
        """
        Interpolates AQI at target coordinates (lat, lon) using Inverse Distance Weighting (IDW).
        Formula:
            w_i = 1 / d(x, x_i)^p
            Z(x) = Σ(w_i × Z_i) / Σ(w_i)
        
        Parameters:
            lat: Target latitude
            lon: Target longitude
            current_base_aqi: Current live regional AQI (used to scale station baselines dynamically)
            base_aqi_scale: Alias for current_base_aqi
            station_observations: Optional live overrides for station AQI values
            power: IDW power parameter (default: 2.0)
            k_nearest: Limit to the k nearest stations (default: 5, None uses all)
        """
        if current_base_aqi is None and base_aqi_scale is not None:
            current_base_aqi = base_aqi_scale

        # Robust coordinate validity check - return graceful error dict rather than crash
        if not (-90.0 <= lat <= 90.0 and -180.0 <= lon <= 180.0):
            fallback_val = current_base_aqi if current_base_aqi is not None else 120.0
            return {
                "target_coordinates": {"lat": lat, "lon": lon},
                "interpolated_aqi": fallback_val,
                "method": "out_of_bounds_fallback",
                "error": f"Invalid geographic coordinates: ({lat}, {lon})",
                "stations_used": 0,
                "k_stations_used": 0,
                "nearest_station": None,
                "nearest_distance_km": None,
                "station_weights": [],
                "contributing_stations": []
            }

        active_stations = station_observations if station_observations else self.stations
        if not active_stations:
            fallback_val = current_base_aqi if current_base_aqi is not None else 120.0
            return {
                "target_coordinates": {"lat": lat, "lon": lon},
                "interpolated_aqi": fallback_val,
                "method": "fallback_no_stations",
                "error": "No monitoring stations available",
                "stations_used": 0,
                "k_stations_used": 0,
                "nearest_station": None,
                "nearest_distance_km": None,
                "station_weights": [],
                "contributing_stations": []
            }

        # Compute distances to all stations
        station_distances: List[Tuple[float, Dict[str, Any], float]] = []
        
        # Determine global mean ratio if live current_base_aqi provided
        base_scaling = 1.0
        if current_base_aqi is not None and current_base_aqi > 0:
            dataset_mean = 235.0  # Dataset mean across all Delhi stations
            base_scaling = current_base_aqi / dataset_mean

        for st in active_stations:
            st_lat = st.get("lat")
            st_lon = st.get("lon")
            if st_lat is None or st_lon is None:
                continue

            dist = self.haversine_distance(lat, lon, st_lat, st_lon)
            
            # Determine station AQI: explicit live reading -> scaled historical mean -> default
            if "aqi" in st and st["aqi"] is not None:
                st_aqi = float(st["aqi"])
            elif "historical_mean_aqi" in st and st["historical_mean_aqi"] is not None:
                st_aqi = float(st["historical_mean_aqi"]) * base_scaling
            elif current_base_aqi is not None:
                st_aqi = float(current_base_aqi)
            else:
                st_aqi = 120.0

            # Exact match threshold: within 50 meters (0.05 km)
            if dist < 0.05:
                station_dict = {
                    "id": st.get("id"),
                    "name": st.get("name"),
                    "distance_km": round(dist, 4),
                    "aqi": round(st_aqi, 2),
                    "normalized_weight": 1.0,
                    "weight": 1.0
                }
                return {
                    "target_coordinates": {"lat": round(lat, 6), "lon": round(lon, 6)},
                    "interpolated_aqi": round(st_aqi, 2),
                    "method": "Exact Station Observation (<50m proximity)",
                    "stations_used": 1,
                    "k_stations_used": 1,
                    "nearest_station": {"name": st.get("name", st.get("id")), "id": st.get("id"), "distance_km": round(dist, 4)},
                    "nearest_distance_km": round(dist, 4),
                    "station_weights": [station_dict],
                    "contributing_stations": [station_dict]
                }

            station_distances.append((dist, st, st_aqi))

        if not station_distances:
            fallback_val = current_base_aqi if current_base_aqi is not None else 120.0
            return {
                "target_coordinates": {"lat": lat, "lon": lon},
                "interpolated_aqi": fallback_val,
                "method": "fallback_no_valid_stations",
                "stations_used": 0,
                "k_stations_used": 0,
                "nearest_station": None,
                "nearest_distance_km": None,
                "station_weights": [],
                "contributing_stations": []
            }

        # Sort by distance
        station_distances.sort(key=lambda x: x[0])

        # Filter to k nearest if specified
        if k_nearest is not None and k_nearest > 0:
            selected = station_distances[:k_nearest]
        else:
            selected = station_distances

        # Compute IDW weights: w_i = 1 / (d_i ^ p)
        total_weight = 0.0
        weighted_aqi_sum = 0.0
        contributions = []

        for dist, st, st_aqi in selected:
            # Avoid division by zero with small epsilon
            eff_dist = max(dist, 0.0001)
            w = 1.0 / (eff_dist ** power)
            total_weight += w
            weighted_aqi_sum += w * st_aqi
            contributions.append({
                "id": st.get("id"),
                "name": st.get("name"),
                "distance_km": round(dist, 3),
                "aqi": round(st_aqi, 2),
                "raw_weight": w
            })

        if total_weight <= 0:
            interp_aqi = current_base_aqi if current_base_aqi is not None else 120.0
        else:
            interp_aqi = weighted_aqi_sum / total_weight

        # Normalize weights so sum is 1.0
        for c in contributions:
            c["normalized_weight"] = round(c["raw_weight"] / total_weight, 4) if total_weight > 0 else 0.0
            del c["raw_weight"]

        nearest_dist, nearest_st, nearest_aqi = selected[0]
        nearest_dict = {
            "name": nearest_st.get("name", nearest_st.get("id")),
            "id": nearest_st.get("id"),
            "distance_km": round(nearest_dist, 3)
        }

        return {
            "target_coordinates": {"lat": round(lat, 6), "lon": round(lon, 6)},
            "interpolated_aqi": round(interp_aqi, 2),
            "method": f"Inverse Distance Weighting (IDW, p={power})",
            "power": power,
            "stations_used": len(selected),
            "k_stations_used": len(selected),
            "nearest_station": nearest_dict,
            "nearest_distance_km": round(nearest_dist, 3),
            "station_weights": contributions,
            "contributing_stations": contributions
        }


# Global singleton instance & module-level exports
spatial_interpolator = SpatialInterpolator()
spatial_engine = spatial_interpolator
haversine_distance = SpatialInterpolator.haversine_distance

