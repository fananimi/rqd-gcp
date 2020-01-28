#!/usr/bin/env bash

# mount nfs
mkdir -p "$NFS_DST"
mount "$NFS_IP":"$NFS_SRC" "$NFS_DST"
# start rqd daemon
rqd
