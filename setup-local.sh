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
            just \
            bats \
            podman
        
        # Install mise
        sudo dnf copr enable jdxcode/mise
        sudo dnf install mise -y
    
    # Check in the /etc/os-release and if the value of ID_LIKE key contains Debian or Ubuntu
    elif [ -f /etc/os-release ]; then
        # Source the os-release file to get ID_LIKE
        . /etc/os-release
        # Check if ID_LIKE contains "debian" or "ubuntu" (case-insensitive)
        if [[ "${ID_LIKE,,}" == *"debian"* ]] || [[ "${ID_LIKE,,}" == *"ubuntu"* ]]; then
            # Core build tools for Debian/Ubuntu-based distributions
            sudo apt-get update
            sudo apt-get install -y \
                qemu-utils \
                qemu-kvm \
                qemu-system-x86 \
                libvirt-daemon-system \
                libvirt-clients \
                virt-manager \
                jq \
                yq \
                python3-pip \
                zstd \
                podman \
                just \
                bats
            
            # Install mise (if available in repos, otherwise may need manual installation)
            # Note: mise may need to be installed via other means on Debian/Ubuntu
            if command -v mise &> /dev/null; then
                echo "mise is already installed"
            else
                # Check the architecture and install the appropriate mise package
                if [ "$(uname -m)" == "x86_64" ]; then
                    sudo apt update -y && sudo apt install -y curl
                    sudo install -dm 755 /etc/apt/keyrings
                    curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.pub 1> /dev/null
                    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.pub arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
                    sudo apt update -y
                    sudo apt install -y mise
                elif [ "$(uname -m)" == "aarch64" ]; then
                    sudo apt update -y && sudo apt install -y curl
                    sudo install -dm 755 /etc/apt/keyrings
                    curl -fSs https://mise.jdx.dev/gpg-key.pub | sudo tee /etc/apt/keyrings/mise-archive-keyring.pub 1> /dev/null
                    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.pub arch=arm64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
                    sudo apt update -y
                    sudo apt install -y mise
                else
                    echo "Error: Unsupported architecture: $(uname -m)"
                    exit 1
                fi
            fi

        else
            echo "Error: Beanie Builder is only supported on Fedora, CentOS, or other Red Hat-based distribution, or Debian/Ubuntu-based distributions"
            exit 1
        fi
    else
        echo "Error: Beanie Builder is only supported on Fedora, CentOS, or other Red Hat-based distribution, or Debian/Ubuntu-based distributions"
        exit 1
    fi
else
    echo "Error: Beanie Builder is only supported on Linux"
    exit 1
fi

# Install python using mise
mise install python
mise use python

eval "$(mise activate bash)"

#Verify that python is referenced from the mise-managed path
if [ "$(which python)" != "$(mise which python)" ]; then
    echo "Error: python is not referenced from the mise-managed path"
    exit 1
fi

#Install tomlq and pykickstart using pip
pip install tomlq pykickstart

echo ""
echo "Setup complete! You can now build Linux OS Images."
echo "Run 'just build' to start building your custom OS image."
exit 0