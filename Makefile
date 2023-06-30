# Image URL to use all building/pushing image targets
REGISTRY ?= quay.io
REPOSITORY ?= $(REGISTRY)/eformat/sd-auto

IMG := $(REPOSITORY):latest

# Podman Login
podman-login:
	@podman login -u $(DOCKER_USER) -p $(DOCKER_PASSWORD) $(REGISTRY)

# Build the oci image
podman-build:
	podman build . -t ${IMG} -f Dockerfile

# Push the oci image
podman-push: podman-build
	podman push ${IMG}

# Run
podman-run:
	podman run --rm --privileged -it -p 7860:7860 -e CLI_ARGS="--allow-code --medvram --xformers" \
	-v /home/mike/git/stable-diffusion/download/data:/data \
	--security-opt=label=disable \
	--hooks-dir=/usr/share/containers/oci/hooks.d/ \
	quay.io/eformat/sd-auto:latest
