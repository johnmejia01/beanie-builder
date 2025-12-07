#!/usr/bin/env bats
#
# Tests for clean.sh script
#

load test_helper

@test "clean: requires --blueprint and --output-dir arguments" {
  run_script "clean.sh"
  
  assert_failure
  assert_output --partial "Usage:"
}

@test "clean: removes contents of blueprint build directory" {
  mkdir -p "build/test-blueprint"
  touch "build/test-blueprint/test-file"
  touch "build/test-blueprint/another-file"
  
  run_script "clean.sh" --output-dir "build" --blueprint "test-blueprint"
  
  assert_success
  assert_dir_exist "build/test-blueprint"
  assert_file_not_exist "build/test-blueprint/test-file"
  assert_file_not_exist "build/test-blueprint/another-file"
}

@test "clean: fails when blueprint directory does not exist" {
  run_script "clean.sh" --output-dir "build" --blueprint "nonexistent"
  
  assert_failure
  assert_output --partial "does not exist"
}

@test "clean: only removes contents of specified blueprint directory" {
  mkdir -p "build/blueprint1"
  mkdir -p "build/blueprint2"
  touch "build/blueprint1/file1"
  touch "build/blueprint2/file2"
  
  run_script "clean.sh" --output-dir "build" --blueprint "blueprint1"
  
  assert_success
  assert_dir_exist "build/blueprint1"
  assert_file_not_exist "build/blueprint1/file1"
  assert_dir_exist "build/blueprint2"
  assert_file_exist "build/blueprint2/file2"
}

@test "clean: preserves cache directory" {
  mkdir -p "build/cache"
  mkdir -p "build/test-blueprint"
  touch "build/cache/cache.info"
  touch "build/test-blueprint/test-file"
  
  run_script "clean.sh" --output-dir "build" --blueprint "test-blueprint"
  
  assert_success
  assert_dir_exist "build/cache"
  assert_file_exist "build/cache/cache.info"
}

