#!/usr/bin/env bash
# ==============================================================================
# Description: Tags a local Docker image and pushes it to Google Cloud
#   Artifact Registry using a Service Account JSON key file. Fails fast if
#   the key file is missing so the Jenkins stage marks FAILURE with an
#   actionable message.
# Author: pipeline-security
# Usage: ./pushDockerImageToGoogleCloud.sh <project-id> <region> <image-name> <tag> <sa-key-path>
#   Example: ./pushDockerImageToGoogleCloud.sh my-project southamerica-west1 my-app 1.42 /run/secrets/sa.json
#   Help: ./pushDockerImageToGoogleCloud.sh --help
# Env Vars: none (all inputs are positional args; the SA key PATH is passed,
#   never the key content, so the secret never lands in logs)
# Dependencies: gcloud, docker
# Output: push log plus FULL_IMAGE=<ref> and DIGEST: <repo-digest> lines for
#   Jenkins notifications; digest lookup is best-effort (WARN to STDERR).
# Exit codes: 0 on success; 1 on missing args, missing key file, or any
#   gcloud/docker failure (set -euo pipefail).
# ==============================================================================
set -euo pipefail

# Prints CLI usage to STDOUT and exits 0.
usage() {
  cat <<'EOF'
Usage: pushDockerImageToGoogleCloud.sh <project-id> <region> <image-name> <tag> <sa-key-path>

Pushes <image-name>:<tag> to <region>-docker.pkg.dev/<project-id>/docker/.

Arguments:
  project-id    GCP project id owning the Artifact Registry repo
  region        Artifact Registry region (e.g. southamerica-west1)
  image-name    Local Docker image name
  tag           Local Docker image tag
  sa-key-path   Path to the Service Account JSON key FILE (content never echoed)

Options:
  -h, --help    Show this help and exit 0
EOF
}

# ---- arg handling (validation errors go to STDERR) ----
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "$#" -ne 5 ]]; then
  echo "ERROR: expected 5 arguments, got $#. See --help." >&2
  usage >&2
  exit 1
fi

PROJECT_ID="$1"
REGION="$2"
IMAGE_NAME="$3"
TAG="$4"
SA_KEY="$5"

if [[ ! -f "$SA_KEY" ]]; then
  echo "ERROR: Service Account JSON not found: $SA_KEY" >&2
  exit 1
fi

AR_HOST="${REGION}-docker.pkg.dev"
FULL_IMAGE="${AR_HOST}/${PROJECT_ID}/docker/${IMAGE_NAME}:${TAG}"

echo "======================================"
echo " Project:               ${PROJECT_ID}"
echo " Region:                ${REGION}"
echo " Local image:           ${IMAGE_NAME}:${TAG}"
echo " Remote image:          ${FULL_IMAGE}"
echo "======================================"

echo "[0/3] Authenticating Service Account..."
gcloud auth activate-service-account --key-file="${SA_KEY}"

echo "[1/3] Setting project..."
gcloud config set project "${PROJECT_ID}"

echo "[2/3] Configuring Docker for Artifact Registry..."
gcloud auth configure-docker "${AR_HOST}" --quiet

echo "[3/3] Tag + Push..."
docker tag "${IMAGE_NAME}:${TAG}" "${FULL_IMAGE}"
docker push "${FULL_IMAGE}"

# Prints the RepoDigest so the Jenkins log (and notifications) can link the
# exact pushed bytes; best-effort because the digest may lag right after push.
echo "FULL_IMAGE: ${FULL_IMAGE}"
if DIGEST="$(docker inspect --format='{{index .RepoDigests 0}}' "${FULL_IMAGE}" 2>/dev/null)"; then
  echo "DIGEST: ${DIGEST}"
else
  echo "WARN: RepoDigest not available yet for ${FULL_IMAGE}" >&2
fi

echo "Image successfully published to Artifact Registry."
