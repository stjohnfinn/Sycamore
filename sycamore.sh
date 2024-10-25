#!/usr/bin/env bash

set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -eu

readonly VERSION="1.0.0"
GENERATED_SCRIPT="sycamore_$(date +%Y%m%d_%H%M%S).sh"
readonly GENERATED_SCRIPT
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")
readonly SCRIPT_NAME

usage() {
  cat << EOF
Usage: ${SCRIPT_NAME} pipeline_job_name [--help] [--version] [--run]

Run a pipeline job with the specified name.

Options:
    --job JOB             Job to be converted to shell script
    --pipeline-file FILE  Path to the pipeline configuration file (default: .gitlab-ci.yml)
    --run                 Execute the pipeline job after generating script
    --help                Show this help message and exit
    --version             Show version information and exit
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
  local run=0
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
      -r|--run)
        run=1
        shift
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
    die "$pipeline_file not found."
  fi

  if [[ "$(yq eval ".\"$pipeline_job_name\"" "$pipeline_file")" == "null" ]]; then
    die "$pipeline_job_name not found in $pipeline_file."
  fi

  # Ok now start creating the shell script

  touch "$GENERATED_SCRIPT"
  # shebang
  echo -e "#!/usr/bin/env bash\n" >> "$GENERATED_SCRIPT"

  printf "Job: %s (pipeline file: %s)\n" "$pipeline_job_name" "$pipeline_file"

  # shellcheck disable=SC2129
  printf "# Global variables\n" >> "$GENERATED_SCRIPT"
  yq eval -o=json ".variables" "$pipeline_file" | jq -r 'to_entries | .[] | "\(.key)=\"\(.value)\""' >> "$GENERATED_SCRIPT"
  echo "" >> "$GENERATED_SCRIPT"
  printf "# Job variables\n" >> "$GENERATED_SCRIPT"
  yq eval -o=json ".\"$pipeline_job_name\".variables" "$pipeline_file" | jq -r 'to_entries | .[] | "\(.key)=\"\(.value)\""' >> "$GENERATED_SCRIPT"
  echo "" >> "$GENERATED_SCRIPT"
  printf "# Job script\n" >> "$GENERATED_SCRIPT"
  yq eval ".\"$pipeline_job_name\".script[]" "$pipeline_file" >> "$GENERATED_SCRIPT"
  echo "" >> "$GENERATED_SCRIPT"

  if [[ "$run" == 1 ]]; then
    echo "Running the script..."

    while IFS= read -r line; do
      if [[ -z "$line" ]]; then
        continue
      fi

      if [[ ${line:0:1} == "#" ]]; then
        continue
      fi

      echo "Running \"$line\" in 3 seconds."
      sleep 3

      eval "$line"

      sleep 1
    done < "$GENERATED_SCRIPT"

    rm -f "$GENERATED_SCRIPT"
  fi
}

main "$@"
