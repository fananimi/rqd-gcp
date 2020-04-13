#!/bin/bash


download_cuda() {
    filepath="./build/nvidia/cuda/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb"
    download=false
    if test -f "$filepath"; then
        if [ `md5sum "$filepath" | awk '{print $1}'` != "306fbaad179372f5f200c8d2c2c9b8bb" ]; then
            download=true
        fi
    else
        download=true
    fi
    if [ "$download" == true ] ; then
        curl -SL "http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb" -o "$filepath"
    fi
}

main() {
    mkdir -p build/nvidia/cuda
    download_cuda
}

main