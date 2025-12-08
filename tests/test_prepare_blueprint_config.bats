#!/usr/bin/env bats
#
# Tests for prepare-blueprint-config.sh script
#

load test_helper

@test "prepare-blueprint-config: requires --blueprint-name argument" {
  run_script "prepare-blueprint-config.sh"
  
  assert_failure
  assert_output --partial "Usage:"
  assert_output --partial "--blueprint-name"
}

@test "prepare-blueprint-config: creates mise.toml in build directory" {
  if ! command -v mise >/dev/null 2>&1; then
    skip "mise command not available"
  fi
  
  create_test_blueprint_config "test-blueprint" "fedora-43" "minimal-installer" "x86_64"
  mkdir -p "build/test-blueprint"
  
  run_script "prepare-blueprint-config.sh" \
    --blueprint-name "test-blueprint" \
    --config-root "blueprint-config"
  
  assert_success
  assert_file_exist "build/test-blueprint/mise.toml"
}

@test "prepare-blueprint-config: includes distro in mise.toml" {
  if ! command -v mise >/dev/null 2>&1; then
    skip "mise command not available"
  fi
  
  create_test_blueprint_config "test-blueprint" "fedora-43" "minimal-installer" "x86_64"
  mkdir -p "build/test-blueprint"
  
  run_script "prepare-blueprint-config.sh" \
    --blueprint-name "test-blueprint" \
    --config-root "blueprint-config"
  
  assert_success
  
  # Check that mise.toml contains the distro
  if command -v tomlq >/dev/null 2>&1; then
    run tomlq -r '.env.DISTRO?' "build/test-blueprint/mise.toml"
    assert_output "fedora-43"
  fi
}

@test "prepare-blueprint-config: includes image-type in mise.toml" {
  if ! command -v mise >/dev/null 2>&1; then
    skip "mise command not available"
  fi
  
  create_test_blueprint_config "test-blueprint" "fedora-43" "minimal-installer" "x86_64"
  mkdir -p "build/test-blueprint"
  
  run_script "prepare-blueprint-config.sh" \
    --blueprint-name "test-blueprint" \
    --config-root "blueprint-config"
  
  assert_success
  
  if command -v tomlq >/dev/null 2>&1; then
    run tomlq -r '.env.IMAGE_TYPE?' "build/test-blueprint/mise.toml"
    assert_output "minimal-installer"
  fi
}

@test "prepare-blueprint-config: includes arch in mise.toml" {
  if ! command -v mise >/dev/null 2>&1; then
    skip "mise command not available"
  fi
  
  create_test_blueprint_config "test-blueprint" "fedora-43" "minimal-installer" "x86_64"
  mkdir -p "build/test-blueprint"
  
  run_script "prepare-blueprint-config.sh" \
    --blueprint-name "test-blueprint" \
    --config-root "blueprint-config"
  
  assert_success
  
  if command -v tomlq >/dev/null 2>&1; then
    run tomlq -r '.env.ARCH?' "build/test-blueprint/mise.toml"
    assert_output "x86_64"
  fi
}

@test "prepare-blueprint-config: fails when config file does not exist" {
  run_script "prepare-blueprint-config.sh" \
    --blueprint-name "nonexistent" \
    --config-root "blueprint-config"
  
  assert_failure
}

@test "prepare-blueprint-config: uses custom config-root directory" {
  if ! command -v mise >/dev/null 2>&1; then
    skip "mise command not available"
  fi
  
  mkdir -p "custom-config"
  create_test_blueprint_config "test-blueprint" "fedora-43" "minimal-installer" "x86_64"
  mv "blueprint-config/test-blueprint.yaml" "custom-config/test-blueprint.yaml"
  mkdir -p "build/test-blueprint"
  
  run_script "prepare-blueprint-config.sh" \
    --blueprint-name "test-blueprint" \
    --config-root "custom-config"
  
  assert_success
  assert_file_exist "build/test-blueprint/mise.toml"
}

@test "prepare-blueprint-config: fails when yq is not available" {
  create_test_blueprint_config "test-blueprint" "fedora-43" "minimal-installer" "x86_64"
  mkdir -p "build/test-blueprint"
  
  if command -v yq >/dev/null 2>&1; then
    skip "yq is available, cannot test missing dependency"
  fi
  
  run_script "prepare-blueprint-config.sh" \
    --blueprint-name "test-blueprint" \
    --config-root "blueprint-config"
  
  assert_failure
  assert_output --partial "yq is required"
}

