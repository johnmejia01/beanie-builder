#!/usr/bin/env bats
#
# Test helper functions for Beanie Builder tests
#

# Note: This test helper provides its own assertion functions
# If you have bats-assert, bats-support, and bats-file installed,
# you can uncomment the lines below to use them instead.
# Otherwise, the custom implementations below will be used.

# Uncomment to use external libraries (if installed):
# load 'test_helper/bats-support/load'
# load 'test_helper/bats-assert/load'
# load 'test_helper/bats-file/load'

# Test fixtures directory
FIXTURES_DIR="$BATS_TEST_DIRNAME/fixtures"

# Temporary test directory
TEST_TMPDIR=""

# Setup function run before each test
setup() {
  # Create a temporary directory for each test
  TEST_TMPDIR=$(mktemp -d)
  export TEST_TMPDIR

  # Save original directory
  ORIGINAL_DIR=$(pwd)

  # Create test directory structure
  mkdir -p "$TEST_TMPDIR/blueprints"
  mkdir -p "$TEST_TMPDIR/blueprint-config"
  mkdir -p "$TEST_TMPDIR/blueprint-kickstarts"
  mkdir -p "$TEST_TMPDIR/blueprint-services"
  mkdir -p "$TEST_TMPDIR/build"
  mkdir -p "$TEST_TMPDIR/scripts"

  # Copy scripts to test directory (if they exist)
  if [ -d "$BATS_TEST_DIRNAME/../scripts" ]; then
    cp -r "$BATS_TEST_DIRNAME/../scripts"/* "$TEST_TMPDIR/scripts/" 2>/dev/null || true
    # Make scripts executable
    chmod +x "$TEST_TMPDIR/scripts"/*.sh 2>/dev/null || true
  fi

  # Change to test directory
  cd "$TEST_TMPDIR" || exit 1
}

# Teardown function run after each test
teardown() {
  # Return to original directory
  cd "$ORIGINAL_DIR" || true

  # Clean up temporary directory
  if [ -n "$TEST_TMPDIR" ] && [ -d "$TEST_TMPDIR" ]; then
    rm -rf "$TEST_TMPDIR"
  fi
}

# Helper function to get script path
get_script_path() {
  local script_name="$1"
  echo "$TEST_TMPDIR/scripts/$script_name"
}

# Helper function to run script with arguments
run_script() {
  local script_name="$1"
  shift
  local script_path
  script_path=$(get_script_path "$script_name")
  run "$script_path" "$@"
}

# Helper function to create a test blueprint config
create_test_blueprint_config() {
  local blueprint_name="$1"
  local distro="${2:-fedora-43}"
  local image_type="${3:-minimal-installer}"
  local arch="${4:-x86_64}"

  cat > "blueprint-config/$blueprint_name.yaml" <<EOF
distro: $distro
image-type: $image_type
arch: $arch
EOF
}

# Helper function to create a test blueprint TOML
create_test_blueprint_toml() {
  local blueprint_name="$1"
  
  cat > "blueprints/$blueprint_name.toml" <<EOF
# Test blueprint
[[packages]]
name = "kernel"
version = "6.17*"

[customizations.timezone]
timezone = "UTC"

[customizations.locale]
languages = ["en_US.UTF-8"]
keyboard = "us"
EOF
}

# Helper function to create a test kickstart file
create_test_kickstart() {
  local blueprint_name="$1"
  mkdir -p "blueprint-kickstarts/$blueprint_name"
  
  cat > "blueprint-kickstarts/$blueprint_name/kickstart.ks" <<EOF
# Test kickstart file
%post --nochroot --log=/mnt/sysimage/root/ks-post.log
echo "Test kickstart executed"
%end
EOF
}

# Helper function to create a test service
create_test_service() {
  local blueprint_name="$1"
  local service_name="$2"
  mkdir -p "blueprint-services/$blueprint_name/$service_name"
  
  cat > "blueprint-services/$blueprint_name/$service_name/$service_name.service" <<EOF
[Unit]
Description=Test Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/$service_name.sh

[Install]
WantedBy=multi-user.target
EOF

  cat > "blueprint-services/$blueprint_name/$service_name/$service_name.sh" <<EOF
#!/bin/bash
echo "Test service script"
EOF
  chmod +x "blueprint-services/$blueprint_name/$service_name/$service_name.sh"
}

# Assertion helper functions
# These work without external bats-assert library

# Assert command succeeded
assert_success() {
  if [ "$status" -ne 0 ]; then
    {
      echo "Command failed with exit code $status"
      echo "Output: $output"
    } >&2
    return 1
  fi
}

# Assert command failed
assert_failure() {
  if [ "$status" -eq 0 ]; then
    {
      echo "Command succeeded but was expected to fail"
      echo "Output: $output"
    } >&2
    return 1
  fi
}

# Assert output contains text (supports --partial flag like bats-assert)
assert_output() {
  local partial=false
  local expected=""
  
  # Handle --partial flag
  if [ "$1" = "--partial" ]; then
    partial=true
    expected="$2"
  else
    expected="$1"
  fi
  
  # Always do partial match (substring check)
  if [[ "$output" != *"$expected"* ]]; then
    {
      echo "Expected output to contain: $expected"
      echo "Actual output: $output"
    } >&2
    return 1
  fi
}

# Assert file exists
assert_file_exist() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "File does not exist: $file"
    return 1
  fi
}

# Assert file does not exist
assert_file_not_exist() {
  local file="$1"
  if [ -f "$file" ]; then
    echo "File exists but should not: $file"
    return 1
  fi
}

# Assert file is empty
assert_file_empty() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "File does not exist: $file"
    return 1
  fi
  if [ -s "$file" ]; then
    echo "File is not empty: $file"
    return 1
  fi
}

# Assert directory exists
assert_dir_exist() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    echo "Directory does not exist: $dir"
    return 1
  fi
}

# Assert directory does not exist
assert_dir_not_exist() {
  local dir="$1"
  if [ -d "$dir" ]; then
    echo "Directory exists but should not: $dir"
    return 1
  fi
}

