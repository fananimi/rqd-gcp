import argparse
import subprocess

container_name = 'rqd'

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Run rqd container.')
    parser.add_argument('--cuebot-hostname', required=True, help='cuebot hostname')
    parser.add_argument('--bucket', required=True, help='bucket name')
    parser.add_argument('--image-id', required=True, help='docker imaage ID')

    args = parser.parse_args()
    cuebot_hostname = args.cuebot_hostname
    bucket = args.bucket
    image_id = args.image_id

    rqd_id = subprocess.Popen('docker ps -aq -f name=%s' % container_name, shell=True, stdout=subprocess.PIPE) \
        .communicate()[0].strip()
    if rqd_id:
        # stop and remove the container
        subprocess.Popen('docker stop {name} && docker rm {name}'.format(name=container_name), shell=True) \
            .communicate()

    # finally start the new rqd
    docker_run_cmd = '''docker run \
-e CUEBOT_HOSTNAME={cuebot_hostname} \
-e GCS_FUSE_BUCKET={bucket} \
-dit \
--network host \
--name {container_name} \
--gpus all \
--privileged \
--restart always \
{image_id}
'''.format(cuebot_hostname=cuebot_hostname, bucket=bucket, container_name=container_name, image_id=image_id)
    subprocess.Popen(docker_run_cmd, shell=True).communicate()
