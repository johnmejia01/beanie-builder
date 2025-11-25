#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [OPTIONS]" >&2
  echo "Options:" >&2
  echo "  --blueprint-dir DIR        Directory containing prepared blueprint files (e.g., build/<blueprint-name>)" >&2
  exit 1
}

BLUEPRINT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --blueprint-dir)
      BLUEPRINT_DIR="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

BLUEPRINT_FILE="$BLUEPRINT_DIR/$(basename $BLUEPRINT_DIR).toml"

# Validate required parameters
if [ -z "$BLUEPRINT_DIR" ]; then
  echo "Error: Missing required parameters" >&2
  usage
fi

# Check if the blueprint directory exists
if [ ! -d "$BLUEPRINT_DIR" ]; then
  echo "Error: Blueprint directory $BLUEPRINT_DIR does not exist" >&2
  exit 1
fi

# Check if the blueprint file exists
if [ ! -f "$BLUEPRINT_FILE" ]; then
  echo "Error: Blueprint file $BLUEPRINT_FILE does not exist" >&2
  exit 1
fi

#Check if the mise.toml file exists
if [ ! -f "$BLUEPRINT_DIR/mise.toml" ]; then
  echo "Error: mise.toml file $BLUEPRINT_DIR/mise.toml does not exist" >&2
  exit 1
fi

# Load environment variables from mise.toml in the blueprint directory
# Temporarily disable 'set -u' to avoid errors with unbound variables
set +u
cd "$BLUEPRINT_DIR"
eval "$(mise env)"
cd - > /dev/null
set -u

# Get the root directory (parent of scripts)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_IMAGE_SCRIPT="$ROOT_DIR/scripts/build-image.sh"

#Call the build-image script
"$BUILD_IMAGE_SCRIPT" --image-builder-cmd "image-builder" \
  --blueprint "$BLUEPRINT_FILE" \
  --output-dir "$BLUEPRINT_DIR" \
  --cache-dir "build/cache" \
  --arch "$ARCH" \
  --distro "$DISTRO" \
  --base-image "$IMAGE_TYPE" \
  --image-name "$(basename "$BLUEPRINT_DIR")"