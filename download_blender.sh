#!/bin/bash

download_blender312() {
    filepath="./build/blender/blender-3.1.2-linux-x64.tar.xz"
    download=false
    if test -f "$filepath"; then
        if [ `md5sum "$filepath" | awk '{print $1}'` != "c3403f5b897c9ed4794226df69400d87" ]; then
            download=true
        fi
    else
        download=true
    fi
    if [ "$download" == true ] ; then
        curl -SL "https://mirror.clarkson.edu/blender/release/Blender3.1/blender-3.1.2-linux-x64.tar.xz" -o "$filepath"
    fi
}

main() {
    mkdir -p build/blender
    download_blender312
}

main