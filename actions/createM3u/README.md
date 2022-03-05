# Create IPTV Playlist (.m3u file)
This action is creating an .m3u playlist stored in AWS S3

## How it's working?
1. Download playlist definition `.yml` file from AWS S3 bucket (maintained channel lists)

    For local development it copies `/develop/channels.yml` instead of AWS S3 download.

2. Gather all channels which needs to be updated. (defined in `channels.yml`)

3. Write output into an `.m3u` file (playlist)

## How to use it?

`./main.sh --action=create --dryrun --debug`

### Options:

    --dryrun          (dry run without any permanent change)
    --skip-steps=1:2  (do not execute 1_[name].sh during run)
    --debug           (print extra debug messages)

### Environment Variables

* ENV
  ```
  application environment (e.g. docker-compose will set it to ENV=dev)
  ```
* AWS_ACCESS_KEY_ID
* AWS_SECRET_ACCESS_KEY
