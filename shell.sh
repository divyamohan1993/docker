#!/bin/bash
set -euo pipefail

APP_NAME="flask-app"
REGISTRY="local"

# Jenkins sets GIT_COMMIT; fall back to 'dev' if not available
# Ensure we have a commit id even under `set -u`
# If Jenkins didn't export GIT_COMMIT, derive it from git (or "dev")
GIT_COMMIT="${GIT_COMMIT:-$(git rev-parse --short HEAD 2>/dev/null || echo dev)}"
SHORT_SHA="${GIT_COMMIT:0:7}"
 
IMAGE_TAG="${REGISTRY}/${APP_NAME}:${SHORT_SHA}"
IMAGE_LATEST="${REGISTRY}/${APP_NAME}:latest"

# Fail early if Docker isn’t installed/accessible
command -v docker >/dev/null 2>&1 || { echo "Docker CLI not found"; exit 127; }

# Build with both a unique and a 'latest' tag
docker build -t "${IMAGE_TAG}" -t "${IMAGE_LATEST}" .

# Clean up any existing container
docker rm -f "${APP_NAME}" >/dev/null 2>&1 || true

# Run the new container
docker run -d --name "${APP_NAME}" -p 5000:5000 "${IMAGE_TAG}"

# Simple health wait + check (up to ~30s)
for i in {1..30}; do
  if curl -fsS http://localhost:5000/health >/dev/null; then
    echo "App is healthy"
    break
  fi
  sleep 1
done
curl -fsS http://localhost:5000/health >/dev/null || { echo "App not healthy"; exit 1; }

echo "Done: ${IMAGE_TAG}"
