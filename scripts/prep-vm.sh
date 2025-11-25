#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [OPTIONS]" >&2
  echo "Options:" >&2
  echo "  --blueprint-dir DIR        Directory containing prepared blueprint files (e.g., build/<blueprint-name>)" >&2
  echo "  --mem-size SIZE              Memory size (e.g., 8G)" >&2
  echo "  --smp-count COUNT            Number of CPU cores" >&2
  echo "  --pflash-path PATH           Path to OVMF firmware" >&2
  echo "  --disk-size SIZE             Size of the disk (e.g., 10G)" >&2
  exit 1
}

BLUEPRINT_DIR=""
MEM_SIZE="8G"
SMP_COUNT="2"
PFLASH_PATH="/usr/share/edk2/ovmf/OVMF_CODE.fd"
DISK_SIZE="15G"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --blueprint-dir)
            BLUEPRINT_DIR="$2"
            shift 2
            ;;
        --mem-size)
            MEM_SIZE="$2"
            shift 2
            ;;
        --smp-count)
            SMP_COUNT="$2"
            shift 2
            ;;
        --pflash-path)
            PFLASH_PATH="$2"
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

# Load environment variables from mise.toml in the blueprint directory
# Temporarily disable 'set -u' to avoid errors with unbound variables
set +u
cd "$BLUEPRINT_DIR"
eval "$(mise env)"
cd - > /dev/null
set -u

#Check if the image type contains installer or not
if [[ "$IMAGE_TYPE" == *"installer"* ]]; then
    #Check if the raw image file exists, if not create it
    if [ ! -f "$BLUEPRINT_DIR/os.raw" ]; then
        qemu-img create -f raw "$BLUEPRINT_DIR/os.raw" "$DISK_SIZE"
    fi
fi

#Update the mise.toml
mise set --file="$BLUEPRINT_DIR/mise.toml" \
    MEM_SIZE="$MEM_SIZE" \
    SMP_COUNT="$SMP_COUNT" \
    PFLASH_PATH="$PFLASH_PATH" \
    DISK_SIZE="$DISK_SIZE"

exit 0