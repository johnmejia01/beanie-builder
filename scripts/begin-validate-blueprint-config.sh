#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [OPTIONS]" >&2
  echo "Options:" >&2
  echo "  --blueprint-name NAME        Blueprint name (e.g., mobile_workstation_nvidia)" >&2
  echo "  --config-root DIR            Root directory for config files (default: blueprint-config)" >&2
  exit 1
}

BLUEPRINT_NAME=""
CONFIG_ROOT="blueprint-config"

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

# Get the root directory (parent of scripts)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATE_BLUEPRINT_CONFIG_SCRIPT="$ROOT_DIR/scripts/validate-blueprint-config.sh"

#Check if the operating system is Fedora, CentOS, or other Red Hat-based distribution
if [ -f /etc/redhat-release ]; then
  #Call the validate-blueprint-config script
  "$VALIDATE_BLUEPRINT_CONFIG_SCRIPT" --blueprint-name "$BLUEPRINT_NAME" --config-root "$CONFIG_ROOT" --image-builder-cmd "image-builder"
else
  #Call the validate-blueprint-config script using podman
  "$VALIDATE_BLUEPRINT_CONFIG_SCRIPT" --blueprint-name "$BLUEPRINT_NAME" --config-root "$CONFIG_ROOT" --image-builder-cmd "podman run ghcr.io/osbuild/image-builder-cli:latest"
fi

exit 0