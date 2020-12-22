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

# Comment line in siptv.m3u over the HLS definition.
CHANNEL="# Spektrum"
FILENAME="spektrum.m3u8"
URL=${SPEKTRUM}

# handle --debug option
if [[ "${ADEBUG}" -eq 0 ]] && [[ ! -f ${LOCAL_PATH} ]]; then
  __msg_error "File ${LOCAL_PATH} does not exists! Make sure you provide the file in --debug mode!"
  return "${FAILURE}"
fi

# Download the channel's source file.
curl -o ${LOCAL_DIR}/${FILENAME} ${URL}

# Store the channel IPTV address.
SOURCE_URL=$(grep -A1 '#EXTM3U' ${LOCAL_DIR}/${FILENAME} | tail -1)

# Update channel address.
if [[ $(updateChannelAddress "${CHANNEL}" "${SOURCE_URL}") == "0" ]]; then
  __msg_info "${CHANNEL} Updated!"
  return "${SUCCESS}"
fi
