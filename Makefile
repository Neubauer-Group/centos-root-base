default: image

image:
	docker pull neubauergroup/centos-build-base:latest
	docker build . \
		--file Dockerfile \
		--build-arg BUILDER_IMAGE=neubauergroup/centos-build-base:latest \
		--build-arg ROOT_VERSION=6.24.00 \
		--tag neubauergroup/centos-root-base:debug-local
