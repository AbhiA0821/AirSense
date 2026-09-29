const API_BASE = "http://127.0.0.1:8000";

let userLat = 28.6139; // Default Delhi coordinates for fallback
let userLon = 77.2090;
let map = null;
let userMarker = null;
let destMarker = null;
let routePolylines = [];
let aqiChart = null;
let currentLiveAQI = 120;
let currentRouteData = null;
let selectedRouteIndex = 0;

// EPA AQI Color Mapping
function getAQIColor(aqi) {
    if (aqi === null || aqi === undefined || isNaN(aqi)) return "#94a3b8";
    if (aqi <= 50) return "#10b981"; // Good - Emerald
    if (aqi <= 100) return "#f59e0b"; // Moderate - Amber
    if (aqi <= 150) return "#f97316"; // Unhealthy Sensitive - Orange
    if (aqi <= 200) return "#ef4444"; // Unhealthy - Red
    if (aqi <= 300) return "#a855f7"; // Very Unhealthy - Purple
    return "#881337"; // Hazardous - Maroon
}

function formatVal(val, unit = "") {
    if (val === null || val === undefined || isNaN(val)) return "N/A";
    return `${val} ${unit}`.trim();
}

// Initialize Leaflet Map
function initMap() {
    map = L.map('map').setView([userLat, userLon], 12);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(map);

    const userIcon = L.divIcon({
        className: 'custom-div-icon',
        html: "<div style='background-color:#06b6d4;width:18px;height:18px;border-radius:50%;border:3px solid white;box-shadow:0 0 10px #06b6d4;'></div>",
        iconSize: [20, 20],
        iconAnchor: [10, 10]
    });

    userMarker = L.marker([userLat, userLon], {icon: userIcon}).addTo(map)
        .bindPopup("<b>📍 Current Selected Location</b>").openPopup();
}

// Initialize Chart.js AQI Forecast Graph
function initChart() {
    const ctx = document.getElementById('aqiChart').getContext('2d');
    
    aqiChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [
                {
                    label: 'Historical AQI Trend (Past 24h)',
                    data: [],
                    borderColor: '#3b82f6',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    fill: true,
                    tension: 0.3,
                    borderWidth: 2
                },
                {
                    label: 'AI-Predicted Future AQI (+24h Forecast)',
                    data: [],
                    borderColor: '#c084fc',
                    borderDash: [5, 5],
                    backgroundColor: 'rgba(192, 132, 252, 0.1)',
                    fill: true,
                    tension: 0.3,
                    borderWidth: 3
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    labels: { color: '#cbd5e1', font: { family: 'Inter', size: 12 } }
                }
            },
            scales: {
                x: {
                    grid: { color: 'rgba(255, 255, 255, 0.05)' },
                    ticks: { color: '#94a3b8', font: { family: 'Inter', size: 11 } }
                },
                y: {
                    grid: { color: 'rgba(255, 255, 255, 0.05)' },
                    ticks: { color: '#94a3b8', font: { family: 'Inter', size: 11 } },
                    title: { display: true, text: 'AQI Level', color: '#94a3b8' }
                }
            }
        }
    });
}

// Set default date & time
function initDateTimeInputs() {
    const now = new Date();
    document.getElementById('travelDate').value = now.toISOString().split('T')[0];
    document.getElementById('travelTime').value = now.toTimeString().slice(0, 5);
}

function setOriginToGPS() {
    document.getElementById("routeOriginInput").value = "Current Location";
}

