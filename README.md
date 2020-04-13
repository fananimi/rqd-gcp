# rqd-gcp

RQD - a software daemon that runs on all rendering hosts, which are doing work for an OpenCue deployment.

This project aims to provide a docker container for Google Cloud Platform with GPU support.

Usage
-----
~~~~
# docker build -t gcr.io/$PROJECT_NAME/opencue/rqd:$TAG_NAME -f Dockerfile .
# docker push gcr.io/$PROJECT_NAME/opencue/rqd:$TAG_NAME


# docker run \
-e CUEBOT_HOSTNAME=<CUEBOT_HOSTNAME> \
-e NFS_IP=<NFS_IP> \
-e NFS_SRC=<NFS_SOURCE_DIR> \
-e NFS_DST=<NFS_DESTINATION_DIR> \
-dit \
--network host \
--name rqd \
--gpus all \
--privileged \
--restart always \
<IMAGE_ID>
~~~~


Figure 1 - OpenCue Architecture

![](https://www.opencue.io/docs/images/opencue_architecture.svg)
