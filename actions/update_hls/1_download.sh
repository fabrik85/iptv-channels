# shellcheck source=./helper/step_helper.sh
source "${__DIR}"/helper/step_helper.sh
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

function prepare() {
  if [[ ! -d ${LOCAL_DIR} ]]; then
    mkdir -p ${LOCAL_DIR}
  fi
}

function downloadFromS3() {
  # Download
  if [[ "${DRYRUN}" -eq 1 ]] && ! aws s3 cp "${S3_PATH}" "${LOCAL_PATH}"; then
    # Is file exists?
    if ! aws s3 ls "${S3_PATH}" 1> "${LOCAL_PATH}.info" 2> /dev/null; then
      __msg_error "File on S3 not exists! S3 path: ${S3_PATH}"
      return "${FAILURE}"
    fi

    __msg_error "S3 file exists & download failed!"
    return "${FAILURE}"
  fi
}

# Only try to download in case AWS credentials exits.
if [[ "${ADEBUG}" -eq 0 ]] && [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  __msg_info "Download will be not executed! Reason: --debug option enabled & no AWS credentials provided."
  DRYRUN=0
fi

prepare
downloadFromS3

# Copy file to be able compare (during debug)
cp ${LOCAL_PATH} ${LOCAL_PATH}.original

# Restore DRYRUN
postAction