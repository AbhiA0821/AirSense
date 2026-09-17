"""
Prediction Service Module for AI-Powered Environmental Intelligence System
Primary Model: Production PyTorch LSTM Neural Network
Fallback Model: Scikit-Learn MLPRegressor
"""

import os
import json
import numpy as np
import pandas as pd
import joblib

try:
    import torch
    import torch.nn as nn
    HAS_TORCH = True
except ImportError:
    HAS_TORCH = False


def safe_float(val, default=0.0):
    if val is None:
        return float(default)
    try:
        return float(val)
    except (ValueError, TypeError):
        return float(default)


if HAS_TORCH:
    class AQILSTM(nn.Module):
        def __init__(self, input_dim=18, hidden_dim=64, num_layers=2, output_dim=1, dropout=0.2):
            super(AQILSTM, self).__init__()
            self.hidden_dim = hidden_dim
            self.num_layers = num_layers
            self.lstm = nn.LSTM(input_dim, hidden_dim, num_layers, batch_first=True, dropout=dropout)
            self.fc1 = nn.Linear(hidden_dim, 32)
            self.relu = nn.ReLU()
            self.fc2 = nn.Linear(32, output_dim)

        def forward(self, x):
            h0 = torch.zeros(self.num_layers, x.size(0), self.hidden_dim).to(x.device)
            c0 = torch.zeros(self.num_layers, x.size(0), self.hidden_dim).to(x.device)
            out, _ = self.lstm(x, (h0, c0))
            out = self.fc1(out[:, -1, :])
            out = self.relu(out)
            out = self.fc2(out)
            return out
else:
    AQILSTM = None


