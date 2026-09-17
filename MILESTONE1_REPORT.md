# MILESTONE 1 COMPLETION REPORT
## AI-Powered Environmental Intelligence System for Air Quality Prediction and Smart Mobility Recommendations
**Program:** Infosys Springboard Internship  
**Milestone:** 1 – Historical Data Analysis, Exploratory Data Analysis (EDA), Real-Time Monitoring & Web Application Prototype  
**Date:** September 2026  

---

## 1. Executive Summary & Objectives

Milestone 1 establishes the empirical data foundation and real-time environmental monitoring capabilities for the **AI-Powered Environmental Intelligence System**. 

The main objectives achieved in this milestone include:
1. **Dataset Review & Exploratory Analysis**: Comprehensive evaluation of historical air quality and weather data from Delhi across 27 monitoring stations (771,263 hourly records).
2. **Exploratory Feature Analysis**: Detailed assessment of pollutant correlations, temporal trends (diurnal and seasonal), meteorological relationships, and exploratory feature importance rankings.
3. **Real-Time Environmental Data Subsystem**: Integration of free APIs (WAQI API for live air quality and Open-Meteo API for real-time weather metrics) combined with OpenStreetMap Nominatim reverse-geocoding.
4. **Interactive Web Application**: A responsive dashboard supporting user location auto-detection, reverse-geocoding, coordinate-based native AQI lookup, and city-based search.

---

## 2. Milestone 1 Scope & Implementation Summary

| Component | Target Objective | Implementation Details | Status |
| :--- | :--- | :--- | :--- |
| **Dataset Infrastructure** | Clean historical data | Preserved original `merged_delhi_air_quality_weather.csv` (136.5 MB, 771,263 rows) | **Completed** |
| **EDA Pipeline** | Visual & statistical analysis | Executed `src/eda_analysis.py`; generated 6 visual plots in `data/processed/eda_plots/` | **Completed** |
| **Location & Geocoding** | Identify user position | Integrated OpenStreetMap Nominatim reverse geocoding (`/reverse-geocode`) | **Completed** |
| **Real-Time AQI Feed** | Fetch live air quality | WAQI API integration with native coordinate lookup (`/aqi/geo`) and city fallback (`/aqi/{city}`) | **Completed** |
| **Real-Time Weather Feed** | Fetch live weather | Open-Meteo API integration (`/weather`) for temperature, humidity, wind speed, pressure, & conditions | **Completed** |
| **Web Application Dashboard**| Interactive UI | Clean HTML/JS frontend (`frontend/index.html`) with EPA AQI color-coded badges and metric grids | **Completed** |

---

## 3. Exploratory Data Analysis (EDA) Findings

### A. Important Dataset Findings
* **Dataset Scale**: 771,263 total hourly records across 29 features from 27 air quality monitoring stations in Delhi.
* **Valid AQI Target Records**: 583,340 valid rows (187,923 null target rows safely filtered for target analysis).
* **Missing Value Overview**:
  * `Total Precipitation`: 100% missing (dropped during cleaning).
  * `Xylene`: 88.0% missing; `NH3`: 46.1% missing; `Toluene`: 40.9% missing; `SO2`: 39.4% missing; `Benzene`: 38.2% missing.
  * Core target pollutants ($PM_{2.5}, PM_{10}, NO_2, CO, O_3$) exhibit good coverage (74% to 78% completeness).

### B. AQI Patterns & Target Variable Analysis
* **Mean AQI**: 237.19 (Unhealthy range).
* **Median AQI**: 214.00.
* **AQI Range**: Minimum of 16.0 (Good) to Maximum of 1,113.0 (Severe/Hazardous peak).
* **25th & 75th Percentiles**: $Q_1 = 124.0$, $Q_3 = 325.0$.

### C. Pollutant Relationships
* **$PM_{10}$ ($r = 0.756$)** and **$PM_{2.5}$ ($r = 0.722$)** display the strongest positive linear correlation with the overall AQI score, confirming particulate matter as the primary driver of air pollution in Delhi.
* **Gaseous Pollutants**: $NO_2$ ($r = 0.367$), Benzene ($r = 0.353$), $NO_x$ ($r = 0.344$), $NH_3$ ($r = 0.332$), $NO$ ($r = 0.309$), and $CO$ ($r = 0.285$) show moderate positive correlations.

