#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -eu

SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
readonly SCRIPT_NAME
readonly VERSION="1.2.0"
GENERATED_SCRIPT="sycamore_gen_$(date +%Y%m%d_%H%M%S).sh"

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "Error: yq is required but not installed" >&2
    exit 1
fi

usage() {
  cat << EOF
Usage: ${SCRIPT_NAME} pipeline_job_name [ARGUMENTS]

Parses a given pipeline job and creates a file that you can source to 
automatically export job variables. You must provide at least the '--job-name' 
flag.

Options:
    -j,--job JOB                Job to be converted to shell script
    -p,-f,--pipeline-file FILE  Path to the pipeline configuration file (default: .gitlab-ci.yml)
    -s, --show                  Output the contents of the generated file at the end of the script
    --remove                    Remove the file after converting. Most useful with the "--show" flag.
    -o, --output                Output the contents to a specific filepath.
    -h,--help                   Show this help message and exit
    -v,--version                Show version information and exit
EOF
}

die() {
  local msg=$1
  local code=${2-1}
  printf >&2 "%s: %s\n" "$SCRIPT_NAME" "$msg"
  exit "$code"
}

main() {
  # argument error handling
  if [[ $# -lt 1 ]]; then
    die "at least one argument is required."
  fi

  # Initialize variables before processing flags
  local pipeline_file=".gitlab-ci.yml"
  local pipeline_job_name=""
  local show=false
  local remove_when_finished=false

  # Now process any flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 1
        ;;
      -v|--version|--veresion)
        printf "%s version %s\n" "$SCRIPT_NAME" "$VERSION"
        exit 0
        ;;
      -p|-f|--pipeline-file)
        if [ $# -lt 2 ]; then
          die "--pipeline-file requires a value"
        fi
        pipeline_file=$2
        shift 2
        ;;
      -j|--job)
        if [ $# -lt 2 ]; then
          die "--job requires a value"
        fi
        pipeline_job_name=$2
        shift 2
        ;;
      -s|--show)
        show=true
        shift
        ;;
      --remove)
        remove_when_finished=true
        shift
        ;;
      -o|--output)
        GENERATED_SCRIPT=$2
        shift 2
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done

  ##############################################################################
  # Input validation
  ##############################################################################

  # Some error handling
  if [[ -z "$pipeline_job_name" ]]; then
    die "needs --job flag (and a value)"
  fi

  if [[ "$pipeline_job_name" == "." ]]; then
    die "job name cannot be '.' bro"
  fi

  if [[ ! -f "$pipeline_file" ]]; then
    die "$pipeline_file not found"
  fi

  if [[ "$(yq eval ".\"$pipeline_job_name\"" "$pipeline_file")" == "null" ]]; then
    die "$pipeline_job_name not found in $pipeline_file."
  fi

  # Ok now start creating the shell script
  if [[ -e "$GENERATED_SCRIPT" ]]; then
    die "$GENERATED_SCRIPT already exists. exiting..."
  fi
  
  touch "$GENERATED_SCRIPT"
  
  echo "Creating $GENERATED_SCRIPT."

  if ! $remove_when_finished; then
    # shebang
    echo -e "#!/usr/bin/env bash" >> "$GENERATED_SCRIPT"

    # options so that if they `source` the file with unset variables it fails
    # INTENDED & TESTED WITH BASH ONLY
    echo -e "set -u\n" >> "$GENERATED_SCRIPT"
  fi

  ##############################################################################
  # Global variables
  ##############################################################################
  if yq -e ".variables" "$pipeline_file" &> /dev/null; then
    # shellcheck disable=SC2129
    yq eval -o=json ".variables" "$pipeline_file" | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""' >> "$GENERATED_SCRIPT"
  fi

  ##############################################################################
  # Job variables
  ##############################################################################

  if yq -e ".\"$pipeline_job_name\".variables" "$pipeline_file" &> /dev/null; then
    
    if yq -e ".\"$pipeline_job_name\".extends" "$pipeline_file" &> /dev/null; then
      extends_list=$(yq -e -o=tsv ".\"$pipeline_job_name\".extends" "$pipeline_file")

      for extended_job in $extends_list; do
        [ -z "$extended_job" ] && continue

        if yq -e "has(\"$extended_job\")" "$pipeline_file" > /dev/null 2>&1; then
          yq eval -o=json ".\"$extended_job\".variables" "$pipeline_file" | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""' >> "$GENERATED_SCRIPT"
        fi
      done
    fi

    yq eval -o=json ".\"$pipeline_job_name\".variables" "$pipeline_file" | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""' >> "$GENERATED_SCRIPT"
  fi

  if $show; then
    cat "$GENERATED_SCRIPT"
  fi

  if $remove_when_finished; then
    rm -f "$GENERATED_SCRIPT"
  fi
}

main "$@"
