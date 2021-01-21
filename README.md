# rqd-gcp

RQD - a software daemon that runs on all rendering hosts, which are doing work for an OpenCue deployment.

This project aims to provide a docker container for Google Cloud Platform with GPU support.

Usage
-----
~~~~
# make build
~~~~

Create Container
----------------
~~~~
# docker run \
-e CUEBOT_HOSTNAME=<CUEBOT_HOSTNAME> \
-e GCS_FUSE_BUCKET=<GCS_FUSE_BUCKET> \
-dit \
--network host \
--name rqd \
--gpus all \
--privileged \
--restart always \
<IMAGE_ID>
~~~~

Render Command
--------------

To use gpu rendering we must execute blender combine with `use_gpu.py`. Here the example command:

~~~~
/opt/blender2.81/blender -P /shots/use_gpu.py -b -noaudio /shots/barbershop_interior_cpu.blend -o /shots/renderimages/barbershop_interior_cpu.##### -F PNG -f 1
~~~~

Figure 1 - OpenCue Architecture
--------------------------------

![](https://www.opencue.io/docs/images/opencue_architecture.svg)