// Search live location AQI independently
function searchLiveLocation() {
    const query = document.getElementById("liveLocationSearchInput").value.trim();
    if (!query) {
        alert("Please enter a city or location name to search.");
        return;
    }
    const statusElem = document.getElementById("navStatus");
    statusElem.innerHTML = "<span class='loading-spinner'></span> Geocoding searched location...";

    fetch(`${API_BASE}/geocode?location=${encodeURIComponent(query)}`)
        .then(res => res.json())
        .then(data => {
            if (data.status !== "success" || !data.lat || !data.lon) {
                alert(`Location Error: ${data.message || 'Location not found.'}`);
                statusElem.innerHTML = "<span class='status-dot'></span> BACKEND ONLINE | GPS ACTIVE";
                return;
            }
            loadEnvironmentForCoordinates(data.lat, data.lon, false, "", data.city_label || query);
        })
        .catch(err => {
            console.error("Geocoding error:", err);
            alert("Location search failed. Please check network connection.");
        });
}

// ==========================================
// FETCH LIVE GPS LOCATION & ENVIRONMENT
// ==========================================
function fetchLiveEnvironment() {
    const navStatus = document.getElementById("navStatus");
    navStatus.innerHTML = "<span class='loading-spinner'></span> Acquiring GPS & Environmental Data...";

    // Load default Delhi region immediately so UI never stays stuck
    loadEnvironmentForCoordinates(userLat, userLon, false, "Initial Load");

    if (!navigator.geolocation) {
        console.warn("[GPS] Geolocation API not supported by browser. Using default region.");
        loadEnvironmentForCoordinates(userLat, userLon, true, "GPS unavailable — using Delhi NCR default region");
        return;
    }

    navigator.geolocation.getCurrentPosition(
        (position) => {
            userLat = position.coords.latitude;
            userLon = position.coords.longitude;
            console.log(`[GPS] Location acquired: ${userLat}, ${userLon}`);
            loadEnvironmentForCoordinates(userLat, userLon, false);
        },
        (error) => {
            let reason = "GPS unavailable — using Delhi NCR default region";
            if (error.code === 1) reason = "Location permission denied — using Delhi NCR default region";
            else if (error.code === 2) reason = "Position unavailable — using Delhi NCR default region";
            else if (error.code === 3) reason = "GPS unavailable — using Delhi NCR default region";

            console.warn(`[GPS Error ${error.code}]: ${error.message}`);
            loadEnvironmentForCoordinates(userLat, userLon, true, reason);
        },
        { timeout: 4000, enableHighAccuracy: false, maximumAge: 60000 }
    );
}

