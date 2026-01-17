#!/usr/bin/env bash

set -euo pipefail
eval "$(mise activate bash)"

usage() {
  echo "Usage: $0 [OPTIONS]" >&2
  echo "Options:" >&2
  echo "  --blueprint-path PATH       Path to blueprint file (e.g., blueprints/workstation.toml)" >&2
  echo "  --kickstart-root DIR        Root directory for kickstart files (default: blueprint-kickstarts)" >&2
  exit 1
}

BLUEPRINT_PATH=""
KICKSTART_ROOT="blueprint-kickstarts"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --blueprint-path)
      BLUEPRINT_PATH="$2"
      shift 2
      ;;
    --kickstart-root)
      KICKSTART_ROOT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

# Validate required parameters
if [ -z "$BLUEPRINT_PATH" ]; then
  echo "Error: Missing required parameter --blueprint-path" >&2
  usage
fi

# Check if ksvalidator is available
if ! command -v ksvalidator >/dev/null 2>&1; then
  echo "Error: ksvalidator is required but not installed." >&2
  echo "Install it with: sudo dnf install pykickstart" >&2
  exit 1
fi

# Extract blueprint name from path (e.g., "workstation" from "blueprints/workstation.toml")
BLUEPRINT_BASENAME="$(basename "$BLUEPRINT_PATH")"
BLUEPRINT_NAME="${BLUEPRINT_BASENAME%.toml}"

# Paths to kickstart files
GLOBAL_KS="$KICKSTART_ROOT/all/global.ks"
BLUEPRINT_KS="$KICKSTART_ROOT/$BLUEPRINT_NAME/kickstart.ks"

# Validate global.ks first
if [ ! -f "$GLOBAL_KS" ]; then
  echo "Warning: Global kickstart file not found: $GLOBAL_KS" >&2
  echo "Skipping global kickstart validation..." >&2
else
  echo "Validating global kickstart: $GLOBAL_KS"
  if ksvalidator "$GLOBAL_KS"; then
    echo "✓ Global kickstart validation passed"
  else
    echo "✗ Global kickstart validation failed" >&2
    exit 1
  fi
fi

# Validate blueprint-specific kickstart.ks
if [ ! -f "$BLUEPRINT_KS" ]; then
  echo "Warning: Blueprint-specific kickstart file not found: $BLUEPRINT_KS" >&2
  echo "Skipping blueprint-specific kickstart validation..." >&2
  exit 0
fi

echo "Validating blueprint-specific kickstart: $BLUEPRINT_KS"
if ksvalidator "$BLUEPRINT_KS"; then
  echo "✓ Blueprint-specific kickstart validation passed"
else
  echo "✗ Blueprint-specific kickstart validation failed" >&2
  exit 1
fi

echo ""
echo "All kickstart files validated successfully!"
exit 0
