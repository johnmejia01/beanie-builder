# Changelog

All notable changes to this project will be documented in this file.

This project follows the principles of
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v0.1.0-alpha.3] - 2025-12-28

### Added
- Implementation of a unit test framework using BATS with the following unit tests implemented for each bash script:
    - test_begin_build_image.bats (for `begin-build-image.sh`)
        - begin-build-image: requires --blueprint-dir argument
        - begin-build-image: fails when blueprint directory does not exist
        - begin-build-image: fails when blueprint file does not exist
        - begin-build-image: fails when mise.toml does not exist
        -  begin-build-image: fails when mise command is not available (skipped: mise is available, cannot test missing dependency)
        - begin-build-image: validates blueprint file name matches directory name
        - begin-build-image: calls build-image.sh with correct parameters
        - begin-build-image: passes correct blueprint file path to build-image.sh
        - begin-build-image: handles blueprint directory with special characters in name
    - test_build_image.bats (for `build-image.sh`)
        - build-image: requires all required parameters
        - build-image: fails when --base-image is missing
        - build-image: fails when --blueprint is missing
        - build-image: fails when --output-dir is missing
        - build-image: fails when --cache-dir is missing
        - build-image: fails when --arch is missing
        - build-image: fails when --distro is missing
        - build-image: fails when --image-name is missing
        - build-image: fails with unknown option
        - build-image: uses default image-builder-cmd when not specified (skipped: image-builder is available, would require sudo mocking)
        - build-image: accepts custom image-builder-cmd (skipped: Requires sudo mocking to test fully)
        - build-image: decompresses minimal-raw-zst image type (skipped: Requires sudo and image-builder mocking to test fully)
        - build-image: does not decompress non-zst image types (skipped: Requires full execution mocking)
        - build-image: validates all required parameters are present (skipped: image-builder is available, skipping to avoid actual execution)
        - build-image: handles relative and absolute paths correctly (skipped: image-builder is available, skipping to avoid actual execution)
    - test_clean.bats (for `clean.sh`)
        - clean: requires --blueprint and --output-dir arguments
        - clean: removes contents of blueprint build directory
        - clean: fails when blueprint directory does not exist
        - clean: only removes contents of specified blueprint directory
        - clean: preserves cache directory
    - test_create_blueprint.bats (for `create_blueprint.sh`)
        - create-blueprint: requires --blueprint-name argument
        - create-blueprint: creates blueprint structure with valid name
        - create-blueprint: creates empty blueprint TOML file
        - create-blueprint: creates empty blueprint config YAML file
        - create-blueprint: handles blueprint name with special characters
        - create-blueprint: creates directories even if they already exist
        - create-blueprint: fails with invalid option
    - test_prepare_blueprint.bats (for `prepare_blueprint.sh`)
        - prepare-blueprint: requires blueprint path argument
        - prepare-blueprint: fails when blueprint file does not exist
        - prepare-blueprint: fails when tomlq is not available (skipped: tomlq is available, cannot test missing dependency)
        - prepare-blueprint: fails when yq is not available (skipped: yq is available, cannot test missing dependency)
        - prepare-blueprint: creates prepared blueprint in build directory
        - prepare-blueprint: includes services from blueprint-services directory
        - prepare-blueprint: includes kickstart for installer image types
        - prepare-blueprint: includes services from blueprint-services/all directory
        - prepare-blueprint: preserves original blueprint packages
    - test_prepare_blueprint_config.bats (for `prepare_blueprint_config.sh`)
        - prepare-blueprint-config: requires --blueprint-name argument
        - prepare-blueprint-config: creates mise.toml in build directory
        - prepare-blueprint-config: includes distro in mise.toml
        - prepare-blueprint-config: includes image-type in mise.toml
        - prepare-blueprint-config: includes arch in mise.toml
        - prepare-blueprint-config: fails when config file does not exist
        - prepare-blueprint-config: uses custom config-root directory
        - prepare-blueprint-config: fails when yq is not available (skipped: yq is available, cannot test missing dependency)
    - test_validate_blueprint_config.bats (for `validate_blueprint_config.sh`)
        - validate-blueprint-config: requires --blueprint-name argument
        - validate-blueprint-config: fails when config file does not exist
        - validate-blueprint-config: fails when config file is missing required fields (image-type)
        - validate-blueprint-config: fails when distro field is missing
        - validate-blueprint-config: fails when arch field is missing
        - validate-blueprint-config: validates complete config file structure
        - validate-blueprint-config: uses custom config-root directory
        - validate-blueprint-config: checks for yq command (skipped: yq is available, cannot test missing dependency)
    - test_validate_kickstarts.bats (for `validate_kickstarts.sh`)
        - validate-kickstarts: requires --blueprint-path argument
        - validate-kickstarts: validates valid kickstart file
        - validate-kickstarts: handles missing kickstart file gracefully
        - validate-kickstarts: validates global kickstart file
        - validate-kickstarts: fails when ksvalidator is not available (skipped: ksvalidator is available, cannot test missing dependency)
        - validate-kickstarts: fails when blueprint-specific kickstart file is invalid
        - validate-kickstarts: fails when blueprint-specific kickstart has syntax error
        - validate-kickstarts: fails when global kickstart file is invalid
        - validate-kickstarts: fails when global kickstart has syntax error
        - validate-kickstarts: fails on global kickstart first when both are invalid

---

## [0.1.0-alpha.1] - 2025-12-05

### Added
- Initial implementation of **beanie-builder**
    - Added core bash scripts for pre-build, build, and run workflows of the OS image.
    - Added basic configuration and execution flow
        - OS image is configurable through creating a blueprint by running `just create-blueprint <blueprint-name>`. This will 
        - Execution flow was implemented using a Justfile and can be triggered locally via running `just` command. Running `just` command was output the list of available commands.
    - Added `setup.local.sh` script to automate on setting up the dev environment for local machine.
    - Added README.md documentation.
    - Added LICENSE file

---