function loadEnvironmentForCoordinates(lat, lon, isFallback = false, fallbackReason = "", customCityLabel = null) {
    if (map && userMarker) {
        map.setView([lat, lon], 12);
        userMarker.setLatLng([lat, lon]);
    }

    // Set immediate non-empty display values so hero card never freezes at '--'
    const defaultCity = customCityLabel || 'New Delhi';
    if (document.getElementById("heroAqiVal").innerText === "--") {
        document.getElementById("heroAqiVal").innerText = "90";
        document.getElementById("heroAqiCat").innerText = "Moderate";
        document.getElementById("heroLocationText").innerText = `📍 Location: ${defaultCity}${isFallback ? ' (Default Region)' : ''} (${lat.toFixed(4)}, ${lon.toFixed(4)})`;
        document.getElementById("aiLocationText").innerText = `📍 Location Forecast: ${defaultCity}`;
        document.getElementById("aiPredictedVal").innerText = "92.5";
        document.getElementById("aiModelTag").innerText = "Model: PyTorch LSTM Neural Network";
    }

    fetch(`${API_BASE}/environment/current?latitude=${lat}&longitude=${lon}`)
        .then(res => {
            if (!res.ok) throw new Error(`HTTP Server Error ${res.status}`);
            return res.json();
        })
        .then(data => {
            const statusElem = document.getElementById("navStatus");
            if (isFallback) {
                const reasonTag = fallbackReason ? `<span style="font-size: 11px; opacity: 0.85; margin-left: 6px; font-weight: normal;">(${fallbackReason})</span>` : '';
                statusElem.innerHTML = `<span class="status-dot" style="background-color:#10b981;box-shadow:0 0 8px #10b981;"></span> REGION DEFAULT (Delhi NCR) | LIVE FEEDS ONLINE ${reasonTag}`;
            } else {
                statusElem.innerHTML = `<span class="status-dot"></span> BACKEND ONLINE | GPS ACTIVE (${lat.toFixed(4)}, ${lon.toFixed(4)})`;
            }

            const liveAqi = data.live_aqi || {};
            const weather = data.live_weather || {};
            const geo = data.location || {};
            const ai = data.ai_prediction || {};

            currentLiveAQI = liveAqi.aqi || 120;
            const aqiColor = getAQIColor(currentLiveAQI);
            const displayCity = customCityLabel || geo.city || geo.location || 'Detected Location';

            // 1. Update Live AQI Hero Card
            document.getElementById("heroAqiVal").innerText = formatVal(currentLiveAQI);
            document.getElementById("heroAqiCircle").style.backgroundColor = aqiColor;
            document.getElementById("heroAqiCat").innerText = liveAqi.category || "Moderate";
            document.getElementById("heroAqiSub").innerText = `Primary Pollutant: PM2.5 (${formatVal(liveAqi.pm25, "µg/m³")})`;
            document.getElementById("heroLocationText").innerText = `📍 Location: ${displayCity}${isFallback ? ' (Default Region)' : ''} (${lat.toFixed(4)}, ${lon.toFixed(4)})`;
            document.getElementById("lastUpdatedTime").innerText = data.timestamp || new Date().toLocaleTimeString();

            // 2. Update AI Forecast Card Location & Metrics
            document.getElementById("aiLocationText").innerText = `📍 Location Forecast: ${displayCity}`;
            document.getElementById("aiPredictedVal").innerText = formatVal(ai.predicted_aqi);
            document.getElementById("aiCategory").innerText = ai.category || "Inference Complete";
            document.getElementById("aiModelTag").innerText = `Model: ${ai.model_used || 'PyTorch LSTM Neural Network'}`;
            const advElem = document.getElementById("aiAdvisoryText");
            if (advElem) advElem.remove();

            // Render 24-hour numerical forecast breakdown strip
            const breakdownContainer = document.getElementById("aiForecastBreakdown");
            if (breakdownContainer) {
                const hourlyList = ai.hourly_forecast || [];
                if (hourlyList.length > 0) {
                    breakdownContainer.innerHTML = hourlyList.map((val, idx) => 
                        `<span style="background: rgba(255,255,255,0.06); padding: 3px 8px; border-radius: 4px; font-size: 11px; white-space: nowrap; border: 1px solid rgba(255,255,255,0.1);">+${idx+1}h: <b style="color:#c084fc;">${val}</b></span>`
                    ).join('');
                } else {
                    breakdownContainer.innerHTML = `<span style="font-size: 11px; color: var(--text-secondary);">Forecast sequence unavailable</span>`;
                }
            }

            // 3. Update Environmental Metrics Grid
            document.getElementById("mTemp").innerText = formatVal(weather.temperature, "°C");
            document.getElementById("mHum").innerText = formatVal(weather.humidity, "%");
            document.getElementById("mWind").innerText = formatVal(weather.wind_speed, "km/h");
            document.getElementById("mPress").innerText = formatVal(weather.pressure, "hPa");
            
            document.getElementById("mPm25").innerText = formatVal(liveAqi.pm25, "µg/m³");
            document.getElementById("mPm10").innerText = formatVal(liveAqi.pm10, "µg/m³");
            document.getElementById("mNo2").innerText = formatVal(liveAqi.no2, "ppb");
            document.getElementById("mSo2").innerText = formatVal(liveAqi.so2, "ppb");
            document.getElementById("mCo").innerText = formatVal(liveAqi.co, "ppm");
            document.getElementById("mO3").innerText = formatVal(liveAqi.o3, "ppb");

            // 4. Update Historical vs Forecast Chart
            updateAQIChart(currentLiveAQI, ai.hourly_forecast || []);
        })
        .catch(err => {
            console.error("Error fetching environment data:", err);
            document.getElementById("navStatus").innerHTML = `<span class="status-dot" style="background-color:#ef4444;box-shadow:0 0 8px #ef4444;"></span> ⚠️ Backend Server Offline (${API_BASE})`;
            document.getElementById("heroAqiCat").innerText = "Backend Offline";
            document.getElementById("heroLocationText").innerText = "Unable to connect to backend service";
        });
}

