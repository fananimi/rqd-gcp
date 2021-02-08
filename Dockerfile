# --------------------------------------------------------------------
# BUILD
# --------------------------------------------------------------------
FROM ubuntu:18.04

RUN echo "starting build rqd client for Google Cloud Platform"

# --------------------------------------------------------------------
# Global Environment
# --------------------------------------------------------------------
# Update YOUR_BUCKET_NAME with the name of your bucket in the following line:
# This variable is referenced in startup.sh
ENV GCS_FUSE_BUCKET YOUR_BUCKET_NAME

# This is the GCS bucket mount point on your Render Host. Referenced in startup.sh.sh
ENV GCS_FUSE_MOUNT /shots

# --------------------------------------------------------------------
# Install some dependencies
# --------------------------------------------------------------------
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install \
        curl \
        gnupg2 \
        time \
        python3.7 \
        python3.7-dev \
        python3-pip \
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
# Install gcs-fuse and google cloud SDK
# --------------------------------------------------------------------
RUN echo "deb http://packages.cloud.google.com/apt gcsfuse-bionic main" | tee /etc/apt/sources.list.d/gcsfuse.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN apt-get update && \
    apt-get install gcsfuse -y
RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-bionic main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN apt-get update && apt-get install google-cloud-sdk -y

# --------------------------------------------------------------------
# Install GPU Drivers
# --------------------------------------------------------------------
# <https://cloud.google.com/compute/docs/gpus/install-drivers-gpu> for more info.
COPY build/nvidia/cuda/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb .
RUN dpkg -i cuda-repo-ubuntu1804_10.0.130-1_amd64.deb && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install cuda --no-install-recommends -y && \
    rm cuda-repo-ubuntu1804_10.0.130-1_amd64.deb

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.2 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=396,driver<397 brand=tesla,driver>=410,driver<411 brand=tesla,driver>=418,driver<419"

# --------------------------------------------------------------------
# Install Blender 2.79, 2.80, 2.81, 2.82, and 2.91
# --------------------------------------------------------------------
# blender2.79
WORKDIR /opt/blender2.79
COPY build/blender/blender-2.79-linux-glibc219-x86_64.tar.bz2 .
RUN tar -jxvf blender-2.79-linux-glibc219-x86_64.tar.bz2 --strip-components=1 && \
    rm blender-2.79-linux-glibc219-x86_64.tar.bz2
# blender2.80
WORKDIR /opt/blender2.80
COPY build/blender/blender-2.80-linux-glibc217-x86_64.tar.bz2 .
RUN tar -jxvf blender-2.80-linux-glibc217-x86_64.tar.bz2 --strip-components=1 && \
    rm blender-2.80-linux-glibc217-x86_64.tar.bz2
# blender2.81
WORKDIR /opt/blender2.81
COPY build/blender/blender-2.81-linux-glibc217-x86_64.tar.bz2 .
RUN tar -jxvf blender-2.81-linux-glibc217-x86_64.tar.bz2 --strip-components=1 && \
    rm blender-2.81-linux-glibc217-x86_64.tar.bz2
# blender2.82
WORKDIR /opt/blender2.82
COPY build/blender/blender-2.82-linux64.tar.xz .
RUN tar -xvf blender-2.82-linux64.tar.xz --strip-components=1 && \
    rm blender-2.82-linux64.tar.xz
# blender2.91
WORKDIR /opt/blender2.91
COPY build/blender/blender-2.91.2-linux64.tar.xz .
RUN tar -xvf blender-2.91.2-linux64.tar.xz --strip-components=1 && \
    rm blender-2.91.2-linux64.tar.xz

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
