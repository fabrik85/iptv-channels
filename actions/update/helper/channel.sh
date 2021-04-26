# @param  string $1 channelId  (e.g. '# Pannon TV')
# @param  string $2 sourceUrl  (e.g. http://79.172.194.189/hls/pannonrtv/live.m3u8)
# @return string               (e.g. "0" => true, "1" => false)
function isChannelAddressChanged() {
  local channelId="${1}"
  local sourceUrl="${2}"
  # URL stored in S3 (.m3u file)
  local actualUrl;

  actualUrl=$(grep -A2 "^${channelId}$" "${LOCAL_PATH}" | tail -1) # grep the search pattern +2 lines | print last line
  # Compare 2 URL
  if [[ "${actualUrl}" != "${sourceUrl}" ]]; then
    echo "0"
  else
    echo "1"
  fi
}

# @param string $1 channelId  (e.g. '# Pannon TV')
# @param string $2 sourceUrl  (e.g. http://79.172.194.189/hls/pannonrtv/live.m3u8)
function createNewHLSFile() {
  local channelId="${1}"
  local sourceUrl="${2}"

    # Print everything till the search pattern +1 line
    awk '1;/'"^${channelId}$"'.*/{getline;print;exit}' "${LOCAL_PATH}" > "${LOCAL_PATH}.modified"

    # Append the new URL to the end of the file
    echo "${sourceUrl}" >> "${LOCAL_PATH}.modified"

    # Print everything from pattern | print everything from line number 2
    awk 'x==1 {print}/'"^${channelId}$"'.*/ {x=1}' "${LOCAL_PATH}" | awk 'FNR > 2 {print}' >> "${LOCAL_PATH}.modified"
}

# @param string $1 channelId  (e.g. '# Pannon TV')
# @param string $2 sourceUrl  (e.g. http://79.172.194.189/hls/pannonrtv/live.m3u8)
function updateChannelAddress() {
  local channelId="${1}"
  local sourceUrl="${2}"

  if [[ $(isChannelAddressChanged "${channelId}" "${sourceUrl}") == "0" ]]; then
    createNewHLSFile "${channelId}" "${sourceUrl}"
    # Overwrite existing HLS file.
    mv "${LOCAL_PATH}.modified" "${LOCAL_PATH}"
    echo "${SUCCESS}"
  else
    __msg_info "${NAME} is already up-to-date!"
  fi
}

# @param string $1 channelId (e.g. '# Pannon TV')
function disableChannel() {
  local channelId="${1}"

  # Print everything till the search pattern +1 line | remove last 2 lines
  awk '1;/'"^${channelId}$"'.*/{getline;print;exit}' "${LOCAL_PATH}" | head -n -2 > "${LOCAL_PATH}.modified"
  # Print '# OFF ${NAME}'
  awk '/'"^${channelId}$"'.*/{printf $1 FS "OFF" FS; for (i=2; i<=NF; i++){ if (i<NF) printf $i FS; else printf $i "\n";}; exit}' "${LOCAL_PATH}" >> "${LOCAL_PATH}.modified"
  # Print everything from pattern | print everything from line number 2
  awk 'x==1 {print}/'"^${channelId}$"'.*/ {x=1}' "${LOCAL_PATH}" | awk 'FNR > 2 {print}' >> "${LOCAL_PATH}.modified"

  mv "${LOCAL_PATH}.modified" "${LOCAL_PATH}"
}

# @param string $1 channelId (e.g. '# Pannon TV')
function enableChannel() {
  local channelId="${1}"
  local pattern="# OFF ${NAME}"

  # Print everything till the search pattern +1 line | remove last 2 lines
  awk '1;/'"^${pattern}$"'.*/{getline;print;exit}' "${LOCAL_PATH}" | head -n -2 > "${LOCAL_PATH}.modified"

  # Print commented channel name (e.g. '# Pannon TV')
  echo -e "${channelId}" >> "${LOCAL_PATH}.modified"

  # Print everything from pattern | use the first 2 lines only
  awk 'x==1 {print}/'"^${channelId}$"'.*/ {x=1}' "$(__get_asset_path "channels.m3u")" | head -n 2 >> "${LOCAL_PATH}.modified"

  # Print everything from pattern
  awk 'x==1 {print}/'"^${pattern}$"'.*/ {x=1}' "${LOCAL_PATH}" >> "${LOCAL_PATH}.modified"

  mv "${LOCAL_PATH}.modified" "${LOCAL_PATH}"
}