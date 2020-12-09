#!/bin/sh

function exitWithUsage() {
  echo "NAME"
  echo "     Hungarian IPTV list (.m3u8) generator."
  echo ""
  echo "DESCRIPTION"
  echo "     Create new HLS file for Hungarian free to air senders."
  echo ""
  echo "SYNOPSIS"
  echo ""
  echo "Usage: COMMAND [OPTION]"
  echo ""
  echo "     create [--dry-run] [--skip-steps]"
  echo "            Create new HLS file."
  echo "     update [--dry-run] [--skip-steps]"
  echo "            Update existing HLS file."
  echo "     sleep [--second]"
  echo "            Do nothing else just sleep for x second(s)."
  echo ""
  echo "OPTIONS"
  echo "     --dry-run"
  echo "            Simulate command without any effect."
  echo "     --skip-steps"
  echo "            Skip the defined execute script (step file)."
  echo "     --second"
  echo "            Sleep the defined [x] second(s) (only for 'sleep' command)"
  echo ""
  echo ""
  echo "EXAMPLE"
  echo "     docker run --rm --name iptv docker.bestfabrik.de/iptv create --dry-run"
  echo ""
  echo "     docker run --rm --name iptv docker.bestfabrik.de/iptv sleep --second=30"
  exit 2
}

function main() {
  local command=${1}
  local options
  local valid_arguments

  local dry_run
  local skip_steps
  local second

  # Process config values.
  options=$(getopt -n docker-entrypoint -o s:d: --long skip-steps:,second:,dry-run, -- "${@:2}")
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
      --second)
        second="${2}" ; shift 2
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
  [[ -n "${dry_run}" ]] && args+=( "--noop" )
  [[ -n "${second}" ]] && args+=( "--second=${second}" )

  # Trigger the relevant command.
  case "${command}" in
    "sleep")
      # Keep the container running for x second(s) to be able to debug.
      sleep ${second}
      ;;
    "create")
      /home/src/main.sh --action=create_hls "${args[@]}"
      ;;
    "update")
      /home/src/main.sh --action=update_hls "${args[@]}"
      ;;
    *)
      exitWithUsage
      ;;
  esac
}

main "$@"