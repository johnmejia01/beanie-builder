#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [OPTIONS]" >&2
  echo "Options:" >&2
  echo "  --blueprint-name NAME    Name of the blueprint" >&2
  echo "  --config-root DIR        Root directory for config files" >&2
  exit 1
}

BLUEPRINT_NAME=""
CONFIG_ROOT=""

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
    *)
      usage
      ;;
  esac
done

# Validate required parameters
if [ -z "$BLUEPRINT_NAME" ] || [ -z "$CONFIG_ROOT" ]; then
  echo "Error: Missing required parameters" >&2
  usage
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "Error: yq is required but not installed." >&2
  exit 1
fi

# Get the root directory (parent of scripts)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/build"
BLUEPRINT_CONFIG_FILE="$ROOT_DIR/$CONFIG_ROOT/$BLUEPRINT_NAME.yaml"
OUTPUT_PATH="$OUTPUT_DIR/$BLUEPRINT_NAME/mise.toml"

# Validate config file exists
if [ ! -f "$BLUEPRINT_CONFIG_FILE" ]; then
  echo "Error: Blueprint config file not found: $BLUEPRINT_CONFIG_FILE" >&2
  exit 1
fi

# Read values from YAML config
DISTRO="$(yq -r '.distro // ""' "$BLUEPRINT_CONFIG_FILE" 2>/dev/null || echo "")"
IMAGE_TYPE="$(yq -r '.["image-type"] // ""' "$BLUEPRINT_CONFIG_FILE" 2>/dev/null || echo "")"
ARCH="$(yq -r '.arch // ""' "$BLUEPRINT_CONFIG_FILE" 2>/dev/null || echo "")"

# Validate required values
if [ -z "$DISTRO" ] || [ -z "$IMAGE_TYPE" ] || [ -z "$ARCH" ]; then
  echo "Error: Missing required values in config file. Required: distro, image-type, arch" >&2
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Create mise.toml file
mise set --file="$OUTPUT_PATH" \
    DISTRO="$DISTRO" \
    IMAGE_TYPE="$IMAGE_TYPE" \
    ARCH="$ARCH"

#Check if the mise.toml file was created
if [ ! -f "$OUTPUT_PATH" ]; then
    echo "Error: Failed to create mise.toml file at $OUTPUT_PATH" >&2
    exit 1
else
    echo "Created mise.toml at $OUTPUT_PATH"
    echo "  DISTRO = $DISTRO"
    echo "  IMAGE_TYPE = $IMAGE_TYPE"
    echo "  ARCH = $ARCH"
fi

exit 0