declare -a SEQUENCE
declare -A STATUS
declare -A RUNTIME

export SUCCESS_MSG="SUCCESS"
export ERROR_MSG="FAILED"
export UNKNOWN_MSG="UNKNOWN_EXCEPTION"
export OVERALL_RESULT="$SUCCESS_MSG"
export LOG_DIR=""

PFRED=$'\e[1;31m'
PFGRN=$'\e[1;32m'
PFYEL=$'\e[1;33m'
#PFBLU=$'\e[1;34m'
PFMAG=$'\e[1;35m'
PFCYN=$'\e[1;36m'
PFEND=$'\e[0m'

### ======================= ###
###   Message with colour   ###
### ======================= ###
function __msg_yellow() {
  printf "%s\n" "${PFYEL}$*${PFEND}"
}

function __msg_green() {
  printf "%s\n" "${PFGRN}$*${PFEND}"
}

function __msg_red() {
  printf "%s\n" "${PFRED}$*${PFEND}"
}

function __msg_cyan() {
  printf "%s\n" "${PFCYN}$*${PFEND}"
}

function __msg_magenta() {
  printf "%s\n" "${PFMAG}$*${PFEND}"
}

### ======================= ###
###    Message with type    ###
### ======================= ###
function __msg_info() {
  printf "%s\n" "[INFO]: $*"
}

function __msg_error() {
  __msg_red "[ERROR]: $*"
}

function __msg_warning() {
  __msg_magenta "[WARNING]: $*"
}

function __msg_debug() {
  if [[ "${__DEBUG:-}" -eq 0 ]]; then
    __msg_cyan "[DEBUG]: $*"
  fi
}

function __msg_info_green() {
  __msg_green "[INFO]: $*"
}

function __msg_info_green_white() {
  echo -e "\e[1;97;42m[INFO]: $*\e[0m"
}

### ======================= ###
###   Framework Functions   ###
### ======================= ###
# ${1} - Filename
function __get_asset_path() {
  echo "${ROOT_DIR}/actions/${ACTION}/asset/${1}"
}

function __get_property() {
  local property_value

  property_value=$(echo "${YAML}" | yaml2json - | jq -r --arg PROPERTY "$1" '.vars | .[$PROPERTY]')
  echo "$property_value"
}

function checkNotificationConfig() {
  local is_config_defined

  is_config_defined=$(echo "${YAML}" | yaml2json - | jq -r ".${ACTION}.notify.${1}")

  if [[ "$is_config_defined" == "true" ]]; then
      __msg_debug "Notification set to 'true'.. Will trigger an alert.."
      return "${SUCCESS}"
  else
      __msg_debug "Notification set to 'false'.. Will NOT trigger an alert.."
      return "${FAILURE}"
  fi
}

#shellcheck disable=SC2086,SC2005
function sendEmail() {
  local action_phase
  local options
  local mail_subject

  action_phase=$([[ "${1}" == "at_start" ]] && echo "Started" || echo "Completed")
  options="|"

  for arg in $(echo "${UNKNOWN_ARGS}"); do
    options+=" $(echo $arg | cut -d '=' -f2) |"
  done

  mail_subject="${action_phase}: ${ACTION} ${options}"
  __msg_debug "Send Email: '${EMAIL_LIST}' with subject '${mail_subject}'"

  if [[ -f "${LOG_DIR}/MYSQL_IMPORT_LOG.txt" ]] && [[ -f "${LOG_DIR}/RUN_LOG.txt" ]]; then
    __msg_debug "Sending mail with attachments"
    echo "$(printSummary)"                                    |\
        mutt                                                 \
        -e 'set content_type="text/html"'                    \
        -e "my_hdr From: iptv.bestfabrik.de <info@bestfabrik.de>" \
        -s "${mail_subject}"                                 \
        -a "${LOG_DIR}/RUN_LOG.txt"                          \
        -a "${LOG_DIR}/MYSQL_IMPORT_LOG.txt" -- ${EMAIL_LIST}
  elif [[ -f "${LOG_DIR}/RUN_LOG.txt" ]]; then
    __msg_debug "Sending mail with attachment"
    echo "$(printSummary)"                                    |\
        mutt                                                 \
        -e 'set content_type="text/html"'                    \
        -e "my_hdr From: iptv.bestfabrik.de <info@bestfabrik.de>" \
        -s "${mail_subject}"                                 \
        -a "${LOG_DIR}/RUN_LOG.txt" -- ${EMAIL_LIST}
  else
    __msg_debug "Sending mail without attachment"
    echo "$(printSummary)"                                    |\
        mutt                                                 \
        -e 'set content_type="text/html"'                    \
        -e "my_hdr From: iptv.bestfabrik.de <info@bestfabrik.de>" \
        -s "${mail_subject}"  -- ${EMAIL_LIST}
  fi
}

