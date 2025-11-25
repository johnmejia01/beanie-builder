#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [OPTIONS]" >&2
  echo "Options:" >&2
  echo "  --image-builder-cmd CMD    Image builder command (default: image-builder)" >&2
  echo "  --base-image IMAGE          Base image type (e.g., minimal-installer)" >&2
  echo "  --blueprint PATH            Path to prepared blueprint" >&2
  echo "  --output-dir DIR             Output directory for images" >&2
  echo "  --cache-dir DIR              Cache directory" >&2
  echo "  --arch ARCH                 Architecture (e.g., x86_64)" >&2
  echo "  --distro DISTRO             Distribution (e.g., fedora-42)" >&2
  echo "  --image-name NAME           Name of the output image file" >&2
  exit 1
}

IMAGE_BUILDER_CMD="image-builder"
IMAGE_TYPE=""
PREPARED_BLUEPRINT=""
OUTPUT_DIR=""
CACHE_DIR=""
ARCH=""
DISTRO=""
IMAGE_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image-builder-cmd)
      IMAGE_BUILDER_CMD="$2"
      shift 2
      ;;
    --base-image)
      IMAGE_TYPE="$2"
      shift 2
      ;;
    --blueprint)
      PREPARED_BLUEPRINT="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --cache-dir)
      CACHE_DIR="$2"
      shift 2
      ;;
    --arch)
      ARCH="$2"
      shift 2
      ;;
    --distro)
      DISTRO="$2"
      shift 2
      ;;
    --image-name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# Validate required parameters
if [ -z "$IMAGE_TYPE" ] || [ -z "$PREPARED_BLUEPRINT" ] || [ -z "$OUTPUT_DIR" ] || \
   [ -z "$CACHE_DIR" ] || [ -z "$ARCH" ] || [ -z "$DISTRO" ] || [ -z "$IMAGE_NAME" ]; then
  echo "Error: Missing required parameters" >&2
  usage
fi

# Build the image
sudo "$IMAGE_BUILDER_CMD" build "$IMAGE_TYPE" \
  --blueprint "$PREPARED_BLUEPRINT" \
  --output-dir "$OUTPUT_DIR" \
  --cache "$CACHE_DIR" \
  --arch "$ARCH" \
  --distro "$DISTRO" \
  --output-name "$IMAGE_NAME" \
  --progress=verbose

# Decompress if needed
if [ "$IMAGE_TYPE" == "minimal-raw-zst" ]; then
  unzstd "$OUTPUT_DIR/$IMAGE_NAME".zst
fi

exit 0