# Store $DRY_RUN state.
GLOBAL_DRY_RUN=${DRY_RUN}

function postAction() {
  DRY_RUN=${GLOBAL_DRY_RUN}
}