// Update Chart
function updateAQIChart(currentAQI, hourlyForecast) {
    fetch(`${API_BASE}/aqi/historical?current_aqi=${currentAQI}`)
        .then(res => res.json())
        .then(histData => {
            const historicalList = histData.historical_trend || [];
            const histLabels = historicalList.map(item => item.hour);
            const histValues = historicalList.map(item => item.aqi);

            const predLabels = Array.from({length: hourlyForecast.length}, (_, i) => `+${i+1}h`);
            const predValues = hourlyForecast;
            const fullLabels = [...histLabels, ...predLabels];
            
            const padLength = Math.max(0, histValues.length - 1);
            const lastHistVal = histValues.length > 0 ? histValues[histValues.length - 1] : currentAQI;
            
            const histDataset = [...histValues, ...Array(hourlyForecast.length).fill(null)];
            const predDataset = [...Array(padLength).fill(null), lastHistVal, ...predValues];

            if (aqiChart) {
                aqiChart.data.labels = fullLabels;
                aqiChart.data.datasets[0].data = histDataset;
                aqiChart.data.datasets[1].data = predDataset;
                aqiChart.update();
            }
        })
        .catch(err => console.error("Error fetching historical AQI trend:", err));
}

// ==========================================
// OSRM SMART ROUTE & EXPOSURE ANALYSIS
// ==========================================
function analyzeSmartRoute() {
    const originInput = document.getElementById("routeOriginInput").value.trim();
    const destInput = document.getElementById("routeDestInput").value.trim();

    if (!originInput) {
        alert("Please enter an origin location.");
        return;
    }
    if (!destInput) {
        alert("Please enter a destination location.");
        return;
    }

    const btn = document.querySelector(".btn-analyze");
    btn.disabled = true;
    btn.innerHTML = "<span class='loading-spinner'></span> Calculating Road Routes & Pollution Exposure...";

    const reqBody = {
        origin: originInput,
        destination: destInput,
        current_aqi: currentLiveAQI
    };

    if (originInput.toLowerCase().includes("current") && userLat && userLon) {
        reqBody.origin_lat = userLat;
        reqBody.origin_lon = userLon;
    }

    fetch(`${API_BASE}/route/analyze`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(reqBody)
    })
    .then(res => {
        if (!res.ok) throw new Error(`HTTP Server Error ${res.status}`);
        return res.json();
    })
    .then(data => {
        btn.disabled = false;
        btn.innerHTML = "🚀 ANALYZE JOURNEY & EXPOSURE";

        if (data.status === "error") {
            alert(`Location / Route Error: ${data.message}`);
            document.getElementById("resTraffic").innerText = `Error: ${data.message}`;
            return;
        }

        currentRouteData = data;
        renderRouteOptions(data);
    })
    .catch(err => {
        console.error("Routing error:", err);
        btn.disabled = false;
        btn.innerHTML = "🚀 ANALYZE JOURNEY & EXPOSURE";
        document.getElementById("resTraffic").innerText = `Connection Error: Failed to contact backend at ${API_BASE}`;
        alert(`Failed to connect to backend routing service (${API_BASE}). Make sure backend main.py is running on port 8000.`);
    });
}

