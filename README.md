# Beanie Builder

Beanie Builder is a tool for building custom OS images using [OSBuild](https://www.osbuild.org/). It provides a streamlined workflow for creating customized Fedora/RHEL-based images with packages, systemd services, kickstart configurations, and more.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Creating a Blueprint](#creating-a-blueprint)
- [Blueprint Structure](#blueprint-structure)
- [Building Images](#building-images)
- [Workflow Commands](#workflow-commands)
- [Documentation References](#documentation-references)

## Prerequisites

- Fedora or RHEL-based Linux distribution
- sudo/root access for installing dependencies
- `just` command runner (installed during setup)

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd beanie-builder
   ```

2. Install dependencies:
   ```bash
   ./setup-local.sh
   ```

This will install:
- `image-builder` (OSBuild tool)
- `qemu-kvm` and virtualization tools
- `yq`, `jq`, `tomlq` (for configuration processing)
- `just` (command runner)
- `mise` (environment manager)
- `pykickstart` (kickstart validation)

## Getting Started

The basic workflow for building a custom OS image:

1. **Create a blueprint** - Define your custom image configuration
2. **Configure build settings** - Set distribution, architecture, and image type
3. **Build the image** - Compile your blueprint into an OS image

### Quick Example

```bash
# Create a new blueprint
just create-blueprint my-custom-image

# Build the image
just build my-custom-image
```

## Creating a Blueprint

A blueprint defines what packages, customizations, and configurations should be included in your OS image.

### Step 1: Create the Blueprint Structure

```bash
just create-blueprint my-workstation
```

This creates the following structure:
```
blueprints/
  └── my-workstation.toml
blueprint-config/
  └── my-workstation.yaml
blueprint-kickstarts/
  └── my-workstation/
      └── kickstart.ks
blueprint-services/
  └── my-workstation/
```

### Step 2: Configure Build Settings

Edit `blueprint-config/my-workstation.yaml`:

```yaml
distro: fedora-43
image-type: minimal-installer
arch: x86_64
```

**Available image types:**
- `minimal-installer` - Installation ISO
- `raw` - Raw disk image
- `qcow2` - QEMU disk image
- `ami` - Amazon Machine Image
- And more (see [OSBuild documentation](https://osbuild.org/docs/user-guide/image-descriptions/fedora-43))

### Step 3: Define Your Blueprint

Edit `blueprints/my-workstation.toml`:

```toml
# Define packages to install
[[packages]]
name = "kernel"
version = "6.17*"

[[packages]]
name = "firefox"
version = "*"

[[packages]]
name = "vim"
version = "*"

# System customizations
[customizations.timezone]
timezone = "America/New_York"

[customizations.locale]
languages = ["en_US.UTF-8"]
keyboard = "us"

# User creation
[[customizations.user]]
name = "admin"
password = "$6$encrypted_password_hash"
groups = ["wheel"]
```

### Step 4: Add Systemd Services (Optional)

Create service files in `blueprint-services/my-workstation/`:

**Example: `blueprint-services/my-workstation/my-service/my-service.service`**
```ini
[Unit]
Description=My Custom Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/my-script.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

**Example: `blueprint-services/my-workstation/my-service/my-script.sh`**
```bash
#!/bin/bash
echo "Hello from custom service!"
```

The prepare script will automatically:
- Copy service files to `/etc/systemd/system/`
- Copy scripts to `/usr/local/sbin/` or `/usr/local/bin/`
- Enable the services

### Step 5: Add Kickstart Configuration (For Installer Images)

If your image type includes `installer`, you can customize the installation process.

Edit `blueprint-kickstarts/my-workstation/kickstart.ks`:

```bash
# Kickstart file for my-workstation blueprint

# Unattended installation settings
#graphical
#lang en_US.UTF-8
#keyboard us
#timezone America/New_York
#network --bootproto=dhcp --device=link --activate
#firewall --enabled
#selinux --enforcing

# Post-installation script
%post --nochroot --log=/mnt/sysimage/root/ks-post.log

# Customize MOTD
echo "Welcome to My Custom Workstation!" | tee -a /mnt/sysroot/etc/motd

# Install additional software
# dnf install -y --installroot=/mnt/sysroot my-custom-package

%end
```

**Note:** Global kickstart files in `blueprint-kickstarts/all/global.ks` are automatically prepended to blueprint-specific kickstart files.

## Blueprint Structure

### Package Definitions

```toml
[[packages]]
name = "package-name"
version = "*"  # or specific version like "1.2.3" or "1.2*"
```

### Customizations

```toml
# Timezone
[customizations.timezone]
timezone = "America/New_York"

# Locale
[customizations.locale]
languages = ["en_US.UTF-8"]
keyboard = "us"

# Users
[[customizations.user]]
name = "username"
password = "$6$encrypted_hash"
groups = ["wheel"]
ssh_key = "ssh-rsa AAAAB3NzaC1yc2E..."
```

### Files

Files can be added directly in the blueprint (automatically handled by the prepare script):

```toml
[[customizations.files]]
path = "/etc/motd"
mode = "0644"
data = "Welcome message"
```

## Building Images

### Full Build Workflow

```bash
# This runs all preparation steps and builds the image
just build my-workstation
```

The build process:
1. Validates blueprint configuration
2. Validates kickstart files (if applicable)
3. Prepares the blueprint (combines services, kickstart, etc.)
4. Prepares blueprint config (creates mise.toml)
5. Builds the image using OSBuild

### Individual Steps

```bash
# Validate configuration
just validate-blueprint-config my-workstation

# Validate kickstart files
just validate-kickstarts my-workstation

# Prepare blueprint (combine services, kickstart, etc.)
just prepare-blueprint my-workstation

# Prepare blueprint config
just prepare-blueprint-config my-workstation

# Build the image
just build-image my-workstation
```

### Output

Built images are located in:
```
build/my-workstation/
  ├── my-workstation.toml  # Prepared blueprint
  ├── my-workstation.iso    # (for installer images)
  └── mise.toml             # Environment configuration
```

### Running the Image

For installer images:
```bash
just run-image my-workstation
```

This will launch QEMU with the installer ISO.

## Workflow Commands

| Command | Description |
|---------|-------------|
| `just create-blueprint <name>` | Create a new blueprint structure |
| `just validate-blueprint-config <name>` | Validate blueprint configuration |
| `just validate-kickstarts <name>` | Validate kickstart files |
| `just prepare-blueprint <name>` | Prepare blueprint (combine assets) |
| `just prepare-blueprint-config <name>` | Prepare blueprint config |
| `just pre-build <name>` | Run all validation and preparation steps |
| `just build-image <name>` | Build the OS image |
| `just build <name>` | Full workflow: pre-build + build-image |
| `just clean <name>` | Clean build artifacts |
| `just run-image <name>` | Run the image in QEMU |

## Documentation References

### OSBuild Blueprint Reference

For complete blueprint syntax and available customizations, refer to the official OSBuild documentation:

- **OSBuild Homepage**: https://www.osbuild.org/
- **User Guide**: https://www.osbuild.org/guides/user-guide/
- **Creating Custom Images**: https://www.osbuild.org/guides/user-guide/creating-custom-images.html
- **Blueprint Schema Reference**: https://osbuild.org/schemas/
- **Customizations Reference**: https://www.osbuild.org/guides/user-guide/customizations.html

### Kickstart Documentation

For kickstart file syntax and options:

- **Fedora Kickstart Documentation**: https://docs.fedoraproject.org/en-US/fedora/latest/install-guide/advanced/Kickstart_Installations/
- **RHEL Kickstart Documentation**: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/performing_an_advanced_rhel_installation/kickstart-syntax-reference_installing-rhel-as-an-experienced-user
- **Kickstart Options Reference (pykickstart)**: https://pykickstart.readthedocs.io/en/latest/kickstart-docs.html

## Example: Complete Blueprint

Here's a complete example blueprint for a development workstation:

**`blueprints/dev-workstation.toml`**
```toml
# Development tools
[[packages]]
name = "git"
version = "*"

[[packages]]
name = "vim"
version = "*"

[[packages]]
name = "gcc"
version = "*"

[[packages]]
name = "make"
version = "*"

# System configuration
[customizations.timezone]
timezone = "UTC"

[customizations.locale]
languages = ["en_US.UTF-8"]
keyboard = "us"

# Create developer user
[[customizations.user]]
name = "developer"
password = "$6$rounds=656000$..."  # Use mkpasswd or similar
groups = ["wheel", "docker"]
ssh_key = "ssh-rsa AAAAB3NzaC1yc2E... developer@example.com"
```

**`blueprint-config/dev-workstation.yaml`**
```yaml
distro: fedora-43
image-type: qcow2
arch: x86_64
```

Build it:
```bash
just build dev-workstation
```

## Troubleshooting

### Build Fails

- Check that all required packages exist in the repository
- Verify blueprint syntax with `just validate-blueprint-config <name>`
- Check kickstart syntax with `just validate-kickstarts <name>`

### Services Not Starting

- Ensure service files are in `blueprint-services/<blueprint-name>/<service-name>/`
- Verify service file syntax
- Check that scripts have execute permissions (0755)

### Kickstart Not Applied

- Ensure image type includes `installer` in the config YAML
- Verify kickstart syntax is valid
- Check that kickstart file is in `blueprint-kickstarts/<blueprint-name>/kickstart.ks`

## License

See [LICENSE](LICENSE) file for details.

