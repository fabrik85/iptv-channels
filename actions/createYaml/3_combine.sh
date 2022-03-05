# shellcheck source=./helper/skip.sh
source "${__DIR}"/helper/skip.sh
# shellcheck source=./helper/post_action.sh
source "${__DIR}"/helper/post_action.sh

__FILE_PATH="${__DIR}/$(basename "${BASH_SOURCE[0]}")"
__FILE=${__FILE_PATH##*/} # Remove everything from the last  '/' char backwards
__STEP=${__FILE%%_*}      # Remove everything from the first '_' char onwards

# "0" = true (we need to skip)
if [[ $(_isSkippedStep "${__STEP}") == "0" ]]; then
  __msg_info "SKIP STEP ${__STEP}"
  return "${SUCCESS}"
fi

function main() {
  if [[ -f "${LOCAL_DIR}/${OUTPUT_FILE}" ]]; then
    __msg_debug "File exists! Delete: ${LOCAL_DIR}/${OUTPUT_FILE}"
    rm -f "${LOCAL_DIR}/${OUTPUT_FILE}"
  fi

  echo -e "---\ntv:" > "${LOCAL_DIR}/${OUTPUT_FILE}"
  # Combine all .tyml files into a single .yml file
  find "${LOCAL_DIR}" -type f -name "*.tyml" | sort | xargs cat >> "${LOCAL_DIR}/${OUTPUT_FILE}"

  if [[ -f "${ROOT_DIR}/output/${OUTPUT_FILE}" ]]; then
    __msg_debug "File exists! Delete: ${ROOT_DIR}/output/${OUTPUT_FILE}"
    rm -f "${ROOT_DIR}/output/${OUTPUT_FILE}"
  fi

  cp "${LOCAL_DIR}/${OUTPUT_FILE}" "${ROOT_DIR}/output/${OUTPUT_FILE}"
}

main "$@"
