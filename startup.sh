#!/usr/bin/env bash

# mount nfs
mkdir -p "$NFS_DES"
mount "$NFS_IP":"$NFS_SRC" "$NFS_DES"
# start rqd daemon
rqd
