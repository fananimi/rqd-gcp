# --------------------------------------------------------------------
# Author(s): Fanani M. Ihsan
#
# This software may be modified and distributed under the terms of the
# MIT license. See the LICENSE file for details.
# --------------------------------------------------------------------

# all our targets are phony (no files to check).
.PHONY: shell help build clean

# suppress makes own output
#.SILENT:

# Regular Makefile part for buildpypi itself
help:
	@echo ''
	@echo 'Targets:'
	@echo '  build    	build docker --image-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  test     	test docker --container-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  clean    	remove docker --image-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo '  shell      run docker --container-- for current user: $(HOST_USER)(uid=$(HOST_UID))'
	@echo ''

build:
	# only build the container. Note, docker does this also if you apply other targets.
	# docker-compose build $(SERVICE_TARGET)
	mkdir -p build && \
	bash download_blender.sh

clean:
	# remove build directory
	rm -rf build
