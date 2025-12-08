# Beanie Builder Tests

This directory contains Bats (Bash Automated Testing System) tests for the Beanie Builder project.

## Prerequisites

Install Bats and required dependencies:

```bash
# Install Bats
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local

# Install Bats helper libraries
git clone https://github.com/bats-core/bats-support.git tests/test_helper/bats-support
git clone https://github.com/bats-core/bats-assert.git tests/test_helper/bats-assert
git clone https://github.com/bats-core/bats-file.git tests/test_helper/bats-file
```

Or use your distribution's package manager if available.

## Running Tests

Run all tests:
```bash
bats tests/
```

Run a specific test file:
```bash
bats tests/test_create_blueprint.bats
```

Run with verbose output:
```bash
bats --verbose tests/
```

Run with tap output format:
```bash
bats --tap tests/
```

## Test Structure

- `test_helper.bash` - Common test helper functions and setup/teardown
- `test_create_blueprint.bats` - Tests for blueprint creation
- `test_validate_blueprint_config.bats` - Tests for blueprint config validation
- `test_prepare_blueprint.bats` - Tests for blueprint preparation
- `test_validate_kickstarts.bats` - Tests for kickstart validation
- `test_clean.bats` - Tests for cleanup functionality
- `test_prepare_blueprint_config.bats` - Tests for blueprint config preparation

## Writing New Tests

1. Create a new `.bats` file in the `tests/` directory
2. Load the test helper: `load test_helper`
3. Use Bats test functions:
   - `@test "description"` - Define a test case
   - `setup()` - Run before each test (already defined in test_helper)
   - `teardown()` - Run after each test (already defined in test_helper)
   - `run_script "script-name" args...` - Run a script and capture output
   - `assert_success` - Assert command succeeded
   - `assert_failure` - Assert command failed
   - `assert_output` - Assert output contains text

Example:
```bash
#!/usr/bin/env bats

load test_helper

@test "my-script: does something" {
  run_script "my-script.sh" --arg "value"
  assert_success
  assert_output --partial "expected output"
}
```

## Test Helpers

The `test_helper.bash` provides several helper functions:

- `run_script script_name args...` - Run a script from the scripts directory
- `create_test_blueprint_config name distro image_type arch` - Create a test blueprint config
- `create_test_blueprint_toml name` - Create a test blueprint TOML file
- `create_test_kickstart name` - Create a test kickstart file
- `create_test_service name service_name` - Create a test systemd service
- `get_script_path script_name` - Get the path to a script

## Notes

- Tests run in isolated temporary directories
- Each test gets a fresh environment
- Tests may skip if required external tools are not available (e.g., `image-builder`, `yq`, `tomlq`)
- Some tests require actual tools to be installed to fully validate functionality

