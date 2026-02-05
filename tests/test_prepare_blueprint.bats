#!/usr/bin/env bats
#
# Tests for prepare-blueprint.sh script
#
# Note: mise version manager is activated in test_helper.bash setup()
# This ensures tools like tomlq and yq are available in the correct versions

load test_helper

@test "prepare-blueprint: requires blueprint path argument" {
  run_script "prepare-blueprint.sh"
  
  assert_failure
  assert_output --partial "Usage:"
}

@test "prepare-blueprint: fails when blueprint file does not exist" {
  run_script "prepare-blueprint.sh" "blueprints/nonexistent.toml"
  
  assert_failure
}

@test "prepare-blueprint: fails when tomlq is not available" {
  create_test_blueprint_toml "test-blueprint"
  
  # Mock missing tomlq
  if command -v tomlq >/dev/null 2>&1; then
    skip "tomlq is available, cannot test missing dependency"
  fi
  
  run_script "prepare-blueprint.sh" "blueprints/test-blueprint.toml"
  
  assert_failure
  assert_output --partial "tomlq is required"
}

@test "prepare-blueprint: fails when yq is not available" {
  create_test_blueprint_toml "test-blueprint"
  
  # Mock missing yq
  if command -v yq >/dev/null 2>&1; then
    skip "yq is available, cannot test missing dependency"
  fi
  
  run_script "prepare-blueprint.sh" "blueprints/test-blueprint.toml"
  
  assert_failure
  assert_output --partial "yq is required"
}

@test "prepare-blueprint: creates prepared blueprint in build directory" {
  # Ensure mise is activated (already done in test_helper setup, but verify tools are available)
  set +u
  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)" 2>/dev/null || true
  fi
  set -u
  
  if ! command -v tomlq >/dev/null 2>&1 || ! command -v yq >/dev/null 2>&1; then
    skip "tomlq or yq not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  create_test_blueprint_config "test-blueprint"
  
  run_script "prepare-blueprint.sh" "blueprints/test-blueprint.toml"
  
  assert_success
  assert_file_exist "build/test-blueprint/test-blueprint.toml"
}

@test "prepare-blueprint: includes services from blueprint-services directory" {
  # Ensure mise is activated for tool availability
  set +u
  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)" 2>/dev/null || true
  fi
  set -u
  
  if ! command -v tomlq >/dev/null 2>&1 || ! command -v yq >/dev/null 2>&1; then
    skip "tomlq or yq not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  create_test_blueprint_config "test-blueprint"
  create_test_service "test-blueprint" "test-service"
  
  run_script "prepare-blueprint.sh" "blueprints/test-blueprint.toml"
  
  assert_success
  
  # Check that service was added to prepared blueprint
  if command -v tomlq >/dev/null 2>&1; then
    run tomlq -r '.customizations.services.enabled[]?' "build/test-blueprint/test-blueprint.toml"
    assert_output --partial "test-service.service"
  fi
}

@test "prepare-blueprint: includes kickstart for installer image types" {
  # Ensure mise is activated for tool availability
  set +u
  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)" 2>/dev/null || true
  fi
  set -u
  
  if ! command -v tomlq >/dev/null 2>&1 || ! command -v yq >/dev/null 2>&1; then
    skip "tomlq or yq not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  create_test_blueprint_config "test-blueprint" "fedora-43" "minimal-installer" "x86_64"
  create_test_kickstart "test-blueprint"
  
  run_script "prepare-blueprint.sh" "blueprints/test-blueprint.toml"
  
  assert_success
  
  # Check that kickstart was added to prepared blueprint
  if command -v tomlq >/dev/null 2>&1; then
    run tomlq -r '.customizations.installer.kickstart.contents?' "build/test-blueprint/test-blueprint.toml"
    assert_output --partial "Test kickstart executed"
  fi
}

@test "prepare-blueprint: includes services from blueprint-services/all directory" {
  # Ensure mise is activated for tool availability
  set +u
  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)" 2>/dev/null || true
  fi
  set -u
  
  if ! command -v tomlq >/dev/null 2>&1 || ! command -v yq >/dev/null 2>&1; then
    skip "tomlq or yq not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  create_test_blueprint_config "test-blueprint"
  create_test_service "all" "global-service"
  
  run_script "prepare-blueprint.sh" "blueprints/test-blueprint.toml"
  
  assert_success
  
  # Check that global service was added
  if command -v tomlq >/dev/null 2>&1; then
    run tomlq -r '.customizations.services.enabled[]?' "build/test-blueprint/test-blueprint.toml"
    assert_output --partial "global-service.service"
  fi
}

@test "prepare-blueprint: preserves original blueprint packages" {
  # Ensure mise is activated for tool availability
  set +u
  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)" 2>/dev/null || true
  fi
  set -u
  
  if ! command -v tomlq >/dev/null 2>&1 || ! command -v yq >/dev/null 2>&1; then
    skip "tomlq or yq not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  create_test_blueprint_config "test-blueprint"
  
  run_script "prepare-blueprint.sh" "blueprints/test-blueprint.toml"
  
  assert_success
  
  # Check that packages are preserved
  if command -v tomlq >/dev/null 2>&1; then
    run tomlq -r '.packages[].name' "build/test-blueprint/test-blueprint.toml"
    assert_output --partial "kernel"
  fi
}

