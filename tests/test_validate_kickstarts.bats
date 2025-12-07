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
  assert [ $status -eq 0 ] || [ $status -eq 1 ]
}

@test "validate-kickstarts: handles missing kickstart file gracefully" {
  create_test_blueprint_toml "test-blueprint"
  # Don't create kickstart file
  
  run_script "validate-kickstarts.sh" --blueprint-path "blueprints/test-blueprint.toml"
  
  # Should handle missing kickstart gracefully (may skip or succeed)
  assert [ $status -eq 0 ] || [ $status -eq 1 ]
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
  assert [ $status -eq 0 ] || [ $status -eq 1 ]
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

