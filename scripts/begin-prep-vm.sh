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

if [ -z "$BLUEPRINT_DIR" ]; then
  echo "Error: Missing required parameters" >&2
  usage
fi

if [ ! -d "$BLUEPRINT_DIR" ]; then
  echo "Error: Blueprint directory $BLUEPRINT_DIR does not exist" >&2
  exit 1
fi

# Get the root directory (parent of scripts)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREP_VM_SCRIPT="$ROOT_DIR/scripts/prep-vm.sh"

# Check if the host OS is Linux 
if [ "$(uname -s)" == "Linux" ]; then
    # Check if the host OS is Fedora, CentOS, or other Red Hat-based distribution
    if [ -f /etc/redhat-release ]; then
        # Call the prep-vm script
        "$PREP_VM_SCRIPT" --blueprint-dir "$BLUEPRINT_DIR"
    else
        "$PREP_VM_SCRIPT" --blueprint-dir "$BLUEPRINT_DIR" --pflash-path "/usr/share/ovmf/OVMF_CODE.fd"
    fi
else
    echo "Error: Unsupported operating system"
    exit 1
fi