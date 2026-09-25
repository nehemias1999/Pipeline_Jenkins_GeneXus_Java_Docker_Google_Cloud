#!/usr/bin/env bash
# ==============================================================================
# Description: Prunes local Docker images of the known application
#   repositories, keeping only the 3 most recent tags per repository to free
#   disk space on the remote build server. Never fails the pipeline when an
#   individual rmi fails; reports it and continues.
# Author: pipeline-security
# Usage: ./deleteOldDockerLocalImages.sh
#   Help: ./deleteOldDockerLocalImages.sh --help
# Env Vars: none
# Dependencies: docker
# Exit codes: 0 always on completion (per-image failures are logged, not fatal).
# ==============================================================================
set -euo pipefail

# Prints CLI usage to STDOUT and exits 0.
usage() {
  cat <<'EOF'
Usage: deleteOldDockerLocalImages.sh

Keeps only the 3 most recent local images per known repository.

Options:
  -h, --help    Show this help and exit 0
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# List of local repositories/images to process.
repos=(
  "java_application_dev"
)

echo "Removing local images, keeping only the 3 most recent ones..."
for repo in "${repos[@]}"; do
  echo
  echo "Processing repository: $repo"

  # 1) Get the list of image names and tags.
  mapfile -t images_names < <(
    docker images "$repo" --format "{{.Repository}}:{{.Tag}}" \
      | sort -r
  )

  total=${#images_names[@]}
  echo "Total images found: $total"

  # 2) If there are 3 or fewer images, do not remove anything.
  if (( total <= 3 )); then
    echo "There are $total images (<=3); nothing will be removed."
    continue
  fi

  # 3) Build the list of image names to delete (from the 4th onward).
  images_to_delete=( "${images_names[@]:3}" )
  echo "Removing ${#images_to_delete[@]} old images from $repo..."

  echo "All images: ${images_names[*]}"
  echo "Images to be deleted: ${images_to_delete[*]}"

  # 4) Remove old images one by one (a single failure never aborts cleanup).
  for image_name in "${images_to_delete[@]}"; do
    echo "Removing image $image_name..."
    docker rmi -f "$image_name" || echo "Failed to remove image $image_name."
  done

done

echo
echo "Process completed: only the 3 most recent images of each repository were kept."
