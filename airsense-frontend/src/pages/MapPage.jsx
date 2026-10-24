import { useCallback, useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import { useAppContext } from "../context/AppContext";
import MapView from "../components/MapView";
import LocationSearch from "../components/LocationSearch";
import { LocationResult, RouteOptionsResult } from "../components/ResultPanel";
import AqiTimelineChart from "../components/AqiTimelineChart";
import WeatherHistoryChart from "../components/WeatherHistoryChart";
import CleanNavigationHud from "../components/CleanNavigationHud";
import { predictAtLocation, routeOptions, getRouteAdvisory, getAqiTimeline, getWeatherHistory } from "../lib/api";

export default function MapPage() {
  const [searchParams] = useSearchParams();
  const initialMode = searchParams.get("mode") === "route" ? "route" : "location";
  const [mode, setMode] = useState(initialMode);

  const { ageGroup, healthNote, addHistoryEntry } = useAppContext();

  const [selectedPoint, setSelectedPoint] = useState(null);
  const [locationResult, setLocationResult] = useState(null);
  const [timeline, setTimeline] = useState(null);
  const [timelineLoading, setTimelineLoading] = useState(false);
  const [weatherHistory, setWeatherHistory] = useState(null);
  const [weatherLoading, setWeatherLoading] = useState(false);

  const [routeStart, setRouteStart] = useState(null);
  const [routeEnd, setRouteEnd] = useState(null);
  const [routes, setRoutes] = useState(null);
  const [aiAdvisory, setAiAdvisory] = useState(null);
  const [userPreference, setUserPreference] = useState("balanced");
  const [selectedRouteIndex, setSelectedRouteIndex] = useState(0);

  const [status, setStatus] = useState("");
  const [statusIsError, setStatusIsError] = useState(false);
  const [loading, setLoading] = useState(false);
  const [locating, setLocating] = useState(false);
  const [isNavigating, setIsNavigating] = useState(false);
  const [navRouteData, setNavRouteData] = useState(null);

  // Update mode if URL changes
  useEffect(() => {
    const urlMode = searchParams.get("mode") === "route" ? "route" : "location";
    if (urlMode !== mode) {
      switchMode(urlMode);
    }
  }, [searchParams]);

  function switchMode(next) {
    setMode(next);
    setSelectedPoint(null);
    setLocationResult(null);
    setTimeline(null);
    setWeatherHistory(null);
    setRouteStart(null);
    setRouteEnd(null);
    setRoutes(null);
    setAiAdvisory(null);
    setSelectedRouteIndex(0);
    setStatus("");
  }

  const handleClick = useCallback(
    (lat, lng) => {
      setStatus("");
      const formattedCoord = `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
      if (mode === "location") {
        setSelectedPoint({ lat, lng, label: `${formattedCoord} (Map Click)` });
        setLocationResult(null);
        setTimeline(null);
        setWeatherHistory(null);
        return;
      }

      setRouteStart((currentStart) => {
        if (!currentStart) return { lat, lng, label: `${formattedCoord} (Start)` };
        return currentStart;
      });

      setRouteEnd((currentEnd) => {
        if (!routeStart) return null;
        if (routeStart && !currentEnd) return { lat, lng, label: `${formattedCoord} (Destination)` };
        return null;
      });

      if (routeStart && routeEnd) {
        setRouteStart({ lat, lng, label: `${formattedCoord} (Start)` });
        setRouteEnd(null);
        setRoutes(null);
        setTimeline(null);
        setWeatherHistory(null);
        setSelectedRouteIndex(0);
      }
    },
    [mode, routeStart, routeEnd]
  );

  function handleLocationSearchSelect(lat, lon, label) {
    setSelectedPoint({ lat, lng: lon, label });
    setLocationResult(null);
    setTimeline(null);
    setWeatherHistory(null);
    setStatus("");
  }

  function handleStartSearchSelect(lat, lon, label) {
    setRouteStart({ lat, lng: lon, label });
    setRoutes(null);
    setTimeline(null);
    setWeatherHistory(null);
    setSelectedRouteIndex(0);
    setStatus("");
  }

  function handleEndSearchSelect(lat, lon, label) {
    setRouteEnd({ lat, lng: lon, label });
    setRoutes(null);
    setTimeline(null);
    setWeatherHistory(null);
    setSelectedRouteIndex(0);
    setStatus("");
  }

  function locateCurrentPosition(target) {
    if (!navigator.geolocation) {
      setStatus("Geolocation isn't supported in this browser.");
      setStatusIsError(true);
      return;
    }
    setLocating(true);
    setStatus("Detecting your current location…");
    setStatusIsError(false);

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        if (target === "location") {
          setSelectedPoint({ lat: latitude, lng: longitude, label: "Current Location" });
          setLocationResult(null);
          setTimeline(null);
          setWeatherHistory(null);
        } else if (target === "start") {
          setRouteStart({ lat: latitude, lng: longitude, label: "Current Location" });
          setRoutes(null);
          setTimeline(null);
          setWeatherHistory(null);
          setSelectedRouteIndex(0);
        } else if (target === "end") {
          setRouteEnd({ lat: latitude, lng: longitude, label: "Current Location" });
          setRoutes(null);
          setTimeline(null);
          setWeatherHistory(null);
          setSelectedRouteIndex(0);
        }
        setStatus("");
        setLocating(false);
      },
      (err) => {
        setStatus(`Couldn't get your location — ${err.message}`);
        setStatusIsError(true);
        setLocating(false);
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  }

  function getActiveChartCoords(overrideRouteIdx = selectedRouteIndex, routeList = routes) {
    if (mode === "location" && selectedPoint) {
      return { lat: selectedPoint.lat, lon: selectedPoint.lng };
    }
    if (mode === "route" && routeList && routeList.length > 0) {
      const r = routeList[overrideRouteIdx] || routeList[0];
      const pts = r.route_points || [];
      if (pts.length > 0) {
        const mid = pts[Math.floor(pts.length / 2)];
        return { lat: Number(mid.lat), lon: Number(mid.lon) };
      }
      if (routeStart && routeEnd) {
        return {
          lat: (routeStart.lat + routeEnd.lat) / 2,
          lon: (routeStart.lng + routeEnd.lng) / 2,
        };
      }
    }
    return null;
  }

  async function submitLocation() {
    if (!selectedPoint) return;
    setLoading(true);
    setStatus("Fetching prediction…");
    setStatusIsError(false);
    setTimeline(null);
    setWeatherHistory(null);
    try {
      const data = await predictAtLocation(selectedPoint.lat, selectedPoint.lng);
      setLocationResult(data);
      setStatus("");

      addHistoryEntry({
        type: "location",
        aqi: data.interpolated_aqi,
        locationLabel: selectedPoint.label || `${selectedPoint.lat.toFixed(4)}, ${selectedPoint.lng.toFixed(4)}`,
      });
    } catch (err) {
      setStatus(`Couldn't reach the API — ${err.message}`);
      setStatusIsError(true);
    } finally {
      setLoading(false);
    }
  }

  async function fetchTimeline(customCoords = null) {
    const coords = customCoords || getActiveChartCoords();
    if (!coords) return;
    setTimelineLoading(true);
    setStatus("Building 24h AQI trend & LSTM forecast for this coordinate…");
    setStatusIsError(false);
    try {
      const data = await getAqiTimeline(coords.lat, coords.lon, 24, 24);
      setTimeline(data);
      setStatus("");
    } catch (err) {
      setStatus(`Couldn't reach the API — ${err.message}`);
      setStatusIsError(true);
    } finally {
      setTimelineLoading(false);
    }
  }

  async function fetchWeatherHistory(customCoords = null) {
    const coords = customCoords || getActiveChartCoords();
    if (!coords) return;
    setWeatherLoading(true);
    setStatus("Fetching local microclimate weather history…");
    setStatusIsError(false);
    try {
      const data = await getWeatherHistory(coords.lat, coords.lon, 168);
      setWeatherHistory(data);
      setStatus("");
    } catch (err) {
      setStatus(`Couldn't reach the API — ${err.message}`);
      setStatusIsError(true);
    } finally {
      setWeatherLoading(false);
    }
  }

  async function handleSelectRouteIndex(newIdx) {
    setSelectedRouteIndex(newIdx);
    const coords = getActiveChartCoords(newIdx, routes);
    if (coords && timeline) {
      fetchTimeline(coords);
    }
    if (coords && weatherHistory) {
      fetchWeatherHistory(coords);
    }
  }

  async function submitRoute() {
    if (!routeStart || !routeEnd) return;
    setLoading(true);
    setStatus("Analyzing routes with 3-Agent Environmental Intelligence System (Gemini + RAG)…");
    setStatusIsError(false);
    setTimeline(null);
    setWeatherHistory(null);
    try {
      const data = await getRouteAdvisory(
        routeStart.lat,
        routeStart.lng,
        routeEnd.lat,
        routeEnd.lng,
        userPreference,
        ageGroup,
        healthNote
      );
      const routeList = data.routes || [];
      const recIdx =
        data.ai_advisory?.recommended_route_index != null &&
        data.ai_advisory.recommended_route_index >= 0 &&
        data.ai_advisory.recommended_route_index < routeList.length
          ? data.ai_advisory.recommended_route_index
          : data.recommended_index != null &&
            data.recommended_index >= 0 &&
            data.recommended_index < routeList.length
          ? data.recommended_index
          : 0;

      setRoutes(routeList);
      setAiAdvisory(data.ai_advisory || null);
      setSelectedRouteIndex(recIdx);
      setStatus("");

      if (routeList.length > 0 && routeList[recIdx]) {
        addHistoryEntry({
          type: "route",
          aqi: routeList[recIdx].average_aqi_exposure,
          locationLabel: `${routeStart.label || "Start"} to ${routeEnd.label || "End"}`,
        });
      }
    } catch (err) {
      setStatus(`Couldn't reach the API — ${err.message}`);
      setStatusIsError(true);
    } finally {
      setLoading(false);
    }
  }

  const canShowGraphs =
    (mode === "location" && locationResult) ||
    (mode === "route" && routes && routes.length > 0);

  return (
    <div className="map-page-layout">
      <div className="panel map-panel">
        <div className="mode-switch">
          <button className={`mode-btn ${mode === "location" ? "active" : ""}`} onClick={() => switchMode("location")}>
            📍 Analyze Location Health
          </button>
          <button className={`mode-btn ${mode === "route" ? "active" : ""}`} onClick={() => switchMode("route")}>
            Plan route
          </button>
        </div>

        {mode === "location" ? (
          <>
            <div className="field-label">Search, use current location, or click the map</div>
            <div className="search-with-locate">
              <LocationSearch
                id="location-health-search"
                placeholder="e.g. India Gate, Connaught Place, Delhi University…"
                value={selectedPoint?.label || ""}
                onSelect={(lat, lon, label) => handleLocationSearchSelect(lat, lon, label)}
                onInvalidate={() => {
                  setSelectedPoint(null);
                  setLocationResult(null);
                }}
                dotColor="#2E6E5E"
              />
              <button className="locate-btn" onClick={() => locateCurrentPosition("location")} disabled={locating} title="Use current location">
                📍
              </button>
            </div>

            <div className="field-label" style={{ marginTop: 14 }}>Selected point</div>
            <div className="point-display">
              {selectedPoint ? (
                <span>{selectedPoint.label || `${selectedPoint.lat.toFixed(4)}, ${selectedPoint.lng.toFixed(4)}`}</span>
              ) : (
                <span className="empty">Not selected yet</span>
              )}
            </div>
            <p className="hint">Analyzes environmental health, AQI severity, and microclimate telemetry at any point in Delhi NCR.</p>
            <button className="primary" disabled={!selectedPoint || loading} onClick={submitLocation}>
              {loading ? "Analyzing Environmental Health…" : "📍 Analyze Location Health"}
            </button>
          </>
        ) : (
          <>
            <div className="field-label">Start point</div>
            <div className="search-with-locate">
              <LocationSearch
                id="route-start-search"
                placeholder="Search or click map for start (e.g. Connaught Place)"
                value={routeStart?.label || ""}
                onSelect={(lat, lon, label) => handleStartSearchSelect(lat, lon, label)}
                onInvalidate={() => {
                  setRouteStart(null);
                  setRoutes(null);
                  setAiAdvisory(null);
                }}
                dotColor="#2E6E5E"
              />
              <button className="locate-btn" onClick={() => locateCurrentPosition("start")} disabled={locating} title="Use current location">
                📍
              </button>
            </div>
            <div className="point-display" style={{ marginTop: 6 }}>
              {routeStart ? (
                <span>{routeStart.label || `${routeStart.lat.toFixed(4)}, ${routeStart.lng.toFixed(4)}`}</span>
              ) : (
                <span className="empty">Not selected yet</span>
              )}
            </div>

            <div className="field-label" style={{ marginTop: 14 }}>Destination</div>
            <LocationSearch
              id="route-destination-search"
              placeholder="Search or click map for destination (e.g. India Gate)"
              value={routeEnd?.label || ""}
              onSelect={(lat, lon, label) => handleEndSearchSelect(lat, lon, label)}
              onInvalidate={() => {
                setRouteEnd(null);
                setRoutes(null);
                setAiAdvisory(null);
              }}
              dotColor="#E0533D"
            />
            <div className="point-display" style={{ marginTop: 6 }}>
              {routeEnd ? (
                <span>{routeEnd.label || `${routeEnd.lat.toFixed(4)}, ${routeEnd.lng.toFixed(4)}`}</span>
              ) : (
                <span className="empty">Not selected yet</span>
              )}
            </div>

            <div className="ai-pref-selector">
              <div className="ai-pref-label">Route Optimization Criterion</div>
              <div className="ai-pref-buttons">
                <button
                  type="button"
                  className={`ai-pref-btn ${userPreference === "cleanest" ? "active" : ""}`}
                  onClick={() => setUserPreference("cleanest")}
                >
                  🌱 Cleanest
                </button>
                <button
                  type="button"
                  className={`ai-pref-btn ${userPreference === "balanced" ? "active" : ""}`}
                  onClick={() => setUserPreference("balanced")}
                >
                  ⚖️ Balanced
                </button>
                <button
                  type="button"
                  className={`ai-pref-btn ${userPreference === "fastest" ? "active" : ""}`}
                  onClick={() => setUserPreference("fastest")}
                >
                  ⚡ Fastest
                </button>
              </div>
            </div>

            <p className="hint">Search by name, use 📍 for your current location, or click the map. Evaluates 3 distinct road corridors with AI intelligence.</p>
            <button className="primary" disabled={!routeStart || !routeEnd || loading} onClick={submitRoute}>
              {loading ? "Generating AI Advisory…" : "Generate AI Route Advisory"}
            </button>
          </>
        )}

        {status && <div className={`status-line ${statusIsError ? "error" : ""}`}>{status}</div>}

        {mode === "location" ? (
          <LocationResult data={locationResult} healthNote={healthNote} ageGroup={ageGroup} />
        ) : (
          <RouteOptionsResult
            routes={routes}
            selectedIndex={selectedRouteIndex}
            onSelectRoute={handleSelectRouteIndex}
            onStartNavigation={(routeData) => {
              setNavRouteData(routeData);
              setIsNavigating(true);
            }}
            healthNote={healthNote}
            ageGroup={ageGroup}
            aiAdvisory={aiAdvisory}
          />
        )}

        {canShowGraphs && (
          <>
            <button
              className="secondary"
              disabled={timelineLoading}
              onClick={() => fetchTimeline()}
              style={{ marginTop: 14 }}
            >
              {timelineLoading
                ? "Loading trend…"
                : mode === "route"
                ? `View 24h AQI trend (Route ${selectedRouteIndex + 1} corridor)`
                : "View 24h AQI trend (past + forecast)"}
            </button>
            <AqiTimelineChart data={timeline} />

            <button
              className="secondary"
              disabled={weatherLoading}
              onClick={() => fetchWeatherHistory()}
              style={{ marginTop: 10 }}
            >
              {weatherLoading
                ? "Loading weather…"
                : mode === "route"
                ? `View weather history (Route ${selectedRouteIndex + 1} corridor)`
                : "View weather history (hourly/daily)"}
            </button>
            <WeatherHistoryChart data={weatherHistory} />
          </>
        )}
      </div>

      <div className="map-container" style={{ position: "relative" }}>
        <MapView
          mode={mode}
          onMapClick={handleClick}
          locationResult={locationResult}
          selectedPoint={selectedPoint}
          routeStart={routeStart}
          routeEnd={routeEnd}
          routes={routes}
          selectedRouteIndex={selectedRouteIndex}
          onSelectRoute={handleSelectRouteIndex}
        />

        {isNavigating && navRouteData && (
          <CleanNavigationHud
            startLabel={routeStart?.label || "Origin"}
            destinationLabel={routeEnd?.label || "Destination"}
            routeAqi={navRouteData.average_aqi_exposure}
            distanceKm={navRouteData.route_distance_km}
            durationMins={navRouteData.route_duration_min}
            corridorLabel={navRouteData.corridor_label || `Route ${selectedRouteIndex + 1}`}
            routePoints={navRouteData.route_points || []}
            onExit={() => setIsNavigating(false)}
          />
        )}
      </div>
    </div>
  );
}