function renderRouteOptions(data) {
    const container = document.getElementById("routeOptionsContainer");
    const routes = data.routes || [];
    if (routes.length === 0) {
        container.innerHTML = "<p style='color: var(--text-secondary); font-size: 13px;'>No valid routes found for the specified origin and destination.</p>";
        return;
    }

    let recIdx = routes.findIndex(r => r.is_recommended);
    if (recIdx === -1) recIdx = 0;
    selectedRouteIndex = recIdx;

    // Draw all polylines on map
    drawAllRoutePolylines(routes, selectedRouteIndex, data.origin_coords, data.destination_coords);

    let html = `<div style="font-size: 12px; font-weight: 700; color: var(--text-secondary); text-transform: uppercase; margin-bottom: 6px; display: flex; justify-content: space-between; align-items: center;">
        <span>Available Route Alternatives (${routes.length})</span>
        <span style="font-size: 11px; font-weight: 400; color: var(--accent-cyan);">${data.routing_provider || 'OSRM Engine'}</span>
    </div>`;

    routes.forEach((r, idx) => {
        const isRec = r.is_recommended;
        const isActive = idx === selectedRouteIndex;
        const exp = r.exposure_analysis || {};
        const avgAqi = exp.avg_route_aqi || r.average_aqi || "--";
        const aiPredAqi = r.ai_predicted_aqi || "--";
        const trafficStat = r.traffic_status || "Live traffic unavailable (OSRM)";
        const pts = r.geometry_point_count || (r.polyline ? r.polyline.length : 0);
        
        html += `
        <div class="route-option-card ${isActive ? 'active-route-card' : ''}" onclick="selectRouteOption(${idx})" id="routeCard_${idx}">
            ${isRec ? `<div class="route-badge-rec">✓ RECOMMENDED - LOWEST EXPOSURE</div>` : ''}
            <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                <div>
                    <div style="font-weight: 700; font-size: 15px; color: #ffffff;">Route ${idx + 1} — ${r.name || 'Driving Route'}</div>
                    <div style="font-size: 12px; color: var(--text-secondary); margin-top: 3px;">Distance: <b style="color: #f1f5f9;">${r.distance_km} km</b> | Est. Time: <b style="color: #f1f5f9;">${r.duration_minutes} mins</b> | Geometry: <b style="color: #cbd5e1;">${pts} pts</b></div>
                </div>
                <div style="text-align: right;">
                    <div style="font-size: 10px; color: var(--text-secondary); text-transform: uppercase;">Est. Route AQI</div>
                    <div style="font-family: var(--font-heading); font-size: 20px; font-weight: 800; color: ${getAQIColor(avgAqi)};">${avgAqi}</div>
                </div>
            </div>

            <!-- ROUTE SPECIFIC PARAMETERS GRID -->
            <div style="margin-top: 10px; padding: 8px; background: rgba(0,0,0,0.2); border-radius: 8px; display: grid; grid-template-columns: 1fr 1fr; gap: 6px; font-size: 11px;">
                <div><span style="color: var(--text-secondary);">AQI Risk:</span> <b style="color: #ffffff;">${exp.exposure_level || 'Moderate'}</b></div>
                <div><span style="color: var(--text-secondary);">AI Predicted AQI:</span> <b style="color: #c084fc;">${aiPredAqi}</b></div>
                <div><span style="color: var(--text-secondary);">Traffic:</span> <b style="color: #94a3b8;">${trafficStat}</b></div>
                <div><span style="color: var(--text-secondary);">Inhaled Dose:</span> <b style="color: #38bdf8;">${r.estimated_inhaled_dose || 'N/A'}</b></div>
            </div>

            <div style="margin-top: 8px; display: flex; justify-content: space-between; font-size: 12px; align-items: center;">
                <span style="color: var(--text-secondary); font-size: 11px;">Pollution Exposure: <b style="color: #ffffff;">${exp.exposure_level || 'Moderate'}</b></span>
                <span style="color: var(--accent-cyan); font-weight: 600;">${isActive ? '● Selected Route' : 'Click to select'}</span>
            </div>
            ${isRec && exp.recommendation_reason ? `<div style="margin-top: 8px; font-size: 11px; color: var(--accent-emerald); background: rgba(16,185,129,0.08); padding: 6px 10px; border-radius: 6px; border: 1px solid rgba(16,185,129,0.2);">${exp.recommendation_reason}</div>` : ''}
        </div>`;
    });

    container.innerHTML = html;
    updateSelectedRouteSummary(routes[selectedRouteIndex], data.traffic_status, data.routing_provider);
}

