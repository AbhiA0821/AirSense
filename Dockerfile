FROM python:3.11-slim

# Prevent Python from writing .pyc files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PORT=7860

# Install minimal OS dependencies needed for network and build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set up standard Hugging Face Spaces non-root user (UID 1000)
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH \
    PYTHONPATH=/home/user/app:/home/user/app/backend:$PYTHONPATH

WORKDIR $HOME/app

# Step 1: Install CPU-only PyTorch first to prevent installing ~2GB CUDA wheels
RUN pip install --upgrade pip && \
    pip install torch==2.2.0 --index-url https://download.pytorch.org/whl/cpu

# Step 2: Install remaining backend dependencies
COPY --chown=user:user backend/requirements.txt ./backend/requirements.txt
RUN pip install -r backend/requirements.txt

# Step 3: Pre-download SentenceTransformer weights to bake into image (avoids cold-start network downloads)
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')"

# Step 4: Copy required backend source code, model weights, and calibration data
COPY --chown=user:user backend/ ./backend/

# Hugging Face Spaces exposes port 7860 by default
EXPOSE 7860

# Start FastAPI backend bound to 0.0.0.0 and port 7860
CMD ["sh", "-c", "uvicorn backend.app_final:app --host 0.0.0.0 --port ${PORT:-7860}"]
