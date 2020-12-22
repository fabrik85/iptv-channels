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