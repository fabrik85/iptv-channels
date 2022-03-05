#!/usr/bin/env bash

function exitWithUsage() {
  echo "NAME"
  echo "     Hungarian IPTV list (.m3u8) generator."
  echo ""
  echo "DESCRIPTION"
  echo "     Create new HLS file for Hungarian free to air senders."
  echo ""
  echo "SYNOPSIS"
  echo ""
  echo "  Usage: COMMAND [OPTION]"
  echo ""
  echo "     createm3u [--dry-run] [--skip-steps]"
  echo "            Create new HLS file."
  echo "     createyaml [--dry-run] [--skip-steps]"
  echo "            Create new YAML file. (Source of the HLS creation)."
  echo "     debug"
  echo "            Do nothing else just prevent exiting the container."
  echo ""
  echo "OPTIONS"
  echo "     --dry-run"
  echo "            Simulate command without any effect."
  echo "     --skip-steps"
  echo "            Skip the defined execute script (step file)."
  echo "     --debug"
  echo "            Debug option (e.g. disables AWS env var check, disable reporting (email, slack), etc...)."
  echo ""
  echo ""
  echo "EXAMPLE"
  echo "     docker run --rm --name iptv docker.bestfabrik.de/iptv create --dry-run"
  echo ""
  echo "     docker run --rm --name iptv docker.bestfabrik.de/iptv debug"
  echo ""
  echo "     docker run --rm --name iptv docker.bestfabrik.de/iptv update --skip-steps=2:3"
  exit 2
}

function main() {
  local command=${1}
  local options
  local valid_arguments

  local dry_run
  local skip_steps
  local debug

  # Process config values.
  options=$(getopt -n docker-entrypoint -o s:d: --long skip-steps:,sec:,dry-run,debug, -- "${@:2}")
  valid_arguments=$?
  if [[ "${valid_arguments}" != "0" ]]; then
    exitWithUsage
  fi

  # set shell's input arguments.
  eval set -- "${options}"

  while true;
  do
    case "${1}" in
      -d | --dry-run)
        dry_run="true" ; shift
        ;;
      -s | --skip-steps)
        skip_steps="${2}" ; shift 2
        ;;
      --debug)
        debug="true" ; shift
        ;;
      --)
        shift; break
        ;;
      *)
        exitWithUsage
        ;;
    esac
  done

  local args=( )

  [[ -n "${skip_steps}" ]] && args+=( "--skip-steps=${skip_steps}" )
  [[ -n "${dry_run}" ]] && args+=( "--dryrun" )
  [[ -n "${debug}" ]] && args+=( "--debug" )

  if [[ -z "${debug}" ]] && [[ -z "${AWS_ACCESS_KEY_ID}" ]]; then
    echo "Error: Required environment varibale 'AWS_ACCESS_KEY_ID' was not defined! (e.g. $ docker run -e AWS_ACCESS_KEY_ID=xxx)"
    exit 2
  fi

  if [[ -z "${debug}" ]] && [[ -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
    echo "Error: Required environment varibale 'AWS_SECRET_ACCESS_KEY' was not defined! (e.g. $ docker run -e AWS_SECRET_ACCESS_KEY=xxx)"
    exit 2
  fi

  if [[ -z "${debug}" ]] && [[ -z "${AWS_DEFAULT_REGION}" ]]; then
    echo "Error: Required environment varibale 'AWS_DEFAULT_REGION' was not defined! (e.g. $ docker run -e AWS_DEFAULT_REGION=eu-central-1)"
    exit 2
  fi

  if [[ -z "${debug}" ]] && [[ -z "${AWS_SES_SMTP_USER}" ]]; then
    echo "Error: Required environment varibale 'AWS_SES_SMTP_USER' was not defined! (e.g. $ docker run -e AWS_SES_SMTP_USER=xxx)"
    exit 2
  fi

  if [[ -z "${debug}" ]] && [[ -z "${AWS_SES_SMTP_PASS}" ]]; then
    echo "Error: Required environment varibale 'AWS_SES_SMTP_PASS' was not defined! (e.g. $ docker run -e AWS_SES_SMTP_PASS=xxx)"
    exit 2
  fi

  if [[ -z "${debug}" ]]; then
    sed -i -e "s/{SMTP-USER}/${AWS_SES_SMTP_USER}/g" \
      -e "s/{SMTP-PASS}/${AWS_SES_SMTP_PASS}/g" \
      -e "s/{REGION}/${AWS_DEFAULT_REGION}/g" \
      /root/.mutt/muttrc
  fi

  # Trigger the relevant command.
  case "${command}" in
    "debug")
      # Keep the container running for debugging (do nothing just prevent exiting the container).
      /usr/bin/tail -f /dev/null
      ;;
    "createm3u")
      /home/src/main.sh --action=createM3u "${args[@]}"
      ;;
    "createyaml")
      /home/src/main.sh --action=createYaml "${args[@]}"
      ;;
    *)
      exitWithUsage
      ;;
  esac
}

main "$@"