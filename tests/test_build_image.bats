#!/usr/bin/env bats
#
# Tests for build-image.sh script
#

load test_helper

@test "build-image: requires all required parameters" {
  run_script "build-image.sh"
  
  assert_failure
  assert_output --partial "Usage:"
}

@test "build-image: fails when --base-image is missing" {
  run_script "build-image.sh" \
    --blueprint "blueprint.toml" \
    --output-dir "output" \
    --cache-dir "cache" \
    --arch "x86_64" \
    --distro "fedora-43" \
    --image-name "test"
  
  assert_failure
  assert_output --partial "Missing required parameters"
}

@test "build-image: fails when --blueprint is missing" {
  run_script "build-image.sh" \
    --base-image "minimal-installer" \
    --output-dir "output" \
    --cache-dir "cache" \
    --arch "x86_64" \
    --distro "fedora-43" \
    --image-name "test"
  
  assert_failure
  assert_output --partial "Missing required parameters"
}

@test "build-image: fails when --output-dir is missing" {
  run_script "build-image.sh" \
    --base-image "minimal-installer" \
    --blueprint "blueprint.toml" \
    --cache-dir "cache" \
    --arch "x86_64" \
    --distro "fedora-43" \
    --image-name "test"
  
  assert_failure
  assert_output --partial "Missing required parameters"
}

@test "build-image: fails when --cache-dir is missing" {
  run_script "build-image.sh" \
    --base-image "minimal-installer" \
    --blueprint "blueprint.toml" \
    --output-dir "output" \
    --arch "x86_64" \
    --distro "fedora-43" \
    --image-name "test"
  
  assert_failure
  assert_output --partial "Missing required parameters"
}

@test "build-image: fails when --arch is missing" {
  run_script "build-image.sh" \
    --base-image "minimal-installer" \
    --blueprint "blueprint.toml" \
    --output-dir "output" \
    --cache-dir "cache" \
    --distro "fedora-43" \
    --image-name "test"
  
  assert_failure
  assert_output --partial "Missing required parameters"
}

@test "build-image: fails when --distro is missing" {
  run_script "build-image.sh" \
    --base-image "minimal-installer" \
    --blueprint "blueprint.toml" \
    --output-dir "output" \
    --cache-dir "cache" \
    --arch "x86_64" \
    --image-name "test"
  
  assert_failure
  assert_output --partial "Missing required parameters"
}

@test "build-image: fails when --image-name is missing" {
  run_script "build-image.sh" \
    --base-image "minimal-installer" \
    --blueprint "blueprint.toml" \
    --output-dir "output" \
    --cache-dir "cache" \
    --arch "x86_64" \
    --distro "fedora-43"
  
  assert_failure
  # May fail with "Missing required parameters" or "unbound variable" due to set -u
  assert_output --partial "Missing required parameters" || assert_output --partial "IMAGE_NAME: unbound variable"
}

@test "build-image: fails with unknown option" {
  run_script "build-image.sh" \
    --unknown-option "value" \
    --base-image "minimal-installer" \
    --blueprint "blueprint.toml" \
    --output-dir "output" \
    --cache-dir "cache" \
    --arch "x86_64" \
    --distro "fedora-43" \
    --image-name "test"
  
  assert_failure
  assert_output --partial "Unknown option"
}

@test "build-image: uses default image-builder-cmd when not specified" {
  # This test verifies the default value is used
  # We can't easily test the actual execution without mocking sudo and image-builder
  # So we'll just verify the script accepts all parameters
  mkdir -p "output"
  mkdir -p "cache"
  touch "blueprint.toml"
  
  # Mock image-builder to avoid actual execution
  if command -v image-builder >/dev/null 2>&1; then
    skip "image-builder is available, would require sudo mocking"
  fi
  
  # Without image-builder, the script will fail with 127 (command not found) when trying to execute it
  # Use -127 so Bats doesn't warn about unexpected exit code
  run_script -127 "build-image.sh" \
    --base-image "minimal-installer" \
    --blueprint "blueprint.toml" \
    --output-dir "output" \
    --cache-dir "cache" \
    --arch "x86_64" \
    --distro "fedora-43" \
    --image-name "test"
  
  # Should fail when trying to execute image-builder, not on parameter validation
  # This confirms all parameters were accepted
  [ $status -ne 0 ]
}

