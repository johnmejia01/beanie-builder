#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [OPTIONS]" >&2
  echo "Options:" >&2
  echo "  --blueprint-name NAME        Name of the blueprint to create" >&2
  exit 1
}

BLUEPRINT_NAME=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --blueprint-name)
            BLUEPRINT_NAME="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "$BLUEPRINT_NAME" ]; then
    echo "Error: Missing required parameters" >&2
    usage
fi

# Create the blueprint directory
mkdir -p "blueprints"

# Create the blueprint toml file
touch "blueprints/$BLUEPRINT_NAME.toml"

# Create the blueprint YAML config file
touch "blueprint-config/$BLUEPRINT_NAME.yaml"

# Create the blueprint kickstarts directory
mkdir -p "blueprint-kickstarts/$BLUEPRINT_NAME"
mkdir -p "blueprint-kickstarts/all"

# Create the blueprint services directory
mkdir -p "blueprint-services/$BLUEPRINT_NAME"
mkdir -p "blueprint-services/all"

echo "Blueprint $BLUEPRINT_NAME created"

exit 0