#!/usr/bin/env bash

CMD=$(realpath "./sycamore.sh")
readonly CMD

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly STRONG_GREEN='\033[1;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly RESET='\033[0m'

validation_test() {
  local name=$1
  local command=$2

  if ! $command; then
    echo -e "${GREEN}$name: test passed!${RESET}"
    rm -f "$output_file"
  else
    echo -e "${RED}$name: test failed!${RESET}"
    exit 1
  fi
}

test() {
  local name=$1
  local job=$2
  local file=$3
  local solution_file=$4

  local output_file
  output_file=$(mktemp)
  # delete the file immediately so that overwrite doesn't get blocked
  rm -f "$output_file"

  echo -e "${YELLOW}Testing: $name${RESET}"
  echo "  job name: $job"
  echo "  file name: $file"
  echo "  solution file: $solution_file"
  echo "  output_file: $output_file"

  $CMD --pipeline-file "$file" --job "$job" --output "$output_file"

  if cmp -s "$output_file" "$solution_file"; then
    echo -e "${GREEN}$name: test passed!${RESET}"
    rm -f "$output_file"
  else
    echo -e "${RED}$name: files differ. test failed!${RESET}"
    echo "path to generated file: $output_file. leaving intact."
    exit 1
  fi
}

pushd test &>/dev/null || exit 1

################################################################################
# Validation tests
################################################################################

validation_test \
  "job name as a dot" \
  "$CMD --pipeline-file .gitlab-ci.yml --job . --remove"

validation_test \
  "pipeline file doesn't exist" \
  "$CMD --pipeline-file .gitlab-ci.yml.noexist --job job-name --remove"

validation_test \
  "job doesn't exist" \
  "$CMD --pipeline-file .gitlab-ci.yml --job invalid-job-name --remove"

validation_test \
  "called without job name flag" \
  "$CMD --pipeline-file .gitlab-ci.yml --remove"

validation_test \
  "output file already exists" \
  "$CMD --pipeline-file .gitlab-ci.yml --job build.job --remove --output .gitlab-ci.yml"

################################################################################
# Basic tests
################################################################################

test \
  "basic 1" \
  "build.job" \
  ".gitlab-ci.yml" \
  "solutions/basic_1.sh"

test \
  "basic 2" \
  "test-job" \
  ".gitlab-ci.yml" \
  "solutions/basic_2.sh"

echo -e "${STRONG_GREEN}All tests passed!${RESET}"
