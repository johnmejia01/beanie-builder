#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [OPTIONS]" >&2
  echo "Options:" >&2
  echo "  --output-dir DIR        Directory containing prepared blueprint files (e.g., build/<blueprint-name>)" >&2
  echo "  --blueprint NAME        Name of the blueprint to clean" >&2
  exit 1
}

OUTPUT_DIR=""
BLUEPRINT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --blueprint)
            BLUEPRINT="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "$OUTPUT_DIR" ]; then
    echo "Error: Missing required parameters" >&2
    usage
fi

if [ -z "$BLUEPRINT" ]; then
    echo "Error: Missing required parameters" >&2
    usage
fi

if [ ! -d "$OUTPUT_DIR/$BLUEPRINT" ]; then
    echo "Error: Output directory $OUTPUT_DIR/$BLUEPRINT does not exist" >&2
    exit 1
fi

# Clean the build
# Remove all files and directories in the blueprint output directory
rm -rf "$OUTPUT_DIR/$BLUEPRINT"/*

echo "Cleaned $BLUEPRINT in $OUTPUT_DIR"

exit 0