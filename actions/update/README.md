# Update channels stored in .m3u file 
This action is maintaining an existing .m3u file stored in AWS S3

## How it's working?

1. Download resources from AWS S3
    + download `.m3u` file from the bucket
    + download assets (e.g. maintained channel lists)
    

2. Gather all channels which needs to be updated.
