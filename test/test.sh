#!/usr/bin/env bash

test() {
  local input_file=$1
  
}

pushd test || exit 1

CMD=../sycamore.sh

$CMD --pipeline-file .gitlab-ci.yml --job build.job


