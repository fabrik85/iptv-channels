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

function uploadToS3() {
  if [[ "${DRY_RUN}" -ne 0 ]] && [[ -f ${LOCAL_PATH} ]]; then
    aws s3 cp "${LOCAL_PATH}" "${S3_PATH}"
  fi
}

# Only try to upload in case AWS credentials exits.
if [[ "${ADEBUG}" -eq 0 ]]; then
  __msg_info "Upload will be not executed! Reason: --debug option enabled."
  DRY_RUN=0
fi

uploadToS3
# Restore DRY_RUN
postAction
