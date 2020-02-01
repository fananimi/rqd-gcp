# --------------------------------------------------------------------
# BUILD
# --------------------------------------------------------------------
FROM ubuntu:latest

RUN echo "starting build rqd client for Google Cloud Platform"

# --------------------------------------------------------------------
# Global Environment
# --------------------------------------------------------------------
ENV NFS_IP localhost
ENV NFS_DST /var/nfs/shots
ENV NFS_SRC /shots

# --------------------------------------------------------------------
# Preparation
# --------------------------------------------------------------------
WORKDIR /opt/opencue
# copy rqd and the dependencies
COPY OpenCue/LICENSE ./
COPY OpenCue/requirements.txt ./
COPY OpenCue/proto/ ./proto
COPY OpenCue/rqd/deploy ./rqd/deploy
COPY OpenCue/rqd/README.md ./rqd/
COPY OpenCue/rqd/setup.py ./rqd/
COPY OpenCue/rqd/tests/ ./rqd/tests
COPY OpenCue/rqd/rqd/ ./rqd/rqd
# copy startup.sh for doker entrypoint
COPY startup.sh ./startup.sh

# --------------------------------------------------------------------
# Install some dependencies
# --------------------------------------------------------------------
RUN apt-get update && apt-get upgrade -y
RUN apt-get install \
    bzip2 \
    curl \
    gnupg2 \
    time \
    python3.7 \
    python3.7-dev \
    python3-pip \
    nfs-common \
    libfreetype6 \
    libgl1-mesa-dev \
    libxi-dev \
    libglu1-mesa-dev \
    zlib1g-dev \
    libxinerama-dev \
    libxrandr-dev \
    --no-install-recommends \
    -y

# --------------------------------------------------------------------
# Install GPU Drivers
# --------------------------------------------------------------------
RUN curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
RUN dpkg -i cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
RUN rm cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
RUN apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install \
    cuda --no-install-recommends \
    -y

# --------------------------------------------------------------------
# Download blender 2.80 and install blender 2.80
# --------------------------------------------------------------------
ENV BLENDER_MAJOR 2.80
ENV BLENDER_VERSION 2.80
ENV BLENDER_DOWNLOAD_URL https://mirror.clarkson.edu/blender/release/Blender$BLENDER_MAJOR/blender-$BLENDER_VERSION-linux-glibc217-x86_64.tar.bz2
RUN mkdir /usr/local/blender
RUN curl -SL "$BLENDER_DOWNLOAD_URL" -o blender.tar.bz2
RUN tar -jxvf blender.tar.bz2 -C /usr/local/blender --strip-components=1
RUN rm blender.tar.bz2

# --------------------------------------------------------------------
# COMPILE proto
# --------------------------------------------------------------------
RUN python3.7 -m pip install setuptools
RUN python3.7 -m pip install wheel
RUN python3.7 -m pip install -r requirements.txt
RUN python3.7 -m grpc_tools.protoc \
    -I=./proto \
    --python_out=./rqd/rqd/compiled_proto \
    --grpc_python_out=./rqd/rqd/compiled_proto \
    ./proto/*.proto
# Fix imports to work in both Python 2 and 3. See
# <https://github.com/protocolbuffers/protobuf/issues/1491> for more info.
RUN sed -i 's/^\(import.*_pb2\)/from . \1/' rqd/rqd/compiled_proto/*.py

# TODO(bcipriano) Lint the code here. (Issue #78)

COPY OpenCue/VERSION.in VERSIO[N] ./
RUN test -e VERSION || echo "$(cat VERSION.in)-custom" | tee VERSION

## Doing python test
RUN cd rqd && python3.7 setup.py test
RUN cd rqd && python3.7 setup.py install

# --------------------------------------------------------------------
# Removing cache
# --------------------------------------------------------------------
RUN apt-get clean \
    apt-get autoclean \
    apt-get remove \
    apt-get autoremove
RUN rm -rf /var/lib/apt/lists/*

# This step isn't really needed at runtime, but is used when publishing an OpenCue release
# from this build.
RUN versioned_name="rqd-$(cat ./VERSION)-all" \
    && cp LICENSE requirements.txt VERSION rqd/ \
    && mv rqd $versioned_name \
    && tar -cvzf $versioned_name.tar.gz $versioned_name/* \
    && ln -s $versioned_name rqd

# RQD gRPC server
EXPOSE 8444

# NOTE: This shell out is needed to avoid RQD getting PID 0 which leads to leaking child processes.
ENTRYPOINT ["./startup.sh"]
