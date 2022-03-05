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

function download() {
  local target="${1}"

  # Is file exists?
  if [[ -f "${target}/"tv.html ]]; then
    __msg_info "File exists! Delete: ${target}/tv.html"
    rm -f "${target}/"tv.html
  fi

  wget 'https://onlinestream.live/?search=&broad=7&feat=&chtype=&server=&format=&sort=&fp=50&p=1' -O "${target}/"tv.html
  __msg_info_green "Download from https://onlinestream.live/tv successful!"
}

prepare

# Only try to download in case file not exits.
if [[ "${DRY_RUN}" -eq 0 ]] || [[ ! -f "${ROOT_DIR}"/develop/tv.html ]]; then
  __msg_debug "Download source code (.html)"
  download "${LOCAL_DIR}"
else
  __msg_debug "Download will be not executed! Reason: --dry-run option enabled."
  cp "${ROOT_DIR}"/develop/tv.html "${LOCAL_DIR}/tv.html"
fi

# Restore DRY_RUN value
postAction
