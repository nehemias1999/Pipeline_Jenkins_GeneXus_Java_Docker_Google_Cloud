#!/usr/bin/env bash
set -euo pipefail

# =========================
# Parameters
# =========================

PROJECT_ID="$1"
REGION="$2"
IMAGE_NAME="$3"
TAG="$4"
SA_KEY="$5"

# =========================
# Validations
# =========================

if [[ ! -f "$SA_KEY" ]]; then
  echo "ERROR: Service Account JSON not found: $SA_KEY"
  exit 1
fi

# =========================
# Artifact Registry URL
# =========================

AR_HOST="${REGION}-docker.pkg.dev"
FULL_IMAGE="${AR_HOST}/${PROJECT_ID}/docker/${IMAGE_NAME}:${TAG}"

echo "======================================"
echo " Project:               ${PROJECT_ID}"
echo " Region:                ${REGION}"
echo " Local image:            ${IMAGE_NAME}:${TAG}"
echo " Remote image:           ${FULL_IMAGE}"
echo " Service Account JSON:   ${SA_KEY}"
echo "======================================"

# =========================
# Authentication
# =========================

echo "[0/3] Authenticating Service Account..."
gcloud auth activate-service-account --key-file="${SA_KEY}"

# =========================
# Project configuration
# =========================

echo "[1/3] Setting project..."
gcloud config set project "${PROJECT_ID}"

# =========================
# Docker authentication for Artifact Registry
# =========================

echo "[2/3] Configuring Docker for Artifact Registry..."
gcloud auth configure-docker "${AR_HOST}" --quiet

# =========================
# Push
# =========================

echo "[3/3] Tag + Push..."
docker tag "${IMAGE_NAME}:${TAG}" "${FULL_IMAGE}"
docker push "${FULL_IMAGE}"

echo "Image successfully published to Artifact Registry."
