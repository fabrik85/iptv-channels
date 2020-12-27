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

# Store the channel IPTV address.
SOURCE_URL=$(grep -A1 "${SEARCH_PATTERN}" "${LOCAL_DIR}/${FILENAME}" | tail -1)

if [[ -z "${SOURCE_URL}" ]]; then
  __msg_info "SOURCE_URL empty! Search pattern: ${SEARCH_PATTERN}!"
fi

# Update channel address.
if [[ $(updateChannelAddress "${COMMENT}" "${SOURCE_URL}") == "0" ]]; then
  __msg_info "${NAME} updated! \n"
  return "${SUCCESS}"
else
  __msg_info "${NAME} is already up-to-date! \n"
fi