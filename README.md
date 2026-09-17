# AI-Powered Environmental Intelligence System
## Air Quality Prediction & Smart Mobility Recommendations

[![Python Version](https://img.shields.io/badge/python-3.10%20%7C%203.11-blue.svg)](https://www.python.org/)
[![Framework](https://img.shields.io/badge/FastAPI-0.110+-009688.svg)](https://fastapi.tiangolo.com/)
[![Deep Learning](https://img.shields.io/badge/PyTorch-2.2+-EE4C2C.svg)](https://pytorch.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Milestone%202-Verified%20100%25-brightgreen.svg)]()

---

## 1. Project Title
**AI-Powered Environmental Intelligence System for Air Quality Prediction and Smart Mobility Recommendations**

---

## 2. Project Objective
To provide urban commuters, municipal authorities, and health-conscious citizens with a real-time, deep-learning-powered air quality forecasting platform and a pollution-aware mobility recommendation engine that quantifies exposure and optimizes travel corridors across the National Capital Territory (NCT) of Delhi.

---

## 3. Project Overview
Urban centers such as Delhi face acute seasonal and episodic air pollution spikes driven by meteorological inversions, industrial emissions, vehicular traffic, and biomass burning. Conventional routing services optimize exclusively for physical distance or travel time, frequently funneling commuters through severe pollution hotspots. 

This system integrates:
1. **Live Multi-Source Feeds:** Real-time AQI from the World Air Quality Index (WAQI) and meteorological feeds from Open-Meteo.
2. **PyTorch LSTM Time-Series Forecasting:** A production 2-layer Recurrent Neural Network with a 24-hour historical lookback and 18 environmental/temporal features, forecasting local AQI trends up to 24 hours in advance.
3. **Inverse Distance Weighting (IDW) Spatial Interpolation:** Continuous geospatial surface estimation using observations from 27 CPCB/DPCC monitoring stations across Delhi.
4. **Smart Mobility Pollution Analysis:** Real road routing via the Open Source Routing Machine (OSRM), evaluating route geometry alternatives for pollution exposure and estimated inhaled PM2.5 dose.
5. **Interactive Web Command Center:** A Flask-served interactive dashboard featuring Leaflet.js maps, Chart.js forecasting curves, and multi-route comparison cards.

---

## 4. Main Features
- **Real-Time Environmental Telemetry:** Ingests live PM2.5, PM10, NO2, SO2, CO, O3, temperature, humidity, wind speed, and surface pressure.
- **Production Deep Neural Forecasting:** Active 2-layer PyTorch LSTM model predicting 1-hour and 24-hour forward AQI horizons.
- **Preserved MLP Baseline:** Preserves Scikit-Learn MLP baseline model for architectural benchmarking.
- **Geographic Inverse Distance Weighting (IDW):** Mathematically rigorous spatial interpolation ($p=2.0$) over 27 Delhi ground monitoring stations.
- **Multi-Route Geometry & Exposure Analysis:** Computes spatial pollution profiles and inhaled dose ($\mu\text{g } PM_{2.5}$) across real road alternatives retrieved from OSRM.
- **Objective Route Recommendation:** Suggests the lowest-exposure travel corridor based on calculated exposure rather than arbitrary heuristics.
- **Transparent Traffic Documentation:** Clearly specifies when live traffic data is unavailable from OSRM rather than fabricating congestion figures.
- **Forward & Reverse Geocoding:** OpenStreetMap Nominatim integration for coordinate and location search.

---

## 5. System Architecture

```text
                                  +---------------------------------------+
                                  |         User / Commuter Input         |
                                  |      (GPS Coordinates / Address)      |
                                  +-------------------+-------------------+
                                                      |
                                                      v
                                  +---------------------------------------+
                                  |        FastAPI Backend Service        |
                                  |         (http://127.0.0.1:8000)       |
                                  +---------+-------------------+---------+
                                            |                   |
                     +----------------------+                   +---------------------+
                     |                                                                |
                     v                                                                v
   +-----------------------------------+                            +-----------------------------------+
   |      Live Environmental Feeds     |                            |       OSRM Road Routing Engine    |
   | - WAQI API (Live AQI & PM2.5)     |                            | - Multi-route alternative polylines
   | - Open-Meteo (Weather & Wind)     |                            | - Driving distances & durations   |
   +-----------------+-----------------+                            +-----------------+-----------------+
                     |                                                                |
                     v                                                                v
   +-----------------------------------+                            +-----------------------------------+
   |   PyTorch LSTM Forecasting Model  |                            |   IDW Spatial Pollution Analysis  |
   | - 24-hour lookback sequence       |                            | - 27 Delhi CPCB/DPCC stations     |
   | - 18 environmental features       |                            | - Route polyline sampling         |
   | - 24-hour dynamic forward curve   |                            | - Inhaled PM2.5 dose calculation  |
   +-----------------+-----------------+                            +-----------------+-----------------+
                     |                                                                |
                     +----------------------+                   +---------------------+
                                            |                   |
                                            v                   v
                                  +---------------------------------------+
                                  |    Synthesized Route Recommendation   |
                                  |  (Lowest Exposure / Minimal Inhaled)  |
                                  +-------------------+-------------------+
                                                      |
                                                      v
                                  +---------------------------------------+
                                  |        Flask Web Demonstration        |
                                  |       (Leaflet Maps & Chart.js)       |
                                  +---------------------------------------+
```

---

## 6. Technology Stack
- **Deep Learning & Inference:** PyTorch (v2.2+), NumPy, Pandas, Scikit-Learn, Joblib
- **Backend Framework:** FastAPI, Uvicorn, Pydantic, Python-Dotenv
- **Geospatial & Routing:** OSRM Driving API, OpenStreetMap Nominatim, Haversine IDW
- **Demonstration Frontend:** Flask, Vanilla HTML5/CSS3, JavaScript (ES6+), Leaflet.js, Chart.js

---

## 7. Dataset
- **Source:** Central Pollution Control Board (CPCB), DPCC, and IMD.
- **Coverage:** National Capital Territory (NCT) of Delhi across 27 permanent ground monitoring stations.
- **Records:** 583,340 hourly observations.
- **Features:** 18 total features (pollutants, weather variables, temporal encodings, and rolling indicators).
- **Partition:** Chronological 70% train (204,157 sequences), 15% validation (43,739 sequences), 15% test (43,739 sequences).
- **Documentation:** Full dataset details are documented in [`dataset/README.md`](dataset/README.md).

---

## 8. PyTorch LSTM Model
- **Active Model Artifact:** `backend/models/aqi_lstm_model.pth`
- **Scaler Artifact:** `backend/models/scaler.pkl` (MinMaxScaler)
- **Metadata:** `backend/models/model_metadata.json`
- **Preserved Baseline:** `backend/models/aqi_model.joblib` (Scikit-Learn MLP)
- **Architecture:**
  ```text
  LSTM(input_dim=18, hidden_dim=64, num_layers=2, dropout=0.2, batch_first=True)
  Linear(in_features=64, out_features=32)
  ReLU()
  Linear(in_features=32, out_features=1)
  ```
- **Input Tensor Shape:** `[batch_size, 24, 18]`
- **Evaluation Performance (Test Set):**
  - **MAE:** 34.42 AQI
  - **RMSE:** 44.69 AQI
  - **MSE:** 1997.54
  - **$R^2$ Score:** 0.7128

---

## 9. IDW Spatial Interpolation
To resolve continuous spatial air quality across unmonitored coordinates in Delhi:
$$\hat{Z}(x) = \frac{\sum_{i=1}^k w_i Z_i}{\sum_{i=1}^k w_i}, \quad w_i = \frac{1}{d(x, x_i)^p}$$
- **Power Parameter ($p$):** 2.0 (standard inverse square distance).
- **Stations:** Real coordinates from 27 Delhi DPCC/CPCB/IMD stations.
- **Proximity Snap:** Stations within 50 meters snap directly to ground sensor observation.
- **Boundary Handling:** Robust error validation on invalid or out-of-bounds geographic inputs.

---

## 10. Route Pollution Analysis & Inhaled Dose
For each candidate driving route returned by OSRM:
1. Route polyline geometry is sampled at regular intervals.
2. Each coordinate is evaluated via IDW against the monitoring station network.
3. Inhaled PM2.5 dose is estimated using standard physiological ventilation metrics:
   $$\text{Inhaled Dose } (\mu\text{g}) = \text{Route PM}_{2.5} \left(\frac{\mu\text{g}}{\text{m}^3}\right) \times \text{Duration (min)} \times \text{Ventilation Rate } \left(0.012\,\frac{\text{m}^3}{\text{min}}\right)$$
4. Candidate routes are ranked objectively by lowest exposure and estimated dose.

---

## 11. FastAPI Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/` | `GET` | System health check and model declaration |
| `/environment/current` | `GET` | Combined live AQI, weather, and PyTorch LSTM AI forecast |
| `/aqi/historical` | `GET` | 24-hour historical AQI trend |
| `/prediction/aqi` | `POST` | Dynamic PyTorch LSTM inference and 24-hour hourly forecast |
| `/route/analyze` | `POST` | OSRM road geometry, IDW route AQI, inhaled dose, and recommendations |
| `/spatial/interpolate` | `GET` | Standalone IDW coordinate interpolation endpoint |
| `/geocode` | `GET` | Forward geocoding via OpenStreetMap |
| `/reverse-geocode` | `GET` | Reverse geocoding for latitude/longitude |
| `/aqi/{city}` | `GET` | Preserved city-based AQI lookup |
| `/weather` | `GET` | Preserved Open-Meteo weather endpoint |

---

## 12. Flask Dashboard
The demonstration web application provides a visual command center:
- Live AQI severity gauge with EPA color coding
- Real-time meteorological metric tiles
- 24-hour historical vs AI-predicted AQI curves
- Interactive Leaflet.js map with route polyline overlays
- Comparative route alternative cards with exposure ratings and inhaled dose estimates

---

## 13. Installation & Setup

### Clone Repository
```bash
git clone https://github.com/your-username/AI_Environmental_Intelligence.git
cd AI_Environmental_Intelligence
```

### Install Dependencies
```bash
pip install -r backend/requirements.txt
pip install flask
```

### Configure Environment
Copy `.env.example` to `.env`:
```bash
cp backend/.env.example backend/.env
```
Add your free WAQI API key from [aqicn.org](https://aqicn.org/data-platform/token/).

---

## 14. How to Run

### Start FastAPI Backend
```bash
cd backend
python -m uvicorn main:app --host 127.0.0.1 --port 8000
```
- API Root: `http://127.0.0.1:8000`
- Interactive Swagger Docs: `http://127.0.0.1:8000/docs`

### Start Flask Frontend
In a new terminal window:
```bash
cd frontend
python app.py
```
- Web Dashboard: `http://127.0.0.1:8080`

---

## 15. Verification Suite
Execute the single end-to-end verification script:
```bash
python backend/verify_milestone2_final.py
```
Validates all 30 automated criteria across backend startup, model parity, IDW mathematical correctness, route analysis, frontend integration, and zero regressions.

---

## 16. Project Structure
```text
AI_Environmental_Intelligence/
│
├── backend/
│   ├── models/
│   │   ├── aqi_lstm_model.pth          # Active production PyTorch LSTM weights
│   │   ├── aqi_model.joblib            # Preserved Scikit-Learn MLP baseline
│   │   ├── delhi_stations.json         # 27 Delhi monitoring station coordinates
│   │   ├── model_metadata.json         # Training metrics and architecture metadata
│   │   └── scaler.pkl                  # Fitted MinMaxScaler
│   │
│   ├── main.py                         # FastAPI application & route declarations
│   ├── prediction_service.py           # PyTorch LSTM inference engine
│   ├── routing_service.py              # OSRM routing & route exposure engine
│   ├── spatial_interpolation.py        # IDW spatial interpolation engine
│   ├── health_advisory.py              # Preserved demographic advisory definitions
│   ├── notification_service.py         # Notification interface definition
│   ├── train_model.py                  # PyTorch LSTM model training pipeline
│   ├── verify_milestone2_final.py      # Complete 30-point verification suite
│   ├── requirements.txt                # Python backend dependencies
│   ├── .env.example                    # Environment variable template
│   └── .env                            # Local configuration (gitignored)
│
├── frontend/
│   ├── static/
│   │   ├── css/style.css               # Dashboard stylesheet
│   │   └── js/app.js                   # Map, chart, and API interaction logic
│   ├── templates/
│   │   └── index.html                  # Flask Jinja2 dashboard template
│   ├── app.py                          # Flask web server
│   └── index.html                      # Standalone demonstration dashboard
│
├── dataset/
│   └── README.md                       # Dataset specifications & source documentation
│
├── notebooks/
│   └── 01_eda_and_feature_analysis.ipynb # Milestone 1 exploratory data analysis
│
├── MILESTONE1_REPORT.md                # Milestone 1 completion documentation
├── MILESTONE2_REPORT.md                # Milestone 2 completion documentation
├── README.md                           # Master project documentation
├── LICENSE                             # MIT License
└── .gitignore                          # Git exclusions file
```

---

## 17. Milestone Summary

### Milestone 1: Data Ingestion & Exploratory Analysis
- Integrated historical Delhi AQI records across 27 CPCB monitoring stations.
- Implemented live WAQI AQI feed, Open-Meteo weather integration, and OpenStreetMap geocoding.
- Generated exploratory data analysis visual distributions, correlation heatmaps, and diurnal trends.

### Milestone 2: Deep Learning Model & Smart Routing
- Built and trained production 2-layer PyTorch LSTM with 24-hour historical lookback over 18 features.
- Implemented genuine Inverse Distance Weighting (IDW) spatial interpolation across 27 Delhi ground stations.
- Integrated OSRM road routing engine with multi-alternative geometry extraction.
- Developed spatial route pollution scoring and inhaled PM2.5 dose calculation.
- Connected FastAPI backend with Flask demonstration dashboard and Leaflet.js mapping.

---

## 18. Known Limitations
1. **OSRM Live Traffic:** Public OSRM routing instances do not supply live vehicular congestion feeds. Travel times reflect speed limit physics; route recommendations are driven purely by calculated pollution exposure.
2. **Station Spatial Density:** IDW accuracy is constrained by the 27 physical ground sensor locations in Delhi-NCR. Peripheral rural regions exhibit higher interpolation uncertainty.
3. **Sensor Maintenance:** WAQI station observations occasionally report sensor maintenance gaps, for which fallback baseline imputations are maintained.

---

## 19. Future Work
- **Flutter Android Application:** Native mobile client connecting directly to the FastAPI backend with on-device GPS tracking and push notifications.
- **Traffic Provider Integration:** Migration to live congestion-aware routing APIs (e.g. TomTom, Google Maps) to synthesize travel delay with pollution exposure.
- **Graph Neural Networks (GNN):** Spatio-temporal graph modeling to capture wind advection and cross-station pollutant dispersion dynamics.
