#!/usr/bin/env bats
#
# Tests for validate-blueprint-config.sh script
#

load test_helper

@test "validate-blueprint-config: requires --blueprint-name argument" {
  run_script "validate-blueprint-config.sh"
  
  assert_failure
  assert_output --partial "Usage:"
  assert_output --partial "--blueprint-name"
}

@test "validate-blueprint-config: fails when config file does not exist" {
  run_script "validate-blueprint-config.sh" \
    --blueprint-name "nonexistent" \
    --config-root "blueprint-config"
  
  assert_failure
  assert_output --partial "Config file not found"
}

@test "validate-blueprint-config: fails when config file is missing required fields (image-type)" {
  # Create a config file missing the image-type field
  cat > "blueprint-config/incomplete.yaml" <<EOF
distro: fedora-43
arch: x86_64
EOF
  
  run_script "validate-blueprint-config.sh" \
    --blueprint-name "incomplete" \
    --config-root "blueprint-config"
  
  assert_failure
  assert_output --partial "Missing required fields"
  assert_output --partial "image-type"
}

@test "validate-blueprint-config: fails when distro field is missing" {
  cat > "blueprint-config/missing-distro.yaml" <<EOF
image-type: minimal-installer
arch: x86_64
EOF
  
  run_script "validate-blueprint-config.sh" \
    --blueprint-name "missing-distro" \
    --config-root "blueprint-config"
  
  assert_failure
  assert_output --partial "distro"
}

@test "validate-blueprint-config: fails when arch field is missing" {
  cat > "blueprint-config/missing-arch.yaml" <<EOF
distro: fedora-43
image-type: minimal-installer
EOF
  
  run_script "validate-blueprint-config.sh" \
    --blueprint-name "missing-arch" \
    --config-root "blueprint-config"
  
  assert_failure
  assert_output --partial "arch"
}

@test "validate-blueprint-config: validates complete config file structure" {
  create_test_blueprint_config "complete" "fedora-43" "minimal-installer" "x86_64"
  
  # Mock image-builder command if not available
  if ! command -v image-builder >/dev/null 2>&1; then
    skip "image-builder command not available"
  fi
  
  run_script "validate-blueprint-config.sh" \
    --blueprint-name "complete" \
    --config-root "blueprint-config"
  
  # This may succeed or fail depending on whether the image type is actually available
  # We just check that it processes the config correctly
  assert_output --partial "distro:"
  assert_output --partial "image-type:"
  assert_output --partial "arch:"
}

@test "validate-blueprint-config: uses custom config-root directory" {
  mkdir -p "custom-config"
  create_test_blueprint_config "custom" "fedora-43" "minimal-installer" "x86_64"
  mv "blueprint-config/custom.yaml" "custom-config/custom.yaml"
  
  if ! command -v image-builder >/dev/null 2>&1; then
    skip "image-builder command not available"
  fi
  
  run_script "validate-blueprint-config.sh" \
    --blueprint-name "custom" \
    --config-root "custom-config"
  
  assert_output --partial "distro:"
}

@test "validate-blueprint-config: checks for yq command" {
  # This test would require mocking or skipping if yq is not available
  # For now, we'll just verify the script structure
  create_test_blueprint_config "test" "fedora-43" "minimal-installer" "x86_64"
  
  if ! command -v yq >/dev/null 2>&1; then
    run_script "validate-blueprint-config.sh" \
      --blueprint-name "test" \
      --config-root "blueprint-config"
    
    assert_failure
    assert_output --partial "yq is required"
  else
    skip "yq is available, cannot test missing dependency"
  fi
}

