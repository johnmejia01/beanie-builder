#! /bin/bash

echo "Installing dependencies for Sealight..."

# Core build tools
sudo dnf install -y \
    qemu-img \
    qemu-kvm \
    qemu-system-x86 \
    libvirt \
    virt-manager \
    jq \
    yq \
    image-builder \
    edk2-ovmf \
    python3-pip \
    zstd \
    pykickstart \
    just

# Install tomlq
pip install tomlq

# Install mise
sudo dnf copr enable jdxcode/mise
sudo dnf install mise -y

echo ""
echo "Setup complete! You can now build Linux OS Images."
echo "Run 'make build' to start building your custom OS image."
exit 0