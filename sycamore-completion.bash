#!/usr/bin/env bash

contains_element() {
  local e match=$1
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

_sycamore_completions() {
  local cur prev opts
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  ###################
  # Autocomplete job names given a file
  ###################
  DEFAULT_FILENAME=".gitlab-ci.yml"

  if [[ "$prev" == "--job" ]]; then
    [[ -f "$DEFAULT_FILENAME" ]] || return 0
    JOB_LIST=$(yq eval ".[] | select(. | has(\"stage\")) | path" -o=tsv "$DEFAULT_FILENAME")
    JOB_ARRAY=($(echo "$JOB_LIST" | tr '\t' ' '))

    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "${JOB_ARRAY[@]}" -- "$cur"))
    return 0
  fi

  ###################
  # Autocomplete job names without a file
  ###################
}

complete -F _sycamore_completions sycamore.sh
