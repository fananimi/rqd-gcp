#!/usr/bin/env bash
sudo mkdir -p /shots

if [ -z "$(ls -A /shots)" ]; then
   sudo gcsfuse --implicit-dirs -o rw,allow_other --uid 1000 --gid 1000 --dir-mode 777 --file-mode 777 hompimpa-render /shots
else
   echo "Storage mounted!"
fi
