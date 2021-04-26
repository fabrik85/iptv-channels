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

function prepare() {
  if [[ ! -d ${LOCAL_DIR} ]]; then
    mkdir -p "${LOCAL_DIR}"
  fi
}

function downloadFromS3() {
  local s3_path="${1}"
  local disk_path="${2}"

  # Download
  if [[ "${DRY_RUN}" -ne 0 ]] && ! aws s3 cp "${s3_path}" "${disk_path}"; then
    # Is file exists?
    if ! aws s3 ls "${s3_path}" 1> "${disk_path}.info" 2> /dev/null; then
      __msg_error "File on S3 not exists! S3 path: ${s3_path}"
      return "${FAILURE}"
    fi

    __msg_error "S3 file exists & download failed!"
    return "${FAILURE}"
  fi
}

# Only try to download in case AWS credentials exits.
if [[ "${ADEBUG}" -eq 0 ]] && [[ -z "${AWS_ACCESS_KEY_ID:-}" || -z "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
  __msg_info "Download will be not executed! Reason: --debug option enabled & no AWS credentials provided."
  DRY_RUN=0

  __msg_info "Copy local file ${ROOT_DIR}/develop/channels.yml to ${LOCAL_YAML_PATH}"
  cp "${ROOT_DIR}"/develop/channels.yml "${LOCAL_YAML_PATH}"
fi

prepare
downloadFromS3 "${S3_YAML_PATH}" "${LOCAL_YAML_PATH}"
# Restore DRY_RUN value
postAction
