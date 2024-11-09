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

  FILENAME=".gitlab-ci.yml"

  ###################
  # Autocomplete job names in a file
  ###################

  for ((i=0; i<COMP_CWORD; i++)); do
    if [[ "${COMP_WORDS[i]}" == "--file" && $((i+1)) -lt COMP_CWORD ]]; then
      FILENAME="${COMP_WORDS[i+1]}"
    fi
  done

  if [[ "$prev" == "--job" || "$prev" == "-j" ]]; then
    [[ -f "$FILENAME" ]] || return 0
    JOB_LIST=$(yq eval ".[] | select(. | has(\"stage\")) | path" -o=tsv "$FILENAME")
    JOB_ARRAY=($(echo "$JOB_LIST" | tr '\t' ' '))

    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "${JOB_ARRAY[*]}" -- "$cur"))
    return 0
  fi
}

complete -F _sycamore_completions sycamore.sh
