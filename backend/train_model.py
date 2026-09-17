"""
Model Training Script for AI-Powered Environmental Intelligence System
Trains a production PyTorch LSTM time-series model on historical Delhi AQI and Weather dataset.
Preserves the Scikit-Learn MLP baseline (backend/models/aqi_model.joblib).
Saves trained PyTorch LSTM weights to backend/models/aqi_lstm_model.pth, scaler to backend/models/scaler.pkl,
and comprehensive comparison metrics to backend/models/model_metadata.json.
"""

import os
import sys
import json
import time
from datetime import datetime
import numpy as np
import pandas as pd
import joblib

import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

np.random.seed(42)
torch.manual_seed(42)
torch.set_num_threads(os.cpu_count() or 4)

MODELS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "models"))
os.makedirs(MODELS_DIR, exist_ok=True)

DATASET_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "dataset", "dataset.csv"))

print("==================================================================")
print("PHASE B: TRAINING PYTORCH LSTM TIME-SERIES FORECASTING MODEL")
print("==================================================================")
print(f"Loading full dataset from: {DATASET_PATH}")
start_time = time.time()
df = pd.read_csv(DATASET_PATH, low_memory=False)
print(f"Initial Dataset Shape: {df.shape} (Loaded in {time.time() - start_time:.1f}s)")

# 1. Clean Column Names
df.columns = df.columns.str.strip()
column_mapping = {
    'temp (C)': 'temperature',
    'temp (°C)': 'temperature',
    'Dew Point  (C)': 'dew_point',
    'Dew Point  (°C)': 'dew_point',
    'Relative Humidity (%)': 'humidity',
    'Average Wind Speed (km/h)': 'wind_speed',
    'Sea-Level Air Pressure (hPa)': 'pressure'
}
df.rename(columns=column_mapping, inplace=True)

# 2. Filter valid AQI records
df = df.dropna(subset=['AQI']).copy()
print(f"Shape after dropping missing AQI: {df.shape}")

# 3. Robust Datetime Parsing & Chronological Ordering
print("Parsing Datetimes chronologically...")
df['Datetime'] = pd.to_datetime(df['Datetime'], format='mixed', dayfirst=True, errors='coerce')
df = df.dropna(subset=['Datetime']).sort_values('Datetime').reset_index(drop=True)
print(f"Shape after chronological sorting: {df.shape}")
print(f"Chronological Date Range: {df['Datetime'].min()} to {df['Datetime'].max()}")

# 4. Feature Engineering
df['hour'] = df['Datetime'].dt.hour
df['dayofweek'] = df['Datetime'].dt.dayofweek
df['month'] = df['Datetime'].dt.month
df['is_weekend'] = df['dayofweek'].isin([5, 6]).astype(int)

feature_cols = [
    'PM2.5', 'PM10', 'NO2', 'CO', 'SO2', 'O3',
    'temperature', 'humidity', 'wind_speed', 'pressure',
    'hour', 'dayofweek', 'month', 'is_weekend', 'AQI'
]

for col in feature_cols:
    if col not in df.columns:
        df[col] = 0.0

# Impute missing values with forward fill, backward fill, then median
print("Imputing missing feature values...")
df[feature_cols] = df[feature_cols].ffill().bfill()
for col in feature_cols:
    if df[col].isnull().any():
        df[col] = df[col].fillna(df[col].median())

# Rolling features (calculated chronologically)
print("Calculating 6-hour rolling features...")
df['pm25_roll6'] = df['PM2.5'].rolling(window=6, min_periods=1).mean()
df['pm10_roll6'] = df['PM10'].rolling(window=6, min_periods=1).mean()
df['aqi_roll6'] = df['AQI'].rolling(window=6, min_periods=1).mean()

full_feature_cols = feature_cols + ['pm25_roll6', 'pm10_roll6', 'aqi_roll6']
print(f"Total features selected ({len(full_feature_cols)}):")
print(full_feature_cols)

# 5. Chronological Train / Validation / Test Split BEFORE Scaling
total_records = len(df)
train_end = int(total_records * 0.70)
val_end = int(total_records * 0.85)

train_df = df.iloc[:train_end].copy()
val_df = df.iloc[train_end:val_end].copy()
test_df = df.iloc[val_end:].copy()

