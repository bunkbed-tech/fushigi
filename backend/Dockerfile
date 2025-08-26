FROM python:3.12-slim

WORKDIR /app

# Setup baseline layer with pinned versions and no-install-recommends
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  libpq-dev \
  && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install packages without cache
RUN pip install --no-cache-dir --upgrade pip==23.1.2 \
 && pip install --no-cache-dir uv==0.8.8 hatchling==1.27.0

# Copy what I need to install
COPY pyproject.toml uv.lock ./
COPY backend/ ./backend/
RUN uv sync --dev

# Set global environment variables (potentially move to env files later)
ENV DATABASE_URL=postgres://postgres:password@db/postgres
