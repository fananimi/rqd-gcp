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
# Install some dependencies
# --------------------------------------------------------------------
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install \
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
# <https://cloud.google.com/compute/docs/gpus/install-drivers-gpu> for more info.
RUN curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb && \
    dpkg -i cuda-repo-ubuntu1804_10.0.130-1_amd64.deb && \
    apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install cuda --no-install-recommends -y && \
    rm cuda-repo-ubuntu1804_10.0.130-1_amd64.deb

# --------------------------------------------------------------------
# Install Blender 2.79, 2.80, and 2.81
# --------------------------------------------------------------------
# blender2.79
WORKDIR /opt/blender2.79
COPY script/use_gpu.py ./
RUN curl -SL https://mirror.clarkson.edu/blender/release/Blender2.79/blender-2.79-linux-glibc219-x86_64.tar.bz2 \
        -o blender2.79.tar.bz2 && \
    tar -jxvf blender2.79.tar.bz2 --strip-components=1 && \
    rm blender2.79.tar.bz2
# blender2.80
WORKDIR /opt/blender2.80
COPY script/use_gpu.py ./
RUN curl -SL https://mirror.clarkson.edu/blender/release/Blender2.80/blender-2.80-linux-glibc217-x86_64.tar.bz2 \
        -o blender2.80.tar.bz2 && \
    tar -jxvf blender2.80.tar.bz2 --strip-components=1 && \
    rm blender2.80.tar.bz2
# blender2.81
WORKDIR /opt/blender2.81
COPY script/use_gpu.py ./
RUN curl -SL https://mirror.clarkson.edu/blender/release/Blender2.81/blender-2.81-linux-glibc217-x86_64.tar.bz2 \
        -o blender2.81.tar.bz2 && \
    tar -jxvf blender2.81.tar.bz2 --strip-components=1 && \
    rm blender2.81.tar.bz2

# --------------------------------------------------------------------
# Build rqd
# --------------------------------------------------------------------
WORKDIR /opt/opencue
RUN python3.7 -m pip install setuptools
RUN python3.7 -m pip install wheel
COPY OpenCue/requirements.txt ./
RUN python3.7 -m pip install -r requirements.txt
COPY OpenCue/proto/ ./proto
COPY OpenCue/rqd/rqd/ ./rqd/rqd
RUN python3.7 -m grpc_tools.protoc \
        -I=./proto \
        --python_out=./rqd/rqd/compiled_proto \
        --grpc_python_out=./rqd/rqd/compiled_proto \
        ./proto/*.proto
# Fix imports to work in both Python 2 and 3. See
# <https://github.com/protocolbuffers/protobuf/issues/1491> for more info.
RUN sed -i 's/^\(import.*_pb2\)/from . \1/' rqd/rqd/compiled_proto/*.py

# TODO(bcipriano) Lint the code here. (Issue #78)
COPY OpenCue/LICENSE ./
COPY OpenCue/rqd/README.md ./rqd/
COPY OpenCue/VERSION.in VERSIO[N] ./
RUN test -e VERSION || echo "$(cat VERSION.in)-custom" | tee VERSION

COPY OpenCue/rqd/setup.py ./rqd/
COPY OpenCue/rqd/tests/ ./rqd/tests
# Doing python test and install
RUN cd rqd && python3.7 setup.py test
RUN cd rqd && python3.7 setup.py install

# --------------------------------------------------------------------
# Removing cache
# --------------------------------------------------------------------
RUN apt-get clean && \
    apt-get autoclean  && \
    apt-get remove  && \
    apt-get autoremove  && \
    rm -rf /var/lib/apt/lists/*

# RQD gRPC server
EXPOSE 8444
COPY startup.sh ./startup.sh
# NOTE: This shell out is needed to avoid RQD getting PID 0 which leads to leaking child processes.
ENTRYPOINT ["./startup.sh"]