print(f"\nData Splits (Chronological):")
print(f"  Train : {len(train_df)} rows ({train_df['Datetime'].min()} -> {train_df['Datetime'].max()})")
print(f"  Val   : {len(val_df)} rows ({val_df['Datetime'].min()} -> {val_df['Datetime'].max()})")
print(f"  Test  : {len(test_df)} rows ({test_df['Datetime'].min()} -> {test_df['Datetime'].max()})")

# Fit MinMaxScaler strictly on training data
scaler = MinMaxScaler()
train_scaled = scaler.fit_transform(train_df[full_feature_cols])
val_scaled = scaler.transform(val_df[full_feature_cols])
test_scaled = scaler.transform(test_df[full_feature_cols])

target_idx = full_feature_cols.index('AQI')
SEQ_LENGTH = 24

def create_sequences(data, seq_len, target_col_idx, step=2):
    X, y = [], []
    for i in range(0, len(data) - seq_len, step):
        X.append(data[i : i + seq_len])
        y.append(data[i + seq_len, target_col_idx])
    return np.array(X, dtype=np.float32), np.array(y, dtype=np.float32)

print("\nGenerating time-series sequences (sequence length = 24 hours, step = 2)...")
X_train, y_train = create_sequences(train_scaled, SEQ_LENGTH, target_idx, step=2)
X_val, y_val = create_sequences(val_scaled, SEQ_LENGTH, target_idx, step=2)
X_test, y_test = create_sequences(test_scaled, SEQ_LENGTH, target_idx, step=2)

print(f"Sequence matrices created:")
print(f"  Train: X={X_train.shape}, y={y_train.shape}")
print(f"  Val  : X={X_val.shape}, y={y_val.shape}")
print(f"  Test : X={X_test.shape}, y={y_test.shape}")

# 6. PyTorch Dataset & DataLoader
class AQIDataset(Dataset):
    def __init__(self, X, y):
        self.X = torch.tensor(X, dtype=torch.float32)
        self.y = torch.tensor(y, dtype=torch.float32).unsqueeze(1)
    def __len__(self):
        return len(self.X)
    def __getitem__(self, idx):
        return self.X[idx], self.y[idx]

batch_size = 512
train_loader = DataLoader(AQIDataset(X_train, y_train), batch_size=batch_size, shuffle=True)
val_loader = DataLoader(AQIDataset(X_val, y_val), batch_size=batch_size, shuffle=False)
test_loader = DataLoader(AQIDataset(X_test, y_test), batch_size=batch_size, shuffle=False)

# 7. PyTorch LSTM Model Architecture
class AQILSTM(nn.Module):
    def __init__(self, input_dim, hidden_dim=64, num_layers=2, output_dim=1, dropout=0.2):
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

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"\nTraining on device: {device}")
model = AQILSTM(input_dim=len(full_feature_cols)).to(device)
criterion = nn.MSELoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

# 8. Training Loop with Validation and Early Stopping
EPOCHS = 5
best_val_loss = float('inf')
best_state = None
patience = 2
patience_counter = 0

print(f"\nStarting PyTorch LSTM training for up to {EPOCHS} epochs (batch_size={batch_size}, lr=0.001)...")
for epoch in range(1, EPOCHS + 1):
    epoch_start = time.time()
    model.train()
    total_train_loss = 0.0
    for b_X, b_y in train_loader:
        b_X, b_y = b_X.to(device), b_y.to(device)
        optimizer.zero_grad()
        preds = model(b_X)
        loss = criterion(preds, b_y)
        loss.backward()
        optimizer.step()
        total_train_loss += loss.item() * len(b_X)
    
    avg_train_loss = total_train_loss / len(X_train)
    train_rmse_norm = np.sqrt(avg_train_loss)

    model.eval()
    total_val_loss = 0.0
    with torch.no_grad():
        for b_X, b_y in val_loader:
            b_X, b_y = b_X.to(device), b_y.to(device)
            preds = model(b_X)
            loss = criterion(preds, b_y)
            total_val_loss += loss.item() * len(b_X)
    
    avg_val_loss = total_val_loss / len(X_val)
    val_rmse_norm = np.sqrt(avg_val_loss)
    epoch_time = time.time() - epoch_start

    print(f"Epoch [{epoch:02d}/{EPOCHS:02d}] ({epoch_time:.1f}s) - Train Loss: {avg_train_loss:.6f} (Norm RMSE: {train_rmse_norm:.4f}) | Val Loss: {avg_val_loss:.6f} (Norm RMSE: {val_rmse_norm:.4f})")

    if avg_val_loss < best_val_loss:
        best_val_loss = avg_val_loss
        best_state = model.state_dict().copy()
        patience_counter = 0
    else:
        patience_counter += 1
        if patience_counter >= patience:
            print(f"Early stopping triggered at epoch {epoch} (no validation improvement for {patience} consecutive epochs).")
            break