function drawAllRoutePolylines(routes, activeIdx, originCoords, destCoords) {
    if (!map) return;

    routePolylines.forEach(p => map.removeLayer(p));
    routePolylines = [];
    if (userMarker) map.removeLayer(userMarker);
    if (destMarker) map.removeLayer(destMarker);

    const boundsGroup = [];

    routes.forEach((r, idx) => {
        const polyCoords = r.polyline || [];
        if (polyCoords.length === 0) return;

        const isActive = idx === activeIdx;
        const polyline = L.polyline(polyCoords, {
            color: isActive ? '#06b6d4' : '#8b5cf6',
            weight: isActive ? 6 : 4,
            opacity: isActive ? 0.95 : 0.45,
            dashArray: isActive ? null : '6, 6'
        }).addTo(map);

        if (isActive) polyline.bringToFront();

        routePolylines.push(polyline);
        boundsGroup.push(polyline);
    });

    if (originCoords && originCoords.lat && originCoords.lon) {
        const userIcon = L.divIcon({
            className: 'custom-div-icon',
            html: "<div style='background-color:#06b6d4;width:20px;height:20px;border-radius:50%;border:3px solid white;box-shadow:0 0 10px #06b6d4;'></div>",
            iconSize: [22, 22],
            iconAnchor: [11, 11]
        });
        userMarker = L.marker([originCoords.lat, originCoords.lon], {icon: userIcon}).addTo(map)
            .bindPopup(`<b>📍 Origin: ${currentRouteData.origin}</b>`).openPopup();
        boundsGroup.push(userMarker);
    }

    if (destCoords && destCoords.lat && destCoords.lon) {
        const destIcon = L.divIcon({
            className: 'custom-div-icon',
            html: "<div style='background-color:#8b5cf6;width:20px;height:20px;border-radius:50%;border:3px solid white;box-shadow:0 0 10px #8b5cf6;'></div>",
            iconSize: [22, 22],
            iconAnchor: [11, 11]
        });
        destMarker = L.marker([destCoords.lat, destCoords.lon], {icon: destIcon}).addTo(map)
            .bindPopup(`<b>🎯 Destination: ${currentRouteData.destination}</b>`);
        boundsGroup.push(destMarker);
    }

    if (boundsGroup.length > 0) {
        const group = L.featureGroup(boundsGroup);
        map.fitBounds(group.getBounds(), { padding: [40, 40] });
    }
}

function selectRouteOption(idx) {
    if (!currentRouteData || !currentRouteData.routes || !currentRouteData.routes[idx]) return;

    selectedRouteIndex = idx;
    const routes = currentRouteData.routes;

    routePolylines.forEach((poly, i) => {
        const isActive = i === idx;
        poly.setStyle({
            color: isActive ? '#06b6d4' : '#8b5cf6',
            weight: isActive ? 6 : 4,
            opacity: isActive ? 0.95 : 0.45,
            dashArray: isActive ? null : '6, 6'
        });
        if (isActive) poly.bringToFront();
    });

    routes.forEach((_, i) => {
        const card = document.getElementById(`routeCard_${i}`);
        if (card) {
            if (i === idx) card.classList.add("active-route-card");
            else card.classList.remove("active-route-card");
        }
    });

    updateSelectedRouteSummary(routes[idx], currentRouteData.traffic_status, currentRouteData.routing_provider);
}

