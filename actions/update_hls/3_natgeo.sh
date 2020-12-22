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
    local natGeoUrl;

    # Print everything till the search pattern +1 line
    awk '1;/# NatGeo.*/{getline;print;exit}' ${LOCAL_PATH} > ${LOCAL_PATH}.modified

    # Store URL in a variable
    natGeoUrl=$(grep -A1 '#EXTINF:-1,(#1)' ${LOCAL_DIR}/natgeo.m3u8 | tail -1) # grep the search pattern +1 line | print last line

    # Append the new URL to the end of the file
    echo ${natGeoUrl} >> ${LOCAL_PATH}.modified

    # Print everything from pattern | print everything from line number 2
    awk 'x==1 {print}/# NatGeo.*/ {x=1}' ${LOCAL_PATH} | awk 'FNR > 2 {print}' >> ${LOCAL_PATH}.modified
}

function replaceFile() {
  rm ${LOCAL_PATH}
  mv ${LOCAL_PATH}.modified ${LOCAL_PATH}
}

# "0" = true
# "1" = false
function isNatGeoUrlChanged() {
    local actualUrl;
    local natGeoUrl;

    actualUrl=$(grep -A2 '# NatGeo' ${LOCAL_PATH} | tail -1) # grep the search pattern +2 lines | print last line

    # Download NatGeo .m3u8
    curl -o ${LOCAL_DIR}/natgeo.m3u8 ${NATGEO}

    # Store the new URL in a variable
    natGeoUrl=$(grep -A1 '#EXTINF:-1,(#1)' ${LOCAL_DIR}/natgeo.m3u8 | tail -1) # grep the search pattern +1 line | print last line

    # Compare 2 URL
    if [[ $actualUrl != $natGeoUrl ]]; then
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
if [[ $(isNatGeoUrlChanged) == "0" ]]; then
  createNewFile
  replaceFile
  __msg_info "NatGeo updated!"
  
  return "${SUCCESS}"
fi