# Restore best weights
if best_state is not None:
    model.load_state_dict(best_state)

# 9. Test Evaluation on Unseen Chronological Test Set
print("\nEvaluating best LSTM model on unseen chronological test set...")
model.eval()
test_preds = []
with torch.no_grad():
    for b_X, _ in test_loader:
        b_X = b_X.to(device)
        preds = model(b_X).cpu().numpy()
        test_preds.extend(preds)

test_preds = np.array(test_preds).flatten()

# Inverse transform predictions and actual targets back to AQI scale
dummy_pred = np.zeros((len(test_preds), len(full_feature_cols)))
dummy_pred[:, target_idx] = test_preds
inv_pred = scaler.inverse_transform(dummy_pred)[:, target_idx]

dummy_act = np.zeros((len(y_test), len(full_feature_cols)))
dummy_act[:, target_idx] = y_test
inv_act = scaler.inverse_transform(dummy_act)[:, target_idx]

mse = mean_squared_error(inv_act, inv_pred)
rmse = np.sqrt(mse)
mae = mean_absolute_error(inv_act, inv_pred)
r2 = r2_score(inv_act, inv_pred)

print("\n==================================================================")
print("FINAL MODEL EVALUATION METRICS (ON UNSEEN TEST DATA)")
print("==================================================================")
print(f"Model Architecture       : PyTorch LSTM (2 layers, hidden_dim=64, dropout=0.2)")
print(f"Test Samples Evaluated   : {len(inv_act):,}")
print(f"Mean Absolute Error (MAE): {mae:.4f}")
print(f"Root Mean Squared Error  : {rmse:.4f}")
print(f"Mean Squared Error (MSE) : {mse:.4f}")
print(f"R-squared (R2 Score)     : {r2:.4f} (meaning {r2 * 100:.2f}% of AQI variance explained)")
print("==================================================================")

# 10. Save Model Artifacts
lstm_model_path = os.path.join(MODELS_DIR, "aqi_lstm_model.pth")
torch.save(model.state_dict(), lstm_model_path)
print(f"\nSaved PyTorch LSTM model to: {lstm_model_path}")

scaler_path = os.path.join(MODELS_DIR, "scaler.pkl")
joblib.dump({
    'scaler': scaler,
    'feature_cols': full_feature_cols,
    'target_idx': target_idx,
    'seq_length': SEQ_LENGTH,
    'has_torch': True
}, scaler_path)
print(f"Saved scaler artifact to: {scaler_path}")

metadata_path = os.path.join(MODELS_DIR, "model_metadata.json")
metadata = {
    "model_type": "PyTorch LSTM Neural Network",
    "model_file": "backend/models/aqi_lstm_model.pth",
    "training_file": "backend/train_model.py",
    "dataset_file": "dataset/dataset.csv",
    "sequence_length_hours": SEQ_LENGTH,
    "forecast_horizon_hours": 24,
    "feature_columns": full_feature_cols,
    "dataset_records_used": total_records,
    "train_samples": len(X_train),
    "validation_samples": len(X_val),
    "test_samples": len(X_test),
    "hyperparameters": {
        "architecture": "LSTM (2 layers, hidden_dim=64, fc_32, relu, fc_1)",
        "dropout": 0.2,
        "optimizer": "Adam",
        "learning_rate": 0.001,
        "batch_size": batch_size,
        "loss_function": "MSELoss",
        "epochs_trained": epoch,
        "early_stopping": True
    },
    "metrics": {
        "mae": round(float(mae), 4),
        "rmse": round(float(rmse), 4),
        "mse": round(float(mse), 4),
        "r2_score": round(float(r2), 4)
    },
    "baseline_comparison": {
        "model_type": "Deep MLP Neural Network (Scikit-Learn)",
        "baseline_file": "backend/models/aqi_model.joblib",
        "mae": 34.6247,
        "rmse": 46.2358,
        "mse": 2137.7461,
        "r2_score": 0.8424
    },
    "training_timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
}

with open(metadata_path, 'w') as f:
    json.dump(metadata, f, indent=4)
print(f"Saved comprehensive model metadata to: {metadata_path}")

print("\n>>> PHASE B: PYTORCH LSTM TRAINING COMPLETE! <<<")