function setOriginToGPS() {
    const origSelect = document.getElementById("routeOriginSelect");
    if (origSelect) origSelect.value = "GPS";
    const origInput = document.getElementById("routeOriginInput");
    if (origInput) origInput.value = "Current Location";
}

function syncOriginSelection(val) {
    const input = document.getElementById("routeOriginInput");
    if (input) input.value = val === "GPS" ? "Current Location" : val;
}

function syncDestSelection(val) {
    const input = document.getElementById("routeDestInput");
    if (input) input.value = val;
}

function updateSelectedRouteSummary(r, trafficStatus, provider) {
    const recCard = document.getElementById("aiRecommendationCard");
    const recBody = document.getElementById("recBodyContent");
    if (!recCard || !recBody || !currentRouteData || !currentRouteData.routes) return;

    const recBadge = document.getElementById("recModelBadge");
    if (recBadge) recBadge.innerText = "Model: PyTorch LSTM Neural Network";

    const routes = currentRouteData.routes;
    const recIdx = routes.findIndex(route => route.is_recommended);
    const recRoute = recIdx !== -1 ? routes[recIdx] : routes[0];
    const recExp = recRoute.exposure_analysis || {};

    let compHtml = `<div style="margin-top: 10px; padding: 10px; background: rgba(0,0,0,0.25); border-radius: 8px;">
        <div style="font-weight: 700; color: #ffffff; font-size: 13px; margin-bottom: 6px;">✓ Recommended Route: ${recRoute.name} (${recRoute.distance_km} km | ${recRoute.duration_minutes} mins)</div>
        <div style="font-size: 12px; color: var(--accent-cyan); font-weight: 600; margin-bottom: 8px;">
            Estimated Route AQI: ${recRoute.average_aqi} | AI Predicted AQI: ${recRoute.ai_predicted_aqi || 'N/A'} | Exposure: ${recExp.exposure_level || 'Moderate'}
        </div>
        <div style="font-size: 12px; color: #cbd5e1; margin-bottom: 10px;">
            <b>Reasoning:</b> ${recExp.recommendation_reason || `Choose ${recRoute.name} because it has the lowest estimated pollution exposure among the available routes.`}
        </div>
        <div style="font-size: 12px; font-weight: 700; color: #94a3b8; text-transform: uppercase; margin-bottom: 4px;">Route Comparison:</div>
        <div style="display: flex; flex-direction: column; gap: 4px; font-size: 12px;">`;

    routes.forEach((rt, idx) => {
        const isRec = rt.is_recommended;
        compHtml += `<div style="display: flex; justify-content: space-between; padding: 4px 8px; background: ${isRec ? 'rgba(16,185,129,0.1)' : 'rgba(255,255,255,0.04)'}; border-radius: 4px; border: 1px solid ${isRec ? 'rgba(16,185,129,0.3)' : 'transparent'};">
            <span><b>Route ${idx + 1} (${rt.name}):</b> ${rt.distance_km} km | ${rt.duration_minutes} mins</span>
            <span>Est. AQI: <b>${rt.average_aqi}</b> | AI Pred: <b style="color:#c084fc;">${rt.ai_predicted_aqi || 'N/A'}</b> | ${rt.exposure_level || 'Moderate'}</span>
        </div>`;
    });

    compHtml += `</div>
        <div style="margin-top: 10px; font-size: 11px; color: var(--text-secondary); border-top: 1px solid rgba(255,255,255,0.08); padding-top: 6px;">
            ⚠️ <i>Traffic Note: Traffic data was unavailable from OSRM and was not used for the pollution recommendation.</i>
        </div>
    </div>`;

    recBody.innerHTML = compHtml;
}

// Initialize on DOM Ready
window.addEventListener('DOMContentLoaded', () => {
    initMap();
    initChart();
    initDateTimeInputs();
    fetchLiveEnvironment();
});
