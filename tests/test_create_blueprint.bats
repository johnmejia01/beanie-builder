#!/usr/bin/env bats
#
# Tests for create-blueprint.sh script
#

load test_helper

@test "create-blueprint: requires --blueprint-name argument" {
  run_script "create-blueprint.sh"
  
  assert_failure
  assert_output --partial "Usage:"
  assert_output --partial "--blueprint-name"
}

@test "create-blueprint: creates blueprint structure with valid name" {
  run_script "create-blueprint.sh" --blueprint-name "test-blueprint"
  
  assert_success
  assert_output --partial "Blueprint test-blueprint created"
  
  # Check that files and directories were created
  assert_file_exist "blueprints/test-blueprint.toml"
  assert_file_exist "blueprint-config/test-blueprint.yaml"
  assert_dir_exist "blueprint-kickstarts/test-blueprint"
  assert_dir_exist "blueprint-kickstarts/all"
  assert_dir_exist "blueprint-services/test-blueprint"
  assert_dir_exist "blueprint-services/all"
}

@test "create-blueprint: creates empty blueprint TOML file" {
  run_script "create-blueprint.sh" --blueprint-name "empty-blueprint"
  
  assert_success
  assert_file_exist "blueprints/empty-blueprint.toml"
  assert_file_empty "blueprints/empty-blueprint.toml"
}

@test "create-blueprint: creates empty blueprint config YAML file" {
  run_script "create-blueprint.sh" --blueprint-name "config-blueprint"
  
  assert_success
  assert_file_exist "blueprint-config/config-blueprint.yaml"
  assert_file_empty "blueprint-config/config-blueprint.yaml"
}

@test "create-blueprint: handles blueprint name with special characters" {
  run_script "create-blueprint.sh" --blueprint-name "test_blueprint-123"
  
  assert_success
  assert_file_exist "blueprints/test_blueprint-123.toml"
  assert_file_exist "blueprint-config/test_blueprint-123.yaml"
}

@test "create-blueprint: creates directories even if they already exist" {
  # Create directories first
  mkdir -p "blueprint-kickstarts/test-blueprint"
  mkdir -p "blueprint-services/test-blueprint"
  
  run_script "create-blueprint.sh" --blueprint-name "test-blueprint"
  
  assert_success
  assert_file_exist "blueprints/test-blueprint.toml"
}

@test "create-blueprint: fails with invalid option" {
  run_script "create-blueprint.sh" --invalid-option "value"
  
  assert_failure
  assert_output --partial "Usage:"
}

