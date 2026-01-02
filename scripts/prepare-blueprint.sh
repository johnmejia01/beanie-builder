#!/usr/bin/env bash

set -euo pipefail
eval "$(mise activate bash)"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <blueprint-path> [output-path]" >&2
  echo "  Note: output-path is ignored. Prepared blueprint is always created at: build/<blueprint-name>/<blueprint-name>.toml" >&2
  exit 1
fi

if ! command -v tomlq >/dev/null 2>&1; then
  echo "Error: tomlq is required but not installed. Install yq v4+ (provides tomlq)." >&2
  exit 1
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "Error: yq is required but not installed." >&2
  exit 1
fi

tomlq_cmd=(tomlq -t)

run_tomlq() {
  "${tomlq_cmd[@]}" "$@"
}

BLUEPRINT_SOURCE="$1"
ARCH_VALUE="${ARCH:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_ROOT="$ROOT_DIR/blueprint-services"
KICKSTART_ROOT="$ROOT_DIR/blueprint-kickstarts"
OUTPUT_DIR="$ROOT_DIR/build"
BLUEPRINT_CONFIG_DIR="$ROOT_DIR/blueprint-config"

BLUEPRINT_BASENAME="$(basename "$BLUEPRINT_SOURCE")"
BLUEPRINT_NAME="${BLUEPRINT_BASENAME%.toml}"

# Read IMAGE_TYPE_VALUE from blueprint config YAML file
BLUEPRINT_CONFIG_FILE="$BLUEPRINT_CONFIG_DIR/$BLUEPRINT_NAME.yaml"
if [ -f "$BLUEPRINT_CONFIG_FILE" ]; then
  IMAGE_TYPE_VALUE="$(yq -r '.["image-type"] // ""' "$BLUEPRINT_CONFIG_FILE" 2>/dev/null || echo "")"
  # Fallback to environment variable if YAML key is empty
  if [ -z "$IMAGE_TYPE_VALUE" ]; then
    IMAGE_TYPE_VALUE="${IMAGE_TYPE:-}"
  fi
else
  # Fallback to environment variable if config file doesn't exist
  IMAGE_TYPE_VALUE="${IMAGE_TYPE:-}"
fi

# Always construct output path as build/<blueprint-name>/<blueprint-name>.toml
OUTPUT_PATH="$OUTPUT_DIR/$BLUEPRINT_NAME/$BLUEPRINT_NAME.toml"

mkdir -p "$(dirname "$OUTPUT_PATH")"

# Remove existing output file if it exists to ensure fresh creation
[ -f "$OUTPUT_PATH" ] && rm -f "$OUTPUT_PATH"

TMPFILE="$(mktemp)"
trap 'rm -f "$TMPFILE"' EXIT

if [ -n "$ARCH_VALUE" ]; then
  sed "s/\\\$ARCH/$ARCH_VALUE/g" "$BLUEPRINT_SOURCE" > "$TMPFILE"
else
  cp "$BLUEPRINT_SOURCE" "$TMPFILE"
fi

# Initialize customizations structure
if [[ -n "$IMAGE_TYPE_VALUE" ]] && [[ "$IMAGE_TYPE_VALUE" == *"installer"* ]]; then
  run_tomlq -i '
    .customizations = (.customizations // {}) |
    .customizations.services = (.customizations.services // {}) |
    .customizations.files = (.customizations.files // []) |
    .customizations.installer = (.customizations.installer // {}) |
    .customizations.installer.kickstart = (.customizations.installer.kickstart // {})
  ' "$TMPFILE"
else
  run_tomlq -i '
    .customizations = (.customizations // {}) |
    .customizations.services = (.customizations.services // {}) |
    .customizations.files = (.customizations.files // [])
  ' "$TMPFILE"
fi

shopt -s nullglob

append_file() {
  local src="$1"
  local dest_path="$2"
  local mode="$3"
  local data

  data="$(cat "$src")"

  run_tomlq -i --arg path "$dest_path" --arg data "$data" --arg mode "$mode" '
    .customizations.files =
      (((.customizations.files // []) | map(select(.path != $path))) + [{path: $path, mode: $mode, data: $data}])
  ' "$TMPFILE"
}

enable_service() {
  local service_name="$1"

  run_tomlq -i --arg svc "$service_name" '
    .customizations.services.enabled =
      ((.customizations.services.enabled // []) | (if index($svc) == null then . + [$svc] else . end))
  ' "$TMPFILE"
}

process_asset_file() {
  local file="$1"
  local filename mode dest

  filename="$(basename "$file")"

  case "$filename" in
    *.service)
      dest="/etc/systemd/system/$filename"
      mode="0644"
      append_file "$file" "$dest" "$mode"
      enable_service "$filename"
      ;;
    *.sh)
      dest="/usr/local/sbin/$filename"
      mode="0755"
      append_file "$file" "$dest" "$mode"
      ;;
    *)
      return 0
      ;;
  esac
}

process_scope() {
  local scope="$1"

  [ -d "$scope" ] || return 0

  for bundle in "$scope"/*; do
    [ -d "$bundle" ] || continue
    for asset in "$bundle"/*; do
      [ -f "$asset" ] || continue
      process_asset_file "$asset"
    done
  done
}

process_scope "$SERVICE_ROOT/all"
process_scope "$SERVICE_ROOT/$BLUEPRINT_NAME"

# Append kickstart files if IMAGE_TYPE contains "installer"
if [[ -n "$IMAGE_TYPE_VALUE" ]] && [[ "$IMAGE_TYPE_VALUE" == *"installer"* ]]; then
  KICKSTART_CONTENT=""
  
  # Append global.ks first
  GLOBAL_KS="$KICKSTART_ROOT/all/global.ks"
  if [ -f "$GLOBAL_KS" ]; then
    echo "Appending global kickstart: $GLOBAL_KS"
    if [ -n "$KICKSTART_CONTENT" ]; then
      KICKSTART_CONTENT="$KICKSTART_CONTENT

$(cat "$GLOBAL_KS")"
    else
      KICKSTART_CONTENT="$(cat "$GLOBAL_KS")"
    fi
  fi
  
  # Append blueprint-specific kickstart.ks
  BLUEPRINT_KS="$KICKSTART_ROOT/$BLUEPRINT_NAME/kickstart.ks"
  if [ -f "$BLUEPRINT_KS" ]; then
    echo "Appending blueprint-specific kickstart: $BLUEPRINT_KS"
    if [ -n "$KICKSTART_CONTENT" ]; then
      KICKSTART_CONTENT="$KICKSTART_CONTENT

$(cat "$BLUEPRINT_KS")"
    else
      KICKSTART_CONTENT="$(cat "$BLUEPRINT_KS")"
    fi
  fi
  
  # Append combined kickstart content to blueprint if we have any
  if [ -n "$KICKSTART_CONTENT" ]; then
    # Get existing kickstart content if any
    existing_ks="$(run_tomlq -r '.customizations.installer.kickstart.contents // ""' "$TMPFILE" 2>/dev/null || echo "")"
    
    # Combine: existing + new content
    if [ -n "$existing_ks" ]; then
      KICKSTART_CONTENT="$existing_ks

$KICKSTART_CONTENT"
    fi
    
    # Append to blueprint
    run_tomlq -i --arg ks "$KICKSTART_CONTENT" '
      .customizations.installer.kickstart.contents = $ks
    ' "$TMPFILE"
  fi
fi

cp "$TMPFILE" "$OUTPUT_PATH"
trap - EXIT
rm -f "$TMPFILE"

