# shellcheck source=./helper/step_helper.sh
source "${__DIR}"/helper/step_helper.sh

__FILE_PATH="${__DIR}/$(basename "${BASH_SOURCE[0]}")"
__FILE=${__FILE_PATH##*/} # Remove everything from the last  '/' char backwards
__STEP=${__FILE%%_*}      # Remove everything from the first '_' char onwards

# "0" = true (we need to skip)
if [[ $(_isSkippedStep "${__STEP}") == "0" ]]; then
  __msg_info "SKIP STEP ${__STEP}"
  return "${SUCCESS}"
fi

function uploadToS3() {
  if [[ "${NOOP}" -eq 0 ]] && [[ -f ${LOCAL_PATH}.modified ]]; then
    aws s3 cp "${LOCAL_PATH}.modified" "${S3_PATH}"
  fi
}

uploadToS3