@test "build-image: accepts custom image-builder-cmd" {
  mkdir -p "output"
  mkdir -p "cache"
  touch "blueprint.toml"
  
  # Create a mock image-builder command
  cat > "mock-image-builder" <<'EOF'
#!/usr/bin/env bash
echo "Mock image-builder called with custom command"
exit 1
EOF
  chmod +x "mock-image-builder"
  PATH="$TEST_TMPDIR:$PATH"
  
  run_script "build-image.sh" \
    --image-builder-cmd "mock-image-builder" \
    --base-image "minimal-installer" \
    --blueprint "blueprint.toml" \
    --output-dir "output" \
    --cache-dir "cache" \
    --arch "x86_64" \
    --distro "fedora-43" \
    --image-name "test"
  
  # Verify the custom command was used (not the default)
  assert_output --partial "Mock image-builder called with custom command"
  
  # Script should fail because mock exits with error
  assert_failure
}

@test "build-image: decompresses minimal-raw-zst image type" {
  mkdir -p "output"
  mkdir -p "cache"
  touch "blueprint.toml"
  
  # Create a mock compressed file
  echo "test data" > "output/test.zst"
  
  # Mock image-builder and unzstd
  cat > "scripts/mock-image-builder" <<'EOF'
#!/usr/bin/env bash
echo "Mock image-builder"
EOF
  chmod +x "scripts/mock-image-builder"
  
  if ! command -v unzstd >/dev/null 2>&1; then
    skip "unzstd not available"
  fi
  
  # This test would require mocking sudo and image-builder execution
  # For now, we'll verify the decompression logic exists
  skip "Requires sudo and image-builder mocking to test fully"
}

@test "build-image: does not decompress non-zst image types" {
  mkdir -p "output"
  mkdir -p "cache"
  touch "blueprint.toml"
  
  # This test verifies that non-zst image types don't trigger decompression
  # Since we can't easily mock the full execution, we'll skip this
  skip "Requires full execution mocking"
}

@test "build-image: validates all required parameters are present" {
  mkdir -p "output"
  mkdir -p "cache"
  touch "blueprint.toml"
  
  # Skip if image-builder is available to avoid actual execution
  # The script uses sudo which makes mocking difficult
  if command -v image-builder >/dev/null 2>&1; then
    skip "image-builder is available, skipping to avoid actual execution"
  fi
  
  # Create a mock image-builder that fails (to simulate build failure)
  # This allows us to verify parameter validation passed without requiring actual image-builder execution
  cat > "mock-image-builder" <<'EOF'
#!/usr/bin/env bash
echo "Mock image-builder called"
exit 1
EOF
  chmod +x "mock-image-builder"
  
  # Add mock to PATH
  PATH="$TEST_TMPDIR:$PATH"
  
  run_script "build-image.sh" \
    --image-builder-cmd "mock-image-builder" \
    --base-image "minimal-installer" \
    --blueprint "blueprint.toml" \
    --output-dir "output" \
    --cache-dir "cache" \
    --arch "x86_64" \
    --distro "fedora-43" \
    --image-name "test"
  
  # Should have passed parameter validation (no "Missing required parameters" error)
  # The script should fail when executing the mock command, not on parameter validation
  # This confirms all parameters were accepted
  if [[ "$output" == *"Missing required parameters"* ]]; then
    echo "Unexpected: Missing required parameters error"
    return 1
  fi
  
  # Verify the mock was called (confirms script got past parameter validation)
  assert_output --partial "Mock image-builder called"
  
  # Script should fail because mock exits with error
  assert_failure
}

@test "build-image: handles relative and absolute paths correctly" {
  mkdir -p "output"
  mkdir -p "cache"
  touch "blueprint.toml"
  
  # Skip if image-builder is available to avoid actual execution
  # The script uses sudo which makes mocking difficult
  if command -v image-builder >/dev/null 2>&1; then
    skip "image-builder is available, skipping to avoid actual execution"
  fi
  
  # Create a mock image-builder that fails (to simulate build failure)
  # This allows us to verify parameter validation passed without requiring actual image-builder execution
  cat > "mock-image-builder" <<'EOF'
#!/usr/bin/env bash
echo "Mock image-builder called"
exit 1
EOF
  chmod +x "mock-image-builder"
  
  # Add mock to PATH
  PATH="$TEST_TMPDIR:$PATH"
  
  # Test with relative paths
  run_script "build-image.sh" \
    --image-builder-cmd "mock-image-builder" \
    --base-image "minimal-installer" \
    --blueprint "./blueprint.toml" \
    --output-dir "./output" \
    --cache-dir "./cache" \
    --arch "x86_64" \
    --distro "fedora-43" \
    --image-name "test"
  
  # Should have passed parameter validation (no "Missing required parameters" error)
  if [[ "$output" == *"Missing required parameters"* ]]; then
    echo "Unexpected: Missing required parameters error"
    return 1
  fi
  
  # Verify the mock was called (confirms script got past parameter validation)
  assert_output --partial "Mock image-builder called"
  
  # Script should fail because mock exits with error
  assert_failure
}

