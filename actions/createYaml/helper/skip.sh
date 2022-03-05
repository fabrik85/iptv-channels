# @param  string $1 (step_number)
# @return string (0=true, 1=false)
function _isSkippedStep() {
  local step_number="${1}"
  local step
  local skip_steps=()
  local result=1

  if [[ -n "${SKIP}" ]]; then
    while IFS='' read -r line; do skip_steps+=("$line"); done < <(echo "${SKIP}" | tr ":" "\n")

    for step in "${skip_steps[@]}"; do
      if [[ "${step}" == "${step_number}" ]]; then
        result=0
        break
      fi
    done
  fi

  echo "${result}"
}
