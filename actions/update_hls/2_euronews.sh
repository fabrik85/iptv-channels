# shellcheck source=./helper/step_helper.sh
source "${__DIR}"/helper/step_helper.sh

__FILE_PATH="${__DIR}/$(basename "${BASH_SOURCE[0]}")"
__FILE=${__FILE_PATH##*/} # Remove everything from the last  '/' char backwards
__STEP=${__FILE%%_*}      # Remove everything from the first '_' char onwards

# "0" = true (we need to skip)
if [[ $(_isSkippedStep "${__STEP}") == "0" ]]; then
  __msg_info "SKIP STEP ${__STEP}"
  return "${SUCCESS}"
fi

function createNewFile() {
    local euronewsUrl;

    # Print everything till the pattern: 'https://euro.*'
    #   - 'https://euro.*' will be the last line.
    awk '1;/https:\/\/euro.*/{exit}' ${LOCAL_PATH} > ${LOCAL_PATH}.modified

    # Remove 'https://euro.*' (last line)
    sed -i -e '$d' ${LOCAL_PATH}.modified

    # Store URL in a variable
    euronewsUrl=$(cat ${LOCAL_DIR}/euronews.m3u8 | awk 'FNR==2 { print }')

    # Append the new URL to the end of the file
    echo ${euronewsUrl} >> ${LOCAL_PATH}.modified

    # Print everything from pattern: 'https://euro.*'
    awk 'x==1 {print} /https:\/\/euro.*/ {x=1}' ${LOCAL_PATH} >> ${LOCAL_PATH}.modified
}

function replaceFile() {
  rm ${LOCAL_PATH}
  mv ${LOCAL_PATH}.modified ${LOCAL_PATH}
}

# "0" = true
# "1" = false
function isEuronewsUrlChanged() {
    local actualUrl;
    local euronewsUrl;

    actualUrl=$(grep 'https:\/\/euro.*' ${LOCAL_PATH})

    # Download Euronews .m3u8
    curl -o ${LOCAL_DIR}/euronews.m3u8 ${EURONEWS_M3U8_URL}

    # Store URL in a variable
    euronewsUrl=$(cat ${LOCAL_DIR}/euronews.m3u8 | awk 'FNR==2 { print }')

    # Compare 2 URL
    if [[ $actualUrl != $euronewsUrl ]]; then
        echo "0"
    else
        echo "1"
    fi
}

if [[ "${ADEBUG}" -eq 0 ]] && [[ ! -f ${LOCAL_PATH} ]]; then
  __msg_error "File ${LOCAL_PATH} does not exists! Make sure you provide the file in --debug mode!"
  return "${FAILURE}"
fi

# "0" = true
if [[ $(isEuronewsUrlChanged) == "0" ]]; then
  createNewFile
  replaceFile
  __msg_info "Euronews updated!"
  
  return "${SUCCESS}"
fi
