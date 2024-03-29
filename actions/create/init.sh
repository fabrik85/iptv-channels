# Action scripts directory.
__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export __DIR

# Run without any effect (simulate).
export DRY_RUN=1

# Step files has to be skipped.
# Multiple steps defined as colon separated string (e.g. 5:6:7:8:9:10:11)
export SKIP=""

# Run in debug mode. (var name: DEBUG already used in helper.sh so use __DEBUG instead.)
export __DEBUG=1

# ===========================
# Function Definitions
# ===========================

function main() {
  getConfig "$@"
  #shellcheck source=/dev/null
  source "${ROOT_DIR}/actions/${ACTION}/vars.sh"

  if [[ "${ENV:-}" == 'dev' ]]; then
    __DEBUG=0
  fi
}

function getConfig() {
  #shellcheck disable=SC2068
  for option in $@; do
    option="$(echo "${option}" | tr "[:upper:]" "[:lower:]")"

    case "${option}" in
      --dryrun)
        DRY_RUN=0 ;;
      --debug)
        __DEBUG=0 ;;
      --skip-steps=*)
        readonly SKIP="${option//--skip-steps=/}" ;;
    esac
  done

  validateConfig
}

function validateConfig() {
  local -r regexNumber='^[0-9]+$'
  local skip_steps=()

# --skip-steps
  if [[ -n "${SKIP}" ]]; then
    while IFS='' read -r line; do skip_steps+=("$line"); done < <(echo "${SKIP}" | tr ":" "\n")

    if [[ ${#skip_steps[@]} -eq 0 ]] || ! [[ ${skip_steps[0]} =~ $regexNumber ]]; then
      __msg_error "Error: Defining '--skip-steps' (e.g. '--skip-steps=1:5' will skip step 1 and step 5)"
      return "${FAILURE}"
    fi
  fi

  return "${SUCCESS}"
}

main "$@"
