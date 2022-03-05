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

function createTyml() {
  local channel="${1}"
  local increment="${2}"
  local download_uri="${3:-}"
  local id name tpl type epg logo stream download
  local filename

  id=$(echo "${channel}" | jq -r -c '.id')
  name=$(echo "${channel}" | jq -r -c '.name')
  tpl=$(echo "${channel}" | jq -r -c '.tpl')
  type=$(echo "${channel}" | jq -r -c '.type')
  epg=$(echo "${channel}" | jq -r -c '.epg')
  logo=$(echo "${channel}" | jq -r -c '.logo')
  download=$(echo "${channel}" | jq -r -c '.download')
  stream=$(echo "${channel}" | jq -r -c '.stream')

  # Use URI from the web instead of the source yaml
  if [[ -n "${download_uri}" ]] && [[ "${download_uri}" != "null" ]] && [[ "${download}" != "${download_uri}" ]]; then
    __msg_info "Replace download '${download}' with '${download_uri}'"
    download="${download_uri}"
  fi

  local download_comment; download_comment="#"
  local stream_comment; stream_comment="#"

  if [[ -n "${download}" ]] && [[ "${download}" != "null" ]]; then
    download_comment=""
  fi

  if [[ -n "${stream}" ]] && [[ "${stream}" != "null" ]]; then
    stream_comment=""
  fi

  filename=$(printf "%03d_%s.tyml" "${increment}" "${id}")
  __msg_info "Create: ${filename} \n"

  # Escape slashes
  download=$(echo "$download" | sed 's/\//\\\//g');
  stream=$(echo "$stream" | sed 's/\//\\\//g');
  logo=$(echo "$logo" | sed 's/\//\\\//g');
  # Escape ampersands
  download=${download//&/\\&}
  stream=${stream//&/\\&}
  logo=${logo//&/\\&}

  cp "${__DIR}"/template/tv.yml.tpl "${LOCAL_DIR}"/"${filename}"
  sed -i -e "s/{ID}/${id}/g" \
      -e "s/{NAME}/${name}/g" \
      -e "s/{TPL}/${tpl}/g" \
      -e "s/{TYPE}/${type}/g" \
      -e "s/{EPG}/${epg}/g" \
      -e "s/{LOGO}/${logo}/g" \
      -e "s/{DOWNLOAD_COMMENT}/${download_comment}/g" \
      -e "s/{STREAM_COMMENT}/${stream_comment}/g" \
      -e "s/{DOWNLOAD}/${download}/g" \
      -e "s/{STREAM}/${stream}/g" \
      "${LOCAL_DIR}"/"${filename}"
}

function main() {
  local channels
  local yaml
  local channel
  local i
  local onlinestream
  local uri

  __msg_debug "Source channels file = ${SOURCE_YAML_PATH}"

  yaml=$(cat "${SOURCE_YAML_PATH}")
  i=0

  echo "${yaml}" | yaml2json | jq -r -c '.tv[]?' | while read -r channel; do
    i=$((i + 1))
    name=$(echo "${channel}" | jq -r -c '.name')
    stream=$(echo "${channel}" | jq -r -c '.stream')
    onlinestream=$(echo "${channel}" | jq -r -c '.onlinestream')

    # If 'stream' is defined add it without checking 'onlinestream' match
    if [[ -n "${stream}" ]] && [[ "${stream}" != "null" ]]; then
      __msg_debug "Ignore checking onlinestream for ${name}"
      createTyml "${channel}" "${i}";
      continue;
    fi

    __msg_debug "Searching match for ${name}"

    channels=$(cat "${LOCAL_DIR}/tv.html" | pup 'span.allomasnev .allomasnev_allomasnev text{}')
    while IFS= read -r line; do
      #... M1 ...
      #... M2 / Petőfi TV ...
      #... M3 ...
      #... M4 Sport ...
      #echo "... $line ..."
      __msg_debug "  --> Compare '${onlinestream}' with '${line}'"

      if [[ -n "${onlinestream}" ]] && [[ "${onlinestream}" != "null" ]] && [[ "${line}" == "${onlinestream}" ]]; then
        __msg_debug "  --> MATCH FOUND!"

        # Get up-to-date 'download: $uri' part.
        uri=$(cat "${LOCAL_DIR}/tv.html" | pup ':parent-of(:parent-of(:parent-of(.allomasnev_allomasnev:contains("'"${line}"'")))) td.letoltes li a attr{href}' | head -n 1)

        if grep -q '.xspf\|.m3u' <<< "${uri}"; then
          __msg_debug "  --> MATCH URI = https://onlinestream.live${uri}"
          createTyml "${channel}" "${i}" "https://onlinestream.live${uri}";
        else
          createTyml "${channel}" "${i}";
        fi
#        cat develop/tv.html | pup ':parent-of(:parent-of(:parent-of(.allomasnev_allomasnev:contains("TV2")))) td.letoltes li a attr{href}' | head -n 1
#        https://onlinestream.live
        break;
      fi
    done <<< "$channels"

  done
}

main "$@"
