#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [OPTIONS]" >&2
  echo "Options:" >&2
  echo "  --blueprint-name NAME        Blueprint name (e.g., mobile_workstation_nvidia)" >&2
  echo "  --config-root DIR            Root directory for config files (default: blueprint-config)" >&2
  echo "  --image-builder-cmd CMD      Image builder command (default: image-builder)" >&2
  exit 1
}

BLUEPRINT_NAME=""
CONFIG_ROOT="blueprint-config"
IMAGE_BUILDER_CMD="image-builder"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --blueprint-name)
      BLUEPRINT_NAME="$2"
      shift 2
      ;;
    --config-root)
      CONFIG_ROOT="$2"
      shift 2
      ;;
    --image-builder-cmd)
      IMAGE_BUILDER_CMD="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# Validate required parameters
if [ -z "$BLUEPRINT_NAME" ]; then
  echo "Error: Missing required parameter --blueprint-name" >&2
  usage
fi

# Check if yq is available
if ! command -v yq >/dev/null 2>&1; then
  echo "Error: yq is required but not installed. Install yq v4+." >&2
  exit 1
fi

# Check if image-builder command is available (check only the first word of the command)
FIRST_CMD="${IMAGE_BUILDER_CMD%% *}"
if ! command -v "$FIRST_CMD" >/dev/null 2>&1; then
  echo "Error: $FIRST_CMD (from $IMAGE_BUILDER_CMD) is required but not installed." >&2
  exit 1
fi

# Path to YAML config file
CONFIG_FILE="$CONFIG_ROOT/$BLUEPRINT_NAME.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Config file not found: $CONFIG_FILE" >&2
  exit 1
fi

# Extract values from YAML
# Note: image-type has a hyphen, so we need to quote it or use bracket notation
DISTRO="$(yq -r '.distro // ""' "$CONFIG_FILE")"
IMAGE_TYPE="$(yq -r '.["image-type"] // ""' "$CONFIG_FILE")"
ARCH="$(yq -r '.arch // ""' "$CONFIG_FILE")"

# Validate that all required fields are present
if [ -z "$DISTRO" ] || [ -z "$IMAGE_TYPE" ] || [ -z "$ARCH" ]; then
  echo "Error: Missing required fields in config file $CONFIG_FILE" >&2
  echo "  Required fields: distro, image-type, arch" >&2
  echo "  Found:" >&2
  echo "    distro: ${DISTRO:-<missing>}" >&2
  echo "    image-type: ${IMAGE_TYPE:-<missing>}" >&2
  echo "    arch: ${ARCH:-<missing>}" >&2
  exit 1
fi

echo "Validating image availability for blueprint: $BLUEPRINT_NAME"
echo "  distro: $DISTRO"
echo "  image-type: $IMAGE_TYPE"
echo "  arch: $ARCH"

# Check if image exists using image-builder list with filters
LIST_OUTPUT=`$IMAGE_BUILDER_CMD list \
  --filter "distro:$DISTRO" \
  --filter "arch:$ARCH" \
  --filter "type:$IMAGE_TYPE" \
  --format json 2>&1`

# Check if the command succeeded and returned results
if [ $? -ne 0 ]; then
  echo "Error: Failed to query $IMAGE_BUILDER_CMD list" >&2
  echo "$LIST_OUTPUT" >&2
  exit 1
fi

# Check if any results were returned (non-empty JSON array)
# Remove whitespace and check if it's not just "[]" or "null"
LIST_CLEAN="$(echo "$LIST_OUTPUT" | tr -d '[:space:]')"

# Check if the output is a valid non-empty JSON array (starts with [ and contains at least one object)
if [ "$LIST_CLEAN" != "[]" ] && [ "$LIST_CLEAN" != "null" ] && [ -n "$LIST_CLEAN" ] && [[ "$LIST_CLEAN" =~ ^\[.*\]$ ]]; then
  echo "✓ Image is available: $DISTRO/$ARCH/$IMAGE_TYPE"
  exit 0
else
  echo "✗ Image is NOT available: $DISTRO/$ARCH/$IMAGE_TYPE" >&2
  echo "  The specified image type may not be supported for this distribution/architecture combination." >&2
  exit 1
fi
