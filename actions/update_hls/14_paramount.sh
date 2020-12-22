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
CHANNEL="# Paramount Channel"
FILENAME="paramount.m3u8"
URL=${PARAMOUNT}

# shellcheck source=./helper/m3u8.sh
source "${__DIR}"/helper/m3u8.sh
