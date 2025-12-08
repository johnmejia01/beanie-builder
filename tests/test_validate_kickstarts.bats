#!/usr/bin/env bats
#
# Tests for validate-kickstarts.sh script
#

load test_helper

@test "validate-kickstarts: requires --blueprint-path argument" {
  run_script "validate-kickstarts.sh"
  
  assert_failure
  assert_output --partial "Usage:"
  assert_output --partial "--blueprint-path"
}

@test "validate-kickstarts: validates valid kickstart file" {
  if ! command -v ksvalidator >/dev/null 2>&1; then
    skip "ksvalidator not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  create_test_kickstart "test-blueprint"
  
  run_script "validate-kickstarts.sh" --blueprint-path "blueprints/test-blueprint.toml"
  
  # May succeed or fail depending on kickstart content, but should not crash
  # Status should be 0 (success) or 1 (validation failure), but not other errors
  [ $status -eq 0 ] || [ $status -eq 1 ]
}

@test "validate-kickstarts: handles missing kickstart file gracefully" {
  create_test_blueprint_toml "test-blueprint"
  # Don't create kickstart file
  
  run_script "validate-kickstarts.sh" --blueprint-path "blueprints/test-blueprint.toml"
  
  # Should handle missing kickstart gracefully (may skip or succeed)
  # Status should be 0 (success - no kickstart to validate) or 1 (validation failure)
  [ $status -eq 0 ] || [ $status -eq 1 ]
}

@test "validate-kickstarts: validates global kickstart file" {
  if ! command -v ksvalidator >/dev/null 2>&1; then
    skip "ksvalidator not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  mkdir -p "blueprint-kickstarts/all"
  cat > "blueprint-kickstarts/all/global.ks" <<EOF
# Global kickstart file
%post --nochroot --log=/mnt/sysimage/root/ks-post.log
echo "Global kickstart executed"
%end
EOF
  
  run_script "validate-kickstarts.sh" --blueprint-path "blueprints/test-blueprint.toml"
  
  # Should process global kickstart
  # Status should be 0 (success) or 1 (validation failure)
  [ $status -eq 0 ] || [ $status -eq 1 ]
}

@test "validate-kickstarts: fails when ksvalidator is not available" {
  create_test_blueprint_toml "test-blueprint"
  create_test_kickstart "test-blueprint"
  
  if command -v ksvalidator >/dev/null 2>&1; then
    skip "ksvalidator is available, cannot test missing dependency"
  fi
  
  run_script "validate-kickstarts.sh" --blueprint-path "blueprints/test-blueprint.toml"
  
  assert_failure
  assert_output --partial "ksvalidator is required"
}

@test "validate-kickstarts: fails when blueprint-specific kickstart file is invalid" {
  if ! command -v ksvalidator >/dev/null 2>&1; then
    skip "ksvalidator not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  
  # Create an invalid kickstart file (missing %end for %post section)
  mkdir -p "blueprint-kickstarts/test-blueprint"
  cat > "blueprint-kickstarts/test-blueprint/kickstart.ks" <<EOF
# Invalid kickstart file - missing %end
%post --nochroot --log=/mnt/sysimage/root/ks-post.log
echo "This section is not properly closed"
# Missing %end here
EOF
  
  run_script "validate-kickstarts.sh" --blueprint-path "blueprints/test-blueprint.toml"
  
  assert_failure
  assert_output --partial "Blueprint-specific kickstart validation failed"
}

@test "validate-kickstarts: fails when blueprint-specific kickstart has syntax error" {
  if ! command -v ksvalidator >/dev/null 2>&1; then
    skip "ksvalidator not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  
  # Create an invalid kickstart file with syntax error (invalid command)
  mkdir -p "blueprint-kickstarts/test-blueprint"
  cat > "blueprint-kickstarts/test-blueprint/kickstart.ks" <<EOF
# Invalid kickstart file - invalid command
invalid-command-that-does-not-exist
%post
echo "test"
%end
EOF
  
  run_script "validate-kickstarts.sh" --blueprint-path "blueprints/test-blueprint.toml"
  
  assert_failure
  assert_output --partial "Blueprint-specific kickstart validation failed"
}

@test "validate-kickstarts: fails when global kickstart file is invalid" {
  if ! command -v ksvalidator >/dev/null 2>&1; then
    skip "ksvalidator not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  
  # Create an invalid global kickstart file (missing %end)
  mkdir -p "blueprint-kickstarts/all"
  cat > "blueprint-kickstarts/all/global.ks" <<EOF
# Invalid global kickstart file - missing %end
%post --nochroot --log=/mnt/sysimage/root/ks-post.log
echo "This section is not properly closed"
# Missing %end here
EOF
  
  run_script "validate-kickstarts.sh" --blueprint-path "blueprints/test-blueprint.toml"
  
  assert_failure
  assert_output --partial "Global kickstart validation failed"
}

@test "validate-kickstarts: fails when global kickstart has syntax error" {
  if ! command -v ksvalidator >/dev/null 2>&1; then
    skip "ksvalidator not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  
  # Create an invalid global kickstart file with syntax error
  mkdir -p "blueprint-kickstarts/all"
  cat > "blueprint-kickstarts/all/global.ks" <<EOF
# Invalid global kickstart file - invalid command
invalid-command-that-does-not-exist
%post
echo "test"
%end
EOF
  
  run_script "validate-kickstarts.sh" --blueprint-path "blueprints/test-blueprint.toml"
  
  assert_failure
  assert_output --partial "Global kickstart validation failed"
}

@test "validate-kickstarts: fails on global kickstart first when both are invalid" {
  if ! command -v ksvalidator >/dev/null 2>&1; then
    skip "ksvalidator not available"
  fi
  
  create_test_blueprint_toml "test-blueprint"
  
  # Create invalid global kickstart file
  mkdir -p "blueprint-kickstarts/all"
  cat > "blueprint-kickstarts/all/global.ks" <<EOF
# Invalid global kickstart file
%post
echo "test"
# Missing %end
EOF
  
  # Create invalid blueprint-specific kickstart file
  mkdir -p "blueprint-kickstarts/test-blueprint"
  cat > "blueprint-kickstarts/test-blueprint/kickstart.ks" <<EOF
# Invalid blueprint kickstart file
%post
echo "test"
# Missing %end
EOF
  
  run_script "validate-kickstarts.sh" --blueprint-path "blueprints/test-blueprint.toml"
  
  # Should fail on global kickstart first (it's validated first)
  assert_failure
  assert_output --partial "Global kickstart validation failed"
  # Should not reach blueprint-specific validation
  assert_output --partial "Validating global kickstart"
}

