# Delhi Air Quality & Meteorological Dataset

## Overview

This directory houses the historical multi-station air quality and meteorological time-series dataset used to train and validate the PyTorch LSTM neural network for the AI-Powered Environmental Intelligence System.

> **Note on Version Control:** Due to GitHub's file size limit (dataset is ~136 MB), `dataset.csv` is excluded from Git tracking via `.gitignore`. The dataset file should be placed locally in this directory.

---

## Dataset Details

- **Dataset Name:** Delhi Multi-Station Hourly Air Quality and Meteorological Records
- **Data Sources:**
  - Central Pollution Control Board (CPCB), Ministry of Environment, Forest and Climate Change, Government of India
  - Delhi Pollution Control Committee (DPCC)
  - India Meteorological Department (IMD)
- **Geographic Coverage:** National Capital Territory (NCT) of Delhi across 27 permanent ground monitoring stations.
- **Temporal Resolution:** Hourly observations (chronologically sorted).
- **Total Records:** 583,340 observations.
- **Expected File Path:** `dataset/dataset.csv`
- **Expected File Size:** ~136.6 MB

---

## Feature Specifications

The dataset integrates 18 core environmental, meteorological, and temporal features used for sequential modeling:

| Feature Column | Description | Units / Format |
|---|---|---|
| `PM2.5` | Particulate Matter < 2.5 µm | µg/m³ |
| `PM10` | Particulate Matter < 10 µm | µg/m³ |
| `NO2` | Nitrogen Dioxide | µg/m³ |
| `CO` | Carbon Monoxide | mg/m³ |
| `SO2` | Sulphur Dioxide | µg/m³ |
| `O3` | Ground-level Ozone | µg/m³ |
| `temperature` | Ambient 2m Temperature | °C |
| `humidity` | Relative Humidity | % |
| `wind_speed` | Surface Wind Speed | km/h |
| `pressure` | Atmospheric Pressure | hPa |
| `hour` | Hour of Day | 0 – 23 |
| `dayofweek` | Day of Week | 0 (Monday) – 6 (Sunday) |
| `month` | Calendar Month | 1 – 12 |
| `is_weekend` | Binary Weekend Indicator | 0 (Weekday), 1 (Weekend) |
| `AQI` | Target National Air Quality Index | Index (0 – 500+) |
| `pm25_roll6` | 6-hour rolling average PM2.5 | µg/m³ |
| `pm10_roll6` | 6-hour rolling average PM10 | µg/m³ |
| `aqi_roll6` | 6-hour rolling average AQI | Index |

---

## Data Preprocessing & Model Usage

1. **Chronological Splitting:** The data is partitioned chronologically into:
   - **Train:** 70% (204,157 hourly sequences)
   - **Validation:** 15% (43,739 hourly sequences)
   - **Test:** 15% (43,739 hourly sequences)
2. **Sequence Windowing:** Sliding window of 24 historical hours `[batch_size, 24, 18]` forecasting the next hour and 24-hour forward trajectory.
3. **Scaling:** Normalized using `MinMaxScaler` fitted strictly on the training set and saved to `backend/models/scaler.pkl`.
4. **Reproducibility:** Run `python backend/train_model.py` to regenerate the PyTorch model artifacts (`aqi_lstm_model.pth`).
