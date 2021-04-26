# shellcheck source=./helper/skip.sh
source "${__DIR}"/helper/skip.sh
# shellcheck source=./helper/post_action.sh
source "${__DIR}"/helper/post_action.sh

__FILE_PATH="${__DIR}/$(basename "${BASH_SOURCE[0]}")"
__FILE=${__FILE_PATH##*/} # Remove everything from the last  '/' char backwards
__STEP=${__FILE%%_*}      # Remove everything from the first '_' char onwards

# "0" = true (we need to skip)
if [[ $(_isSkippedStep "${__STEP}") == "0" ]]; then
  __msg_info "SKIP STEP ${__STEP}"
  return "${SUCCESS}"
fi

function getRemoteStreamURL() {
  local id="${1}"
  local type="${2}"
  local link="${3}"

  if ! curl -Is "${link}" | grep -q 'location:'; then # redirect => channel not working anymore
    __msg_info "Process: ${id} \n"
    source "${__DIR}"/helper/"${type}".sh

    # Download remote file (channel stream URL)
    if ! curl -o "${LOCAL_DIR}/${id}" "${link}"; then
      __msg_error "${id} download failed! URL: ${link}"
      return "${FAILURE}"
    fi

    # Check file size (it will be 0 in case the channel source removed).
    if [[ $(du -k "${LOCAL_DIR}/${id}" | cut -f1) -le 1 ]]; then
      __msg_info_color "Channel source: ${LOCAL_DIR}/${id} is empty!"
    # Check if pattern (e.g. #EXTM3U) exits in downloaded file.
    elif [[ "${type}" != "xspf" ]] && [[ -z $(grep -A1 "${SEARCH_PATTERN}" "${LOCAL_DIR}/${id}" | tail -1) ]]; then
      __msg_info_color "Search pattern '${SEARCH_PATTERN}' not found in ${LOCAL_DIR}/${id}!"
    fi
  fi
}

function insertIntoM3u() {
  local channel="${1}"
  local increment="${2}"
  local id name tpl type epg logo stream download
  local filename

  id=$(echo "${channel}" | jq -r -c '.id')
  name=$(echo "${channel}" | jq -r -c '.name')
  tpl=$(echo "${channel}" | jq -r -c '.tpl')
  type=$(echo "${channel}" | jq -r -c '.type')
  epg=$(echo "${channel}" | jq -r -c '.epg')
  logo=$(echo "${channel}" | jq -r -c '.logo')
  stream=$(echo "${channel}" | jq -r -c '.stream')
  download=$(echo "${channel}" | jq -r -c '.download')

  if [[ -n "${download}" ]] && [[ "${download}" != "null" ]]; then
    getRemoteStreamURL "${id}" "${type}" "${download}"
    # Store the channel IPTV address.
    if [[ "${type}" == "xspf" ]]; then
      stream=$(awk "${SEARCH_PATTERN}" "${LOCAL_DIR}/${id}")
    else
      stream=$(grep -A1 "${SEARCH_PATTERN}" "${LOCAL_DIR}/${id}" | tail -1)
    fi
  fi

  if [[ -n "${stream}" ]] && [[ "${stream}" != "null" ]]; then
    filename=$(printf "%03d_%s.tpl" "${increment}" "${id}")
    __msg_info "Create: ${filename} \n"

    # Escape slashes
    stream=$(echo "$stream" | sed 's/\//\\\//g');
    logo=$(echo "$logo" | sed 's/\//\\\//g');
    # Escape ampersands
    stream=${stream//&/\\&}
    logo=${logo//&/\\&}

    cp "${__DIR}"/template/"${tpl}".tpl "${LOCAL_DIR}"/"${filename}"
    sed -i -e "s/{ID}/${id}/g" \
        -e "s/{NAME}/${name}/g" \
        -e "s/{EPG}/${epg}/g" \
        -e "s/{LOGO}/${logo}/g" \
        -e "s/{STREAM}/${stream}/g" \
        "${LOCAL_DIR}"/"${filename}"
  fi
}

function create() {
  local yaml
  local channel
  local i

  find "${LOCAL_DIR}" -type f -not -name 'channels.yml' -delete

  yaml=$(cat "${LOCAL_YAML_PATH}")
  i=0
  echo "${yaml}" | yaml2json | jq -r -c '.tv[]?' | while read -r channel; do
    i=$((i + 1))
    insertIntoM3u "${channel}" "${i}";
  done

  echo -e "#EXTM3U\n" > "${LOCAL_PATH}"
  find "${LOCAL_DIR}" -type f -name "*.tpl" | sort | xargs cat >> "${LOCAL_PATH}"
}

create
