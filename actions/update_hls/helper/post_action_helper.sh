# Store $DRYRUN state.
GLOBAL_DRYRUN=${DRYRUN}

function postAction() {
  DRYRUN=${GLOBAL_DRYRUN}
}