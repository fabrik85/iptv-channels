# shellcheck source=./helper/step_helper.sh
source "${__DIR}"/helper/step_helper.sh
# shellcheck source=./helper/channel_helper.sh
source "${__DIR}"/helper/channel_helper.sh

__FILE_PATH="${__DIR}/$(basename "${BASH_SOURCE[0]}")"
__FILE=${__FILE_PATH##*/} # Remove everything from the last  '/' char backwards
__STEP=${__FILE%%_*}      # Remove everything from the first '_' char onwards

# "0" = true (we need to skip)
if [[ $(_isSkippedStep "${__STEP}") == "0" ]]; then
  __msg_info "SKIP STEP ${__STEP}"
  return "${SUCCESS}"
fi

# handle --debug option
if [[ "${ADEBUG}" -eq 0 ]] && [[ ! -f ${LOCAL_PATH} ]]; then
  __msg_error "File ${LOCAL_PATH} does not exists! Make sure you provide the file in --debug mode!"
  return "${FAILURE}"
fi

# Download the channel's source file.
curl -o ${LOCAL_DIR}/spektrumHome.xspf ${SPEKTRUM_HOME_URL}

# Store the channel IPTV address.
sourceUrl=$(awk 'gsub(/<location>|<\/location>/,x)' ${LOCAL_DIR}/spektrumHome.xspf)

# Update channel address.
if [[ $(isChannelAddressChanged "# Spektrum Home" "${sourceUrl}") == "0" ]]; then
  createNewHLSFile "# Spektrum Home" "${sourceUrl}"

  # Overwrite existing HLS file.
  mv ${LOCAL_PATH}.modified ${LOCAL_PATH}

  __msg_info "Spektrum Home Updated!"
  return "${SUCCESS}"
fi