### D. Weather Relationships
* **Dew Point ($r = -0.515$)** & **Temperature ($r = -0.403$)**: Strong inverse correlation with AQI. Lower temperatures and dew points during winter months trap pollutants near the surface due to atmospheric temperature inversion layers.
* **Sea-Level Air Pressure ($r = +0.465$)**: High atmospheric pressure correlates with higher AQI due to stagnant air conditions.
* **Wind Speed ($r = -0.153$)**: Higher wind speeds assist in dispersing atmospheric pollutants, leading to lower AQI levels.

### E. Temporal Patterns
* **Diurnal (Hourly) Cycle**: AQI peaks during morning (07:00–10:00) and evening (19:00–22:00) rush hours due to vehicle emissions and lowered boundary layer heights at night.
* **Seasonal (Monthly) Cycle**: Severe AQI spikes occur during late autumn and winter months (October to January, peaking in November/December with mean AQI > 350) driven by stubble burning, festive fireworks, and winter inversion. Summer months (May to August) exhibit significantly lower AQI levels (mean AQI < 150).

### F. Exploratory Feature Importance Results
> [!NOTE]  
> *Per Milestone 1 guidelines, these feature rankings are strictly exploratory findings. Final model features will be formally selected in Milestone 2 based on the target prediction horizon (e.g., 1-hour vs 24-hour forecast).*

* **Top Ranking Predictors (Random Forest & Mutual Info)**:
  1. $PM_{2.5}$ & $PM_{10}$ (Highest feature weights & mutual information scores > 0.49)
  2. Month / Seasonal index (High MI score > 0.36)
  3. Dew Point & Temperature (°C)
  4. Sea-Level Air Pressure (hPa)
  5. $NO_2$ & $CO$ concentration levels

---

## 4. Real-Time System Architecture & Flow

The real-time monitoring system follows a strict end-to-end data pipeline:

$$\text{User GPS Location} \longrightarrow (\text{Latitude}, \text{Longitude}) \longrightarrow \begin{cases} \text{Nominatim API} \rightarrow \text{Reverse Geocoding / Address} \\ \text{WAQI API (Geo Feed)} \rightarrow \text{Live AQI \& Pollutants} \\ \text{Open-Meteo API} \rightarrow \text{Live Weather Parameters} \end{cases} \longrightarrow \text{Web Dashboard}$$

### Endpoints Implemented in FastAPI Backend (`backend/main.py`)
1. `GET /reverse-geocode?latitude={lat}&longitude={lon}`: Resolves GPS coordinates into street address and city name via OpenStreetMap Nominatim.
2. `GET /aqi/geo?latitude={lat}&longitude={lon}`: Native geographic lookup querying nearest WAQI monitoring station.
3. `GET /aqi/{city}`: Fallback lookup for explicit city queries.
4. `GET /weather?latitude={lat}&longitude={lon}`: Real-time weather parameters (Temperature °C, Humidity %, Wind Speed km/h, Surface Pressure hPa, WMO Weather Condition description) via Open-Meteo.

---

## 5. Security & Code Quality

* **Environment Variables**: API keys (WAQI Token) are stored securely in `.env` and accessed via `python-dotenv`.
* **Reliable Free APIs**: No paid subscriptions required; Open-Meteo provides keyless live weather, Nominatim provides keyless geocoding, and WAQI provides generous free tier feeds.
* **Error Handling & Fallbacks**: API requests include 10-second timeout controls, null value safety checks (`formatVal`), and grace messages when monitoring stations lack specific sensors.

---

## 6. Milestone 2 Roadmap & Next Steps

> [!IMPORTANT]  
> *Development of Machine Learning models and Smart Mobility Recommendation features is paused until explicit approval is granted for Milestone 2.*

When Milestone 2 is initiated, the planned roadmap includes:
1. **Define Prediction Horizon & Objectives**: Establish target forecast windows (e.g., 24-hour AQI prediction).
2. **Model Training & Evaluation**: Train machine learning models (XGBoost, Random Forest, LightGBM) on the preprocessed dataset.
3. **ML Inference API Integration**: Expose `/predict-aqi` endpoints in FastAPI.
4. **Smart Mobility Recommendation Engine**: Build rule-based/ML advisory algorithms suggesting optimal travel times and safe routing choices based on predicted AQI levels.
5. **Dashboard Enhancements**: Add forecast visual charts and mobility advisory panels to `frontend/index.html`.
