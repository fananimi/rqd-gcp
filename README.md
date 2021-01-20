# rqd-gcp

RQD - a software daemon that runs on all rendering hosts, which are doing work for an OpenCue deployment.

This project aims to provide a docker container for Google Cloud Platform with GPU support.

Usage
-----
~~~~
# make build
# docker build -t gcr.io/$PROJECT_NAME/opencue/rqd:$TAG_NAME -f Dockerfile .
# docker push gcr.io/$PROJECT_NAME/opencue/rqd:$TAG_NAME


# docker run \
-e CUEBOT_HOSTNAME=<CUEBOT_HOSTNAME> \
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
