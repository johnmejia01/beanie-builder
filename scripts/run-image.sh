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

# Load environment variables from mise.toml in the blueprint directory
# Temporarily disable 'set -u' to avoid errors with unbound variables
set +u
cd "$BLUEPRINT_DIR"
eval "$(mise env)"
cd - > /dev/null
set -u

QEMU_CMD="qemu-system-$ARCH"

#Check if the ARCH is x86_64 or aarch64
if [ "$ARCH" == "x86_64" ]; then
    QEMU_CMD="qemu-system-$ARCH"
elif [ "$ARCH" == "aarch64" ]; then
    QEMU_CMD="qemu-system-$ARCH -machine virt"
else
    echo "Error: Unsupported architecture: $ARCH" >&2
    exit 1
fi

#Check if the image type contains installer, raw, or qcow2
if [[ "$IMAGE_TYPE" == *"installer"* ]]; then
    QEMU_CMD="$QEMU_CMD \
        -enable-kvm \
        -cpu host \
        -object iothread,id=io1 \
        -m $MEM_SIZE \
        -smp $SMP_COUNT \
        -pflash $PFLASH_PATH \
        -cdrom $BLUEPRINT_DIR/$(basename "$BLUEPRINT_DIR").iso \
        -hda $BLUEPRINT_DIR/os.raw \
        "
elif [[ "$IMAGE_TYPE" == *"raw"* ]]; then
    QEMU_CMD="$QEMU_CMD \
        -enable-kvm \
        -object iothread,id=io1 \
        -m $MEM_SIZE \
        -smp $SMP_COUNT \
        -pflash $PFLASH_PATH \
        -drive format=raw,file=$BLUEPRINT_DIR/$(basename "$BLUEPRINT_DIR").raw,if=virtio,aio=threads \
        "
elif [[ "$IMAGE_TYPE" == *"qcow2"* ]]; then
    QEMU_CMD="$QEMU_CMD \
        -enable-kvm \
        -object iothread,id=io1 \
        -m $MEM_SIZE \
        -smp $SMP_COUNT \
        -pflash $PFLASH_PATH \
        -drive format=qcow2,file=$BLUEPRINT_DIR/$(basename "$BLUEPRINT_DIR").qcow2,if=virtio,aio=threads \
        "
else
    echo "Error: Unsupported image type: $IMAGE_TYPE" >&2
    exit 1
fi

#Run QEMU
sudo $QEMU_CMD

exit 0