# ${1} - ?
# ${2} - ?
function triggerSlackHook() {
  curl -X POST \
    --data-urlencode "payload=$(printSlackSummary "${1}")" \
    "${2}"
}

# ${1} - ?
function sendSlackNotification() {
  local slack_webhook
  local failure_flag_status

  # Do nothing for 'at_start' notification for Slack
  if [[ "${1}" == "at_start" ]]; then
    __msg_debug "at_start notification for slack.. won't do anything"
    return "${SUCCESS}"
  fi

  __msg_debug "Continuing further with slack notification for ${1}...."

  slack_webhook="$(echo "${YAML}" | yaml2json - | jq -r ".${ACTION}.notify.slack.webhook")"
  failure_flag_status="$(echo "${YAML}" | yaml2json - | jq -r ".${ACTION}.notify.slack.only_on_failure")"

  __msg_debug "Checking for slack configurations..."

  if [[ "${slack_webhook}" != "null" ]]; then
    if [[ "${failure_flag_status}" != "null" && "${failure_flag_status}" == "true" ]]; then
      if [[ "${OVERALL_RESULT}" != "${SUCCESS_MSG}" ]]; then
        __msg_debug "Failure condition triggered..Sending slack notification"
        triggerSlackHook "${1}" "${slack_webhook}"
      fi
    else
      triggerSlackHook "${1}" "${slack_webhook}"
    fi
  else
    __msg_debug "'slack_webhook' is not defined in the config. Cannot proceed with Slack notification."
  fi
}

# ${1} - Email Address
function triggerNotification() {
  local slack_definitions

  # Prevent sending notification under local development
  if [[ "${ENV:-}" == 'dev' ]]; then
    return 0
  fi

  __msg_debug "Trigger => notify:${1}"

  if checkNotificationConfig "${1}"; then
      EMAIL_LIST=""
      for mail in $(echo "${YAML}" | yaml2json - | jq -r ".${ACTION}.notify.email.list[]"); do
        [[ -z "${EMAIL_LIST}" ]] && EMAIL_LIST="${mail}" || EMAIL_LIST="${EMAIL_LIST} ${mail}"
      done

      __msg_debug "Emails: ${EMAIL_LIST}"

      if [[ -n "${EMAIL_LIST}" ]]; then
        failure_flag_status="$(echo "${YAML}" | yaml2json - | jq -r ".${ACTION}.notify.email.only_on_failure")"
        if [[ "${failure_flag_status}" != "null" && "${failure_flag_status}" == "true" ]]; then
          __msg_debug "'only_on_failure' flag is set and value is '${failure_flag_status}'"
          if [[ "${OVERALL_RESULT}" != "${SUCCESS_MSG}" ]]; then
            __msg_debug "Failure condition triggered. Sending email..."
            sendEmail "${1}"
          fi
        else
          __msg_debug "'only_on_failure' flag was either not declared OR was set to a value different than 'true'"
          sendEmail "${1}"
        fi
      fi

      slack_definitions="$(echo "${YAML}" | yaml2json - | jq -r ".${ACTION}.notify.slack")"
      __msg_info "Got slack definition block as ${slack_definitions}"

      if [[ "$slack_definitions" != "null" ]]; then
        __msg_info "Sending slack notification..."
        sendSlackNotification "${1}"
      else
        __msg_debug "Slack configurations not found."
      fi
  else
    __msg_debug "Notification alert NOT configured for '${1}'"
  fi
}

# shellcheck source=/dev/null
function run() {
  local file="${1}"
  local args="${2:-}"
  local cols

  if [ -t 0 ]; then
    # tty => safe to use 'tput' command
    cols="${COLUMNS:-$(tput cols)}"
  else
    cols="${COLUMNS:-80}"
  fi

  # print console wide (or 80) = character
  printf '\n%*s\n' "${cols}" '' | tr ' ' =

  file="${ROOT_DIR}/actions/${ACTION}/${file}"
  printf "\n";
  __msg_yellow "[START]: Execute: '${file}' '${args}'"
  printf "\n"

  local filepath="${file:-}"

  [[ -z "$filepath" ]] && return "${FAILURE}"
  filename="$(basename "${filepath}")"
  STATUS[$filename]="STARTED"
  SEQUENCE+=("${filename}")
  # Run the relevant step (e.g. 1_set_lock.sh)
  { time source "${filepath}" "${args}"; }
  local status_code=$?

  if [[ "$status_code" == "0" ]]; then
    STATUS[$filename]="$SUCCESS_MSG";
    local run_time
    run_time="$(tac "${LOG_DIR}/RUN_LOG.txt" | grep -m1 "real")"
    RUNTIME[$filename]="${run_time//real/}";
    printf "\n"
    __msg_yellow "[END]: Success - ${file}"

    return "${SUCCESS}";
  else
    local run_time
    run_time="$(tac "${LOG_DIR}/RUN_LOG.txt" | grep -m1 "real")"
    RUNTIME[$filename]="${run_time//real/}";
    STATUS[$filename]="$ERROR_MSG";
    printf "\n"
    __msg_red "[END]: Failed - ${file}"

    return "${FAILURE}";
  fi
}

function getSlackJsonBlock() {
  declare -a script_statuses=()

  for key in "${SEQUENCE[@]}"; do
    script_statuses[${#script_statuses[@]}]="${STATUS[$key]} - ${RUNTIME[$key]}"
  done

  cat<<-JSON
	{
		"type": "mrkdwn",
		"text": "$( IFS=$'\n'; echo "${SEQUENCE[*]}" )"
	},
	{
		"type": "mrkdwn",
		"text": "$( IFS=$'\n'; echo "${script_statuses[*]}")"
	}
JSON
}

function getSlackFooter() {
  echo "HLS Generator | info: <https://iptv.bestfabrik.de>"
}

function printSlackSummary() {
  if [[ "${1}" == "at_start" ]]; then
      slack_msg_header="STARTED : Operation ${ACTION}"
  else
    if [[ "${OVERALL_RESULT}" == "${SUCCESS_MSG}" ]]; then
      slack_msg_header=":white_check_mark: Status report for *${ACTION}* | *${UNKNOWN_ARGS}*"
    else
      slack_msg_header=":x: Status report for *${ACTION}* | *${UNKNOWN_ARGS}*"
    fi
  fi

  #slack_msg_body="$(get_slack_msg_body)"
  slack_msg_footer="$(getSlackFooter)"
  cat <<-SLACK
            {
                "blocks": [
                  {
                          "type": "section",
                          "text": {
                                  "type": "mrkdwn",
                                  "text": "${slack_msg_header}"
                          }
                  },
                  {
                          "type": "divider"
                  },
                  {
                          "type": "section",
			  "fields": [
			  	{
					"type": "mrkdwn",
					"text": "*Script Name*"
				},
				{
					"type": "mrkdwn",
					"text": "*Status*"
				},
				$(getSlackJsonBlock)
			  ]
                  },
                  {
                          "type": "divider"
                  },
                  {
                          "type": "context",
                          "elements": [
                                  {
                                          "type": "mrkdwn",
                                          "text": "${slack_msg_footer}"
                                  }
                          ]
                  }
                ]
}
SLACK
}

function printSummary() {
  # Check is SEQUENCE array is defined and non-empty
  if [[ -v SEQUENCE[@] && ${#SEQUENCE[@]} -gt 0 ]]; then
    ROW=""
    BODY=""

    for script in "${SEQUENCE[@]}"; do
      ROW="<td>${script}</td><td>${STATUS[$script]}</td><td>${RUNTIME[$script]}</td>"
      BODY="${BODY}<tr>${ROW}</tr>"
    done

    TITLE="$(echo "${ACTION}" | tr "[:lower:]" "[:upper:]") execution report"
    cat <<-EOF
	<html>
	<style>
		table {
			font-family: arial, sans-serif;
			border-collapse: collapse;
			width: 100%;
		}

		td, th {
			border: 1px solid #dddddd;
			text-align: left;
			padding: 8px;
		}

		tr:nth-child(even) {
			background-color: #dddddd;
		}
	</style>
	<body>
    		<h3>${TITLE}</h3>
    		<table>
      			<tr><th>Step</th><th>Status</th><th>Duration</th></tr>
      			${BODY}
    		</table>
	</body>
	</html>
EOF
  else
    __msg_info "Started '${ACTION}'"
  fi
}