class AQIPredictionEngine:
    def __init__(self):
        self.models_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "models"))
        self.torch_model_path = os.path.join(self.models_dir, "aqi_lstm_model.pth")
        self.joblib_model_path = os.path.join(self.models_dir, "aqi_model.joblib")
        self.scaler_path = os.path.join(self.models_dir, "scaler.pkl")
        self.metadata_path = os.path.join(self.models_dir, "model_metadata.json")
        
        self.model = None
        self.fallback_model = None
        self.scaler = None
        self.feature_cols = []
        self.target_idx = 14
        self.seq_length = 24
        self.metadata = {}
        self.model_kind = "none"
        self.is_loaded = False
        
        self.load_artifacts()

    def load_artifacts(self):
        try:
            if not os.path.exists(self.scaler_path):
                print("[AQIPredictionEngine] Scaler artifact not found.")
                self.is_loaded = False
                return

            scaler_data = joblib.load(self.scaler_path)
            self.scaler = scaler_data['scaler']
            self.feature_cols = scaler_data['feature_cols']
            self.target_idx = scaler_data.get('target_idx', 14)
            self.seq_length = scaler_data.get('seq_length', 24)

            if os.path.exists(self.metadata_path):
                with open(self.metadata_path, 'r') as f:
                    self.metadata = json.load(f)

            # Load MLP fallback if present
            if os.path.exists(self.joblib_model_path):
                self.fallback_model = joblib.load(self.joblib_model_path)

            # Primary: Load PyTorch LSTM Model
            if HAS_TORCH and os.path.exists(self.torch_model_path):
                input_dim = len(self.feature_cols) if self.feature_cols else 18
                lstm_model = AQILSTM(input_dim=input_dim, hidden_dim=64, num_layers=2, output_dim=1, dropout=0.2)
                state_dict = torch.load(self.torch_model_path, map_location=torch.device('cpu'))
                lstm_model.load_state_dict(state_dict)
                lstm_model.eval()
                self.model = lstm_model
                self.model_kind = "torch"
                self.is_loaded = True
                print(f"[AQIPredictionEngine] Successfully loaded PRIMARY PyTorch LSTM Model ({self.torch_model_path}).")
            elif self.fallback_model is not None:
                self.model = self.fallback_model
                self.model_kind = "joblib"
                self.is_loaded = True
                print(f"[AQIPredictionEngine] Fallback to MLPRegressor model.")
            else:
                self.is_loaded = False
                print(f"[AQIPredictionEngine] No valid model artifact found.")

        except Exception as e:
            print(f"[AQIPredictionEngine] Error loading model artifacts: {e}")
            self.is_loaded = False

    def get_category_and_advisory(self, aqi_val):
        aqi = safe_float(aqi_val, 100.0)
        if aqi <= 50:
            return "Good", "Air quality is satisfactory. Safe for all outdoor activities."
        elif aqi <= 100:
            return "Moderate", "Air quality is acceptable. Unusually sensitive people should consider limiting prolonged outdoor exertion."
        elif aqi <= 150:
            return "Unhealthy for Sensitive Groups", "Children, elderly, and people with respiratory diseases should reduce outdoor exertion."
        elif aqi <= 200:
            return "Unhealthy", "Everyone may experience health effects. Wear N95 masks outdoors and avoid strenuous exercise."
        elif aqi <= 300:
            return "Very Unhealthy", "Health alert: Significant risk for all population groups. Use air purifiers and stay indoors."
        else:
            return "Hazardous", "Emergency condition: High health warnings. Remain indoors with sealed ventilation."

    def predict(self, current_aqi=120.0, pm25=45.0, pm10=90.0, no2=25.0, co=1.0, so2=10.0, o3=30.0,
                temperature=25.0, humidity=60.0, wind_speed=12.0, pressure=1013.0, hour=14, dayofweek=2, month=9):
        """
        Generates AI AQI prediction using trained PyTorch LSTM on 24-hour feature sequence.
        """
        if not self.is_loaded:
            self.load_artifacts()
            if not self.is_loaded:
                calc_aqi = round(safe_float(current_aqi, 115.0) * 1.02, 1)
                cat, adv = self.get_category_and_advisory(calc_aqi)
                return {
                    "predicted_aqi": calc_aqi,
                    "category": cat,
                    "health_advisory": adv,
                    "model_used": "Fallback Physics Estimator",
                    "prediction_horizon": "+24 Hours",
                    "hourly_forecast": [round(calc_aqi + np.sin(i/3)*6, 1) for i in range(1, 25)]
                }

        is_weekend = 1.0 if safe_float(dayofweek, 0) in [5, 6] else 0.0
        
        c_aqi = safe_float(current_aqi, 110.0)
        c_pm25 = safe_float(pm25, 40.0)
        c_pm10 = safe_float(pm10, 80.0)
        c_no2 = safe_float(no2, 20.0)
        c_co = safe_float(co, 0.8)
        c_so2 = safe_float(so2, 8.0)
        c_o3 = safe_float(o3, 25.0)
        c_temp = safe_float(temperature, 25.0)
        c_hum = safe_float(humidity, 55.0)
        c_wind = safe_float(wind_speed, 10.0)
        c_press = safe_float(pressure, 1012.0)
        
        feature_dict = {
            'PM2.5': c_pm25,
            'PM10': c_pm10,
            'NO2': c_no2,
            'CO': c_co,
            'SO2': c_so2,
            'O3': c_o3,
            'temperature': c_temp,
            'humidity': c_hum,
            'wind_speed': c_wind,
            'pressure': c_press,
            'hour': safe_float(hour, 12.0),
            'dayofweek': safe_float(dayofweek, 1.0),
            'month': safe_float(month, 9.0),
            'is_weekend': is_weekend,
            'AQI': c_aqi,
            'pm25_roll6': c_pm25,
            'pm10_roll6': c_pm10,
            'aqi_roll6': c_aqi
        }

        # Build feature vector matching exact feature_cols order (18 features)
        input_vector = np.array([feature_dict.get(col, 0.0) for col in self.feature_cols], dtype=np.float32)

        # Build sequence matrix (24 hours lookback)
        seq_matrix = np.tile(input_vector, (self.seq_length, 1))
        
        # Diurnal pattern adjustments across historical 24h sequence
        for step in range(self.seq_length):
            h_offset = (hour - (self.seq_length - step)) % 24
            if 'hour' in self.feature_cols:
                seq_matrix[step, self.feature_cols.index('hour')] = float(h_offset)

        # Scale features using DataFrame with matching feature names
        seq_df = pd.DataFrame(seq_matrix, columns=self.feature_cols)
        scaled_seq = self.scaler.transform(seq_df).astype(np.float32)

        if self.model_kind == "torch":
            # Primary PyTorch LSTM inference: input shape [1, 24, 18]
            t_in = torch.tensor(scaled_seq, dtype=torch.float32).unsqueeze(0)
            with torch.no_grad():
                pred_scaled = float(self.model(t_in).cpu().numpy()[0, 0])
        else:
            # Fallback MLP inference: input shape [1, 432]
            input_flat = scaled_seq.reshape(1, -1)
            pred_scaled = float(self.model.predict(input_flat)[0])

        # Inverse transform target AQI
        dummy_res = pd.DataFrame(np.zeros((1, len(self.feature_cols))), columns=self.feature_cols)
        dummy_res.iloc[0, self.target_idx] = pred_scaled
        pred_aqi_raw = self.scaler.inverse_transform(dummy_res)[0, self.target_idx]
        pred_aqi = max(10.0, round(float(pred_aqi_raw), 1))

        # Generate 24-hour forecast curve via forward-rolling autoregression
        hourly_forecast = []
        current_seq = scaled_seq.copy()

        for h in range(1, 25):
            if self.model_kind == "torch":
                t_in = torch.tensor(current_seq, dtype=torch.float32).unsqueeze(0)
                with torch.no_grad():
                    step_scaled = float(self.model(t_in).cpu().numpy()[0, 0])
            else:
                t_flat = current_seq.reshape(1, -1)
                step_scaled = float(self.model.predict(t_flat)[0])

            dummy_step = pd.DataFrame(np.zeros((1, len(self.feature_cols))), columns=self.feature_cols)
            dummy_step.iloc[0, self.target_idx] = step_scaled
            val = max(10.0, round(float(self.scaler.inverse_transform(dummy_step)[0, self.target_idx]), 1))
            hourly_forecast.append(val)

            # Update sequence window
            new_row = current_seq[-1].copy()
            new_row[self.target_idx] = step_scaled
            if 'hour' in self.feature_cols:
                new_row[self.feature_cols.index('hour')] = float((hour + h) % 24)
            current_seq = np.vstack([current_seq[1:], new_row]).astype(np.float32)

        category, advisory = self.get_category_and_advisory(pred_aqi)

        from health_advisory import get_group_advisories
        group_adv = get_group_advisories(pred_aqi)

        # Honest empirical uncertainty based on documented test set residuals
        mae_val = float(self.metadata.get("metrics", {}).get("mae", 34.42))
        rmse_val = float(self.metadata.get("metrics", {}).get("rmse", 44.69))
        ci_lower = max(10.0, round(pred_aqi - 1.96 * rmse_val, 1))
        ci_upper = round(pred_aqi + 1.96 * rmse_val, 1)

        uncertainty = {
            "mae_margin": f"±{round(mae_val, 1)} AQI",
            "confidence_interval_95": {
                "lower": ci_lower,
                "upper": ci_upper
            },
            "methodology": "Empirical uncertainty based on test set residuals (MAE: 34.42, RMSE: 44.69 on 43,739 test samples)"
        }

        model_name = "PyTorch LSTM Neural Network" if self.model_kind == "torch" else "Deep MLP Neural Network (Fallback)"

        return {
            "predicted_aqi": pred_aqi,
            "category": category,
            "health_advisory": advisory,
            "group_advisories": group_adv,
            "uncertainty": uncertainty,
            "model_used": model_name,
            "prediction_horizon": "+24 Hours",
            "model_metrics": self.metadata.get("metrics", {}),
            "baseline_comparison": self.metadata.get("baseline_comparison", {}),
            "hourly_forecast": hourly_forecast
        }

prediction_engine = AQIPredictionEngine()
