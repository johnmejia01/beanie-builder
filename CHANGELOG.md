# Changelog

All notable changes to this project will be documented in this file.

This project follows the principles of
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- 

### Changed
- 

### Fixed
- 

### Removed
- 

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