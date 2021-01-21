#!/usr/bin/env bash
mkdir -p $GCS_FUSE_MOUNT
gcsfuse --implicit-dirs -o rw,allow_other --uid 1000 --gid 1000 --dir-mode 777 --file-mode 777 $GCS_FUSE_BUCKET $GCS_FUSE_MOUNT

/bin/bash -c set -e && rqd
