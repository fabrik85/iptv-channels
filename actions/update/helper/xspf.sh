# handle --debug option
if [[ "${ADEBUG}" -eq 0 ]] && [[ ! -f ${LOCAL_PATH} ]]; then
  __msg_error "File ${LOCAL_PATH} does not exists! Make sure you provide the file in --debug mode!"
  return "${FAILURE}"
fi

# Download the channel's source file.
if ! curl -o "${LOCAL_DIR}/${FILENAME}" "${URL}"; then
  __msg_error "${NAME} download failed! URL: ${URL}"
  return "${FAILURE}"
fi

# Check file size (it will be 0 in case the channel source removed).
if [[ $(du -k "${LOCAL_DIR}/${FILENAME}" | cut -f1) -le 1 ]]; then
  __msg_info_color "--xspf.sh: No channel source for: ${NAME}!"
  # @todo send an e-mail to inform the maintainer!
  __msg_info "--xspf.sh: DISABLE Channel: ${COMMENT}"
  disableChannel "${COMMENT}"

# Check if pattern (e.g. #EXTM3U) exits in downloaded file.
elif [[ -z $(awk 'gsub(/<location>|<\/location>/,x)' "${LOCAL_DIR}/${FILENAME}") ]]; then
  __msg_info_color "--xspf.sh: SOURCE_URL empty! Search pattern: ${SEARCH_PATTERN}!"
  __msg_info "--xspf.sh: DISABLE Channel: ${COMMENT}"
  disableChannel "${COMMENT}"

# Try to update stream link.
else
  # Enable channel before try to update
  if grep -q "^# OFF ${NAME}$" "${LOCAL_PATH}"; then
    __msg_info_color "--xspf.sh: ENABLE Channel: ${COMMENT}"
    enableChannel "${COMMENT}"
  fi

  # Store the channel IPTV address.
  SOURCE_URL=$(awk 'gsub(/<location>|<\/location>/,x)' "${LOCAL_DIR}/${FILENAME}")

  # Update channel address.
  if [[ $(updateChannelAddress "${COMMENT}" "${SOURCE_URL}") == "0" ]]; then
    __msg_info "${NAME} Updated!"
    return "${SUCCESS}"
  fi
fi
