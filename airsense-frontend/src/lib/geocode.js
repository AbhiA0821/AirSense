// Location geocoding service:
// Prioritizes backend /geocode/search (instant response for Delhi landmarks and CPCB stations)
// with graceful client-side fallback to OpenStreetMap Nominatim.

import { searchLocationsApi } from "./api";

const DELHI_VIEWBOX = "76.80,28.90,77.40,28.35"; // left,top,right,bottom

export async function searchPlace(query, signal = null) {
  if (!query || query.trim().length < 2) return [];

  const trimmed = query.trim();

  // 1. Try backend geocode endpoint first
  try {
    const backendResults = await searchLocationsApi(trimmed, signal);
    if (backendResults && Array.isArray(backendResults) && backendResults.length > 0) {
      return backendResults.map((item) => ({
        name: item.name,
        address: item.address || "Delhi NCR, India",
        lat: parseFloat(item.lat),
        lon: parseFloat(item.lon),
        type: item.type || "place",
      }));
    }
  } catch (err) {
    if (err?.name === "AbortError") throw err;
    // Otherwise fallback to client-side Nominatim
  }

  // 2. Direct OpenStreetMap Nominatim fallback
  const url =
    `https://nominatim.openstreetmap.org/search?` +
    `q=${encodeURIComponent(trimmed + ", Delhi")}` +
    `&format=json&limit=6&viewbox=${DELHI_VIEWBOX}&bounded=1&addressdetails=1`;

  const res = await fetch(url, {
    headers: {
      "User-Agent": "AirSense-Intelligence-System/2.0",
    },
    signal,
  });

  if (!res.ok) throw new Error("Geocoding search failed");
  const data = await res.json();

  return data.map((item) => {
    const parts = (item.display_name || "").split(",");
    const name = item.name || parts[0]?.trim() || "Location";
    const address = parts.length > 1 ? parts.slice(1, 4).join(", ").trim() : "Delhi NCR, India";
    return {
      name,
      address,
      lat: parseFloat(item.lat),
      lon: parseFloat(item.lon),
      type: item.type || "osm_place",
    };
  });
}
