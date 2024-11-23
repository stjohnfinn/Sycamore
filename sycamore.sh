#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -eu

readonly VERSION="1.1.0"
GENERATED_SCRIPT="sycamore_$(date +%Y%m%d_%H%M%S).sh"
readonly GENERATED_SCRIPT
INTERMEDIATE_FILE=$(mktemp)
readonly INTERMEDIATE_FILE
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
readonly SCRIPT_NAME

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "Error: yq is required but not installed" >&2
    exit 1
fi

usage() {
  cat << EOF
Usage: ${SCRIPT_NAME} pipeline_job_name [ARGUMENTS]

Parse a pipeline job with the specified name. You must provide at least the 
'--job-name' flag.

Options:
    -j,--job JOB                Job to be converted to shell script
    -p,-f,--pipeline-file FILE  Path to the pipeline configuration file (default: .gitlab-ci.yml)
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
      *)
        die "Unknown option: $1"
        ;;
    esac
  done

  ##############################################################################
  # MAIN LOGIC FOR PARSING PIPELINES HERE
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

  touch "$GENERATED_SCRIPT"
  # shebang
  echo -e "#!/usr/bin/env bash\n" >> "$GENERATED_SCRIPT"
  echo -e "set -eou pipefail\n" >> "$GENERATED_SCRIPT"

  printf "Job: %s (pipeline file: %s)\n" "$pipeline_job_name" "$pipeline_file"

  ###################
  # Global variables
  ###################
  if yq -e ".variables" "$pipeline_file" &> /dev/null; then
    printf "# Global variables\n" >> "$GENERATED_SCRIPT"
    yq eval -o=json ".variables" "$pipeline_file" | jq -r 'to_entries | .[] | "export \(.key)=\"\(.value)\""' >> "$GENERATED_SCRIPT"
    echo "" >> "$GENERATED_SCRIPT"
  fi

  ###################
  # Job variables
  ###################

  if yq -e ".\"$pipeline_job_name\".variables" "$pipeline_file" &> /dev/null; then
    printf "# Job variables\n" >> "$GENERATED_SCRIPT"
    
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
    echo "" >> "$GENERATED_SCRIPT"
  fi
}

main "$@"
