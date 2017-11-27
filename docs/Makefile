CWD := $(shell pwd)
DOCKER_IMAGE := truss/slate

.PHONY: build serve

all: build

image:
	docker build -t $(DOCKER_IMAGE) .

build: image
	docker run --rm \
		-v $(CWD):/usr/src/app/source:ro \
		-v $(CWD)/build:/usr/src/app/build \
		$(DOCKER_IMAGE) \
		bundle exec middleman build --clean

serve: image
	docker run --rm \
		-v $(CWD):/usr/src/app/source:ro \
		-p 4567:4567 \
		$(DOCKER_IMAGE)
