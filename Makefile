NAME = herokuish
HARDWARE = $(shell uname -m)
VERSION ?= 0.3.32
IMAGE_NAME ?= $(NAME)
BUILD_TAG ?= dev

BUILDPACK_ORDER := multi ruby nodejs clojure python java gradle scala play php go erlang static
SHELL := /bin/bash

shellcheck:
ifneq ($(shell shellcheck --version > /dev/null 2>&1 ; echo $$?),0)
ifeq ($(SYSTEM),Darwin)
	brew install shellcheck
else
	@sudo add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty-backports main restricted universe multiverse'
	@sudo apt-get update && sudo apt-get install -y shellcheck
endif
endif

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
		-v ${PWD}:/go/src/github.com/gliderlabs/herokuish -w /go/src/github.com/gliderlabs/herokuish \
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

lint:
	# SC2002: Useless cat - https://github.com/koalaman/shellcheck/wiki/SC2002
	# SC2030: Modification of name is local - https://github.com/koalaman/shellcheck/wiki/SC2030
	# SC2031: Modification of name is local - https://github.com/koalaman/shellcheck/wiki/SC2031
	# SC2034: VAR appears unused - https://github.com/koalaman/shellcheck/wiki/SC2034
	@echo linting...
	shellcheck -e SC2002,SC2030,SC2031,SC2034 -s bash include/*.bash tests/**/tests.sh

release: build
	rm -rf release && mkdir release
	tar -zcf release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz -C build/linux $(NAME)
	tar -zcf release/$(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz -C build/darwin $(NAME)
	gh-release create gliderlabs/$(NAME) $(VERSION) \
		$(shell git rev-parse --abbrev-ref HEAD) v$(VERSION)

bumpup:
	for i in $(BUILDPACK_ORDER); do \
		url=$$(cat buildpacks/buildpack-$$i/buildpack-url) ; \
		version=$$(git ls-remote --tags $$url | awk '{print $$2}' | sed 's/refs\/tags\///' | egrep 'v[0-9]+$$' | sed 's/v//' | sort -n | tail -n 1) ; \
		if [[ "x$$version" != 'x' ]]; then \
			echo v$$version > buildpacks/buildpack-$$i/buildpack-version ; \
			git status -s buildpacks/buildpack-$$i/buildpack-version | fgrep ' M ' ; \
			if [[ $$? -eq 0 ]] ; then \
				git checkout -b $$(date +%Y%m%d)-update-$$i ; \
				git add buildpacks/buildpack-$$i/buildpack-version ; \
				git commit -m "Update $$i to version v$$version" ; \
				git checkout - ; \
			fi ; \
		fi ; \
	done

.PHONY: build
