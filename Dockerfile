# --------------------------------------------------------------------
# BUILD
# --------------------------------------------------------------------
FROM ubuntu:latest

RUN echo "starting build rqd client for Google Cloud Platform"

# --------------------------------------------------------------------
# COPY RQD BASE DIR
# --------------------------------------------------------------------
COPY OpenCue /OpenCue
COPY startup.sh /startup.sh

# --------------------------------------------------------------------
# RUN apt
# --------------------------------------------------------------------
WORKDIR /
RUN apt-get update && apt-get upgrade -y
RUN apt-get install \
    bzip2 \
    curl \
    gnupg2 \
    python \
    python-pip \
    nfs-common \
    libfreetype6 \
    libgl1-mesa-dev \
    libxi-dev \
    libglu1-mesa-dev \
    zlib1g-dev \
    libxinerama-dev \
    libxrandr-dev \
    -y

# --------------------------------------------------------------------
# SETUP GPU Drivers
# --------------------------------------------------------------------
RUN curl -O http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
RUN dpkg -i cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
RUN rm cuda-repo-ubuntu1804_10.0.130-1_amd64.deb
RUN apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install cuda -y

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
RUN pip install -r OpenCue/requirements.txt
RUN python -m grpc_tools.protoc -I=OpenCue/proto --python_out=OpenCue/rqd/rqd/compiled_proto --grpc_python_out=OpenCue/rqd/rqd/compiled_proto OpenCue/proto/*.proto
RUN python OpenCue/rqd/setup.py install
RUN cp -R OpenCue/rqd/rqd /usr/local/lib/python2.7/dist-packages/
RUN rm -rf OpenCue

# --------------------------------------------------------------------
# Cleanup cache
# --------------------------------------------------------------------
RUN apt-get remove && apt-get clean
RUN apt-get autoremove && apt-get autoclean

# RQD gRPC server
EXPOSE 8444

# --------------------------------------------------------------------
# start rqd on start
# --------------------------------------------------------------------
ENTRYPOINT ["./startup.sh"]
