# shellcheck source=./helper/skip.sh
source "${__DIR}"/helper/skip.sh
# shellcheck source=./helper/channel.sh
source "${__DIR}"/helper/channel.sh

__FILE_PATH="${__DIR}/$(basename "${BASH_SOURCE[0]}")"
__FILE=${__FILE_PATH##*/} # Remove everything from the last  '/' char backwards
__STEP=${__FILE%%_*}      # Remove everything from the first '_' char onwards

# "0" = true (we need to skip)
if [[ $(_isSkippedStep "${__STEP}") == "0" ]]; then
  __msg_info "SKIP STEP ${__STEP}"
  return "${SUCCESS}"
fi

if [[ -f "$(__get_asset_path "channels.csv")" ]]; then
  # shellcheck disable=SC2013
  for channel in $(cat "$(__get_asset_path "channels.csv")"); do
    if [[ ${channel:0:1} != "#" ]]; then
      NAME=$(echo "${channel}" | cut -d';' -f1)
      COMMENT="# ${NAME}"
      FILENAME="$(echo "${NAME}" | tr "[:upper:]" "[:lower:]")"
      URL=$(echo "${channel}" | cut -d';' -f2)

      export COMMENT
      export FILENAME
      export URL

      if ! curl -Is "${URL}" | grep -q 'location:'; then # redirect => channel not working anymore
        # Process the channel
        __msg_info "Process: ${NAME} \n"
        source "${__DIR}"/helper/"$(echo "${channel}" | cut -d';' -f3)".sh

      # Only remove if $COMMENT (channel) still exists in .m3u file
      elif grep -q "^${COMMENT}$" "${LOCAL_PATH}"; then
        __msg_info_color "--url-redirect: channel NOT available: ${NAME}!"
        # @todo send an e-mail to inform the maintainer!
        __msg_info "--2_replace.sh: disableChannel: ${COMMENT}"
        disableChannel "${COMMENT}"
      fi
    fi
  done
else
  __msg_info "'channels.csv' file was not found!"
fi
