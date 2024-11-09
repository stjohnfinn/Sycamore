#!/usr/bin/env bash

_sycamore_completions() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  FILENAME=".gitlab-ci.yml"

  ###################
  # Autocomplete job names in a file
  ###################

  for ((i=0; i<COMP_CWORD; i++)); do
    case "${COMP_WORDS[i]}" in
      -f|-p|--pipeline-file)
        if [[ $((i+1)) -lt $COMP_CWORD ]]; then
          FILENAME="${COMP_WORDS[i+1]}"
        fi
        ;;
    esac
  done

  if [[ "$prev" == "--job" || "$prev" == "-j" ]]; then
    [[ -f "$FILENAME" ]] || return 0
    JOB_LIST=$(yq eval ".[] | select(. | has(\"stage\")) | path" -o=tsv "$FILENAME")
    # shellcheck disable=SC2207
    JOB_ARRAY=($(echo "$JOB_LIST" | tr '\t' ' '))

    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "${JOB_ARRAY[*]}" -- "$cur"))
    return 0
  fi

  case "$prev" in
    -f|-p|--pipeline-file)
    # shellcheck disable=SC2207
      COMPREPLY=($(compgen -f -- "$cur" | xargs -I {} bash -c '[[ -f "{}" ]] && echo "{}"'))
      return 0
      ;;
  esac
}

complete -F _sycamore_completions sycamore.sh
