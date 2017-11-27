# Docker-ized Jekyll build
#
# Based on:
# https://kristofclaes.github.io/2016/06/19/running-jekyll-locally-with-docker/

CWD := $(shell pwd)
DOCKER_IMAGE := jekyll/jekyll:pages

.PHONY: image serve

all: serve

image:
	docker pull $(DOCKER_IMAGE)

serve:
	docker run --rm \
		-v $(CWD):/srv/jekyll:ro \
		-p 4000:4000 \
		$(DOCKER_IMAGE) \
		jekyll serve --watch --incremental

shell:
	docker run --rm -it \
		-v $(CWD):/srv/jekyll \
		-p 4000:4000 \
		$(DOCKER_IMAGE) \
		/bin/bash
