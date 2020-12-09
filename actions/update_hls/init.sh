# Run without any effect (simulate).
export DRYRUN=0

# Step files has to be skipped.
# Multiple steps defined as colon separated string (e.g. 5:6:7:8:9:10:11)
export SKIP=""

# ===========================
# Function Definitions
# ===========================

function main() {
  getConfig "$@"
  #shellcheck source=/dev/null
  source "${ROOT_DIR}/actions/${ACTION}/vars.sh"
}

function getConfig() {
  #shellcheck disable=SC2068
  for option in $@; do
    option="$(echo "${option}" | tr "[:upper:]" "[:lower:]")"
    case "${option}" in
      --dryrun)
        readonly DRYRUN=1 ;;
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
