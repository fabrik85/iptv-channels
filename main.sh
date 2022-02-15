#!/usr/bin/env bash

set -o errexit  # same as 'set -e' => abort on nonzero exit status
set -o nounset  # same as 'set -u' => abort on unbound variable
set -o errtrace # same as 'set -E' => inherit ERR trap by shell functions
set -o pipefail #                  => don't hide errors within pipes

# Enable only for debugging! (same as 'set -x')
#  => It will print commands and their arguments as they are executed.
# set -o xtrace

export SUCCESS=0
export FAILURE=240

PROJECT_DIR="iptv"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#shellcheck source=/dev/null
source "${ROOT_DIR}"/helper.sh

UNKNOWN_ARGS=""
YAML=$(cat "${ROOT_DIR}"/config.yml)

function setupLogDir() {
  LOG_DIR="$(mktemp -d)"
  __msg_green "Log file created at: ${LOG_DIR}/RUN_LOG.txt"
}

function getCleanupScript() {
  echo "${YAML}" | yaml2json - | jq -er ".${ACTION}.cleanup"
}

function handleExit() {
  local exit_signal=$?

#  echo "EXIT SIGNAL : $exit_signal - $(kill -l $exit_signal 2>/dev/null || echo "UNKNOWN")"

  if [[ "$exit_signal" != "${SUCCESS}" ]]; then
    if [[ -v SEQUENCE[@] && "${#SEQUENCE[@]}" -gt 0 ]]; then
      local last_element

      last_element="${SEQUENCE[-1]}"
      if [[ "$exit_signal" == "${FAILURE}" ]]; then
        STATUS[$last_element]="${ERROR_MSG}"
        RUNTIME[$last_element]="-"
        OVERALL_RESULT="${ERROR_MSG}"
      else
        if [[ "${STATUS[$last_element]}" != "$SUCCESS_MSG" ]]; then
          STATUS[$last_element]="${UNKNOWN_MSG}"
          # shellcheck disable=SC2034
          RUNTIME[$last_element]="-"
          # shellcheck disable=SC2034
          OVERALL_RESULT="${UNKNOWN_MSG}"
        fi
      fi
    fi
    if getCleanupScript > /dev/null; then
      run "$(getCleanupScript)" 1
    fi
  else
    if getCleanupScript > /dev/null; then
      #run "$(getCleanupScript)" >> "${LOG_DIR}/RUN_LOG.txt" 2>&1
      run "$(getCleanupScript)" 0 > >(tee -a "${LOG_DIR}/RUN_LOG.txt") 2> >(tee -a "${LOG_DIR}/RUN_LOG.txt" >&2)
    fi
  fi

  triggerNotification "at_complete"
  #cat "${LOG_DIR}/RUN_LOG.txt"

  printf "\n"
  if [[ "$exit_signal" == "${SUCCESS}" ]]; then
    __msg_green "EXIT SIGNAL : $exit_signal"
  else
    __msg_red "EXIT SIGNAL : $exit_signal - $(kill -l $exit_signal 2>/dev/null || echo "UNKNOWN")"
  fi
  printf "\n"
}

function getMainConfig() {
  for option in "$@"; do
    case "$option" in
      --action=*)
        ACTION="${option//--action=/}"
        ;;
      *)
        [[ -z "$UNKNOWN_ARGS" ]] && UNKNOWN_ARGS="${option}" || UNKNOWN_ARGS="${UNKNOWN_ARGS} ${option}"
        ;;
    esac
  done

  if [[ -z "${ACTION:-}" ]]; then
    __msg_error "'--action=' argument were not passed.. [Please check]"
    return "${FAILURE}"
  else
    local triggering_datetime

    triggering_datetime=$(date)
    __msg_green "Triggering '$ACTION' action at $triggering_datetime"
  fi
}

function main() {
  local steps
  getMainConfig "$@"

  run "$(echo "${YAML}" | yaml2json - | jq -er ".${ACTION}.entrypoint")" "$UNKNOWN_ARGS"
  triggerNotification "at_start"

  steps=$(echo "${YAML}" | yaml2json - | jq -r ".${ACTION}.scripts[]?")

  for script in ${steps}; do
    run "${script}"
  done

  # Using process substitution with 'tee' listening makes possible to use 'docker logs [identifier]'
} > >(tee -a "${LOG_DIR}/RUN_LOG.txt") 2> >(tee -a "${LOG_DIR}/RUN_LOG.txt" >&2)

trap handleExit 0 SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM

setupLogDir
main "$@"
