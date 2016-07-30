NAME = herokuish
HARDWARE = $(shell uname -m)
VERSION ?= 0.3.18
IMAGE_NAME ?= $(NAME)
BUILD_TAG ?= dev

BUILDPACK_ORDER := multi ruby nodejs clojure python java gradle grails scala play php go erlang static emberjs
SHELL := /bin/bash

build:
	@count=0; \
	for i in $(BUILDPACK_ORDER); do \
		bp_count=$$(printf '%02d' $$count) ; \
		echo -n "$${bp_count}_buildpack-$$i "; \
		cat buildpacks/*-$$i/buildpack* | sed 'N;s/\n/ /'; \
		count=$$((count + 1)) ; \
	done > include/buildpacks.txt
	go-bindata include
	mkdir -p build/linux  && GOOS=linux  go build -a -ldflags "-X main.Version=$(VERSION)" -o build/linux/$(NAME)
	mkdir -p build/darwin && GOOS=darwin go build -a -ldflags "-X main.Version=$(VERSION)" -o build/darwin/$(NAME)
ifeq ($(CIRCLECI),true)
	docker build -t $(IMAGE_NAME):$(BUILD_TAG) .
else
	docker build -f Dockerfile.dev -t $(IMAGE_NAME):$(BUILD_TAG) .
endif

build-in-docker:
	docker build --rm -f Dockerfile.build -t $(NAME)-build .
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock:ro \
		-v /var/lib/docker:/var/lib/docker \
		-v ${PWD}:/usr/src/myapp -w /usr/src/myapp \
		-e IMAGE_NAME=$(IMAGE_NAME) -e BUILD_TAG=$(BUILD_TAG) -e VERSION=master \
		$(NAME)-build make -e deps build
	docker rmi $(NAME)-build || true

clean:
	rm -rf build/*
	docker rm $(shell docker ps -aq) || true
	docker rmi herokuish:dev || true

deps:
	docker pull heroku/cedar:14
	go get -u github.com/jteeuwen/go-bindata/...
	go get -u github.com/progrium/gh-release/...
	go get -u github.com/progrium/basht/...
	go get || true

test:
	basht tests/*/tests.sh

circleci:
	docker version
	rm -f ~/.gitconfig
	mv Dockerfile.dev Dockerfile

release: build
	rm -rf release && mkdir release
	tar -zcf release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz -C build/linux $(NAME)
	tar -zcf release/$(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz -C build/darwin $(NAME)
	gh-release create gliderlabs/$(NAME) $(VERSION) \
		$(shell git rev-parse --abbrev-ref HEAD) v$(VERSION)

.PHONY: build
