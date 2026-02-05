# Beanie Builder Justfile

# Variables
blueprint_config_dir := "blueprint-config"
prepare_blueprint_script := "scripts/prepare-blueprint.sh"
validate_kickstarts_script := "scripts/validate-kickstarts.sh"
prepare_blueprint_config_script := "scripts/prepare-blueprint-config.sh"
create_blueprint_script := "scripts/create-blueprint.sh"
begin_build_image_script := "scripts/begin-build-image.sh"
begin_validate_blueprint_config_script := "scripts/begin-validate-blueprint-config.sh"
clean_script := "scripts/clean.sh"
begin_prep_vm_script := "scripts/begin-prep-vm.sh"
run_image_script := "scripts/run-image.sh"

# Default recipe
default:
    @just --list

# Install required dependencies
install-deps:
    ./setup-local.sh

# Create a new blueprint
create-blueprint blueprint:
    #!/usr/bin/env bash
    {{create_blueprint_script}} --blueprint-name "{{blueprint}}"

# Validate the blueprint config
validate-blueprint-config blueprint:
    #!/usr/bin/env bash
    {{begin_validate_blueprint_config_script}} --blueprint-name "{{blueprint}}" --config-root {{blueprint_config_dir}}

# Validate the kickstart files
validate-kickstarts blueprint:
    #!/usr/bin/env bash
    blueprint_file="blueprints/{{blueprint}}.toml"
    {{validate_kickstarts_script}} --blueprint-path "$blueprint_file"

# Prepare the selected blueprint with shared assets
prepare-blueprint blueprint:
    #!/usr/bin/env bash
    blueprint_file="blueprints/{{blueprint}}.toml"
    {{prepare_blueprint_script}} "$blueprint_file"

# Prepare the blueprint config
prepare-blueprint-config blueprint:
    #!/usr/bin/env bash
    {{prepare_blueprint_config_script}} --blueprint-name "{{blueprint}}" --config-root {{blueprint_config_dir}}

# Pre-build actions
pre-build blueprint:
    @just validate-blueprint-config {{blueprint}}
    @just validate-kickstarts {{blueprint}}
    @just prepare-blueprint {{blueprint}}
    @just prepare-blueprint-config {{blueprint}}

# Build the image
build-image blueprint:
    #!/usr/bin/env bash
    {{begin_build_image_script}} --blueprint-dir "build/{{blueprint}}"

# Full build workflow (prepare + build image)
build blueprint:
    @just pre-build {{blueprint}}
    @just build-image {{blueprint}}

# Clean the build and output directory
clean blueprint:
    #!/usr/bin/env bash
    {{clean_script}} --output-dir "build" --blueprint "{{blueprint}}"

# Run the image
run-image blueprint:
    #!/usr/bin/env bash
    {{begin_prep_vm_script}} --blueprint-dir "build/{{blueprint}}"
    {{run_image_script}} --blueprint-dir "build/{{blueprint}}"

# Show help message
help:
    @echo "Beanie Builder Tool"
    @echo ""
    @echo "Usage: just <recipe> <blueprint-name>"
    @echo ""
    @just --list
    @echo ""
    @echo "Options:"
    @echo "  - blueprint: Name of the blueprint to build"
    @echo ""
    @echo "Examples:"
    @echo "  just create-blueprint workstation-blueprint"
    @echo "  just build workstation-blueprint"

