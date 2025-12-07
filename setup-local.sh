#! /bin/bash

echo "Installing dependencies for Beanie Builder..."

# Check if the host OS is Linux 
if [ "$(uname -s)" == "Linux" ]; then
    # Check if the host OS is Fedora, CentOS, or other Red Hat-based distribution
    if [ -f /etc/redhat-release ]; then
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
            just \
            bats
        
        # Install mise
        sudo dnf copr enable jdxcode/mise
        sudo dnf install mise -y
    
    else
        echo "Error: Beanie Builder is only supported on Fedora, CentOS, or other Red Hat-based distribution"
        exit 1
    fi
else
    echo "Error: Beanie Builder is only supported on Linux"
    exit 1
fi

# Install tomlq
pip install tomlq

echo ""
echo "Setup complete! You can now build Linux OS Images."
echo "Run 'make build' to start building your custom OS image."
exit 0