export PROJECT_DIR=".last-run"
export S3_BUCKET="bestfabrik.de"
export PLAYLIST="siptv.m3u"
export CHANNELS="channels.yml"

# e.g. /home/iptv
export LOCAL_DIR="${HOME}/${PROJECT_DIR}"
export LOCAL_FILE="${PLAYLIST}"

# siptv.m3u PATH
export LOCAL_PATH="${LOCAL_DIR}/${PLAYLIST}"
export S3_PATH="s3://${S3_BUCKET}/${PROJECT_DIR}/${PLAYLIST}"

# channels.yml PATH
export LOCAL_YAML_PATH="${LOCAL_DIR}/${CHANNELS}"
export S3_YAML_PATH="s3://${S3_BUCKET}/${PROJECT_DIR}/${CHANNELS}"