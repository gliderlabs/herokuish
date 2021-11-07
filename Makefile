NAME = herokuish
DESCRIPTION = 'Herokuish uses Docker and Buildpacks to build applications like Heroku'
HARDWARE = $(shell uname -m)
SYSTEM_NAME  = $(shell uname -s | tr '[:upper:]' '[:lower:]')
VERSION ?= 0.5.31
IMAGE_NAME ?= $(NAME)
BUILD_TAG ?= dev
PACKAGECLOUD_REPOSITORY ?= dokku/dokku-betafish

BUILDPACK_ORDER := multi ruby nodejs clojure python java gradle scala play php go static null
SHELL := /bin/bash
SYSTEM := $(shell sh -c 'uname -s 2>/dev/null')

shellcheck:
ifneq ($(shell shellcheck --version > /dev/null 2>&1 ; echo $$?),0)
ifeq ($(SYSTEM),Darwin)
	brew install shellcheck
else
	@sudo add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty-backports main restricted universe multiverse'
	@sudo apt-get update && sudo apt-get install -y shellcheck
endif
endif

fpm:
ifeq ($(SYSTEM),Linux)
	sudo apt-get update && sudo apt-get -y install gcc git build-essential wget ruby-dev ruby1.9.1 lintian rpm help2man man-db
	command -v fpm >/dev/null || gem install fpm --no-ri --no-rdoc
endif

package_cloud:
ifeq ($(SYSTEM),Linux)
	sudo apt-get update && sudo apt-get -y install gcc git build-essential wget ruby-dev ruby1.9.1 lintian rpm help2man man-db
	command -v package_cloud >/dev/null || gem install package_cloud --no-ri --no-rdoc
endif

bindata.go:
	@count=0; \
	for i in $(BUILDPACK_ORDER); do \
		bp_count=$$(printf '%02d' $$count) ; \
		echo -n "$${bp_count}_buildpack-$$i "; \
		cat buildpacks/*-$$i/buildpack* | sed 'N;s/\n/ /'; \
		count=$$((count + 1)) ; \
	done > include/buildpacks.txt
	go-bindata include

build: bindata.go
	mkdir -p build/linux  && GOOS=linux  go build -a -ldflags "-X main.Version=$(VERSION)" -o build/linux/$(NAME)
	mkdir -p build/darwin && GOOS=darwin go build -a -ldflags "-X main.Version=$(VERSION)" -o build/darwin/$(NAME)
	$(MAKE) build/docker
	$(MAKE) build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm
	$(MAKE) build/deb/$(NAME)_$(VERSION)_amd64.deb

build/docker:
	chmod +x build/linux/$(NAME) build/darwin/$(NAME)
ifeq ($(CIRCLECI),true)
	docker build -t $(IMAGE_NAME):$(BUILD_TAG) .
	docker build -t $(IMAGE_NAME):$(BUILD_TAG)-20 --build-arg STACK_VERSION=20 .
else
	docker build -f Dockerfile.dev -t $(IMAGE_NAME):$(BUILD_TAG) .
	docker build -f Dockerfile.dev -t $(IMAGE_NAME):$(BUILD_TAG)-20 --build-arg STACK_VERSION=20 .
endif

build/deb:
	mkdir -p build/deb

build/deb/$(NAME)_$(VERSION)_amd64.deb: build/deb
	echo $(VERSION) > /tmp/$(NAME)-VERSION
	fpm \
		--after-install contrib/post-install \
		--architecture amd64 \
		--category utils \
		--deb-pre-depends 'docker-engine-cs (>= 1.13.0) | docker-engine (>= 1.13.0) | docker-io (>= 1.13.0) | docker.io (>= 1.13.0) | docker-ce (>= 1.13.0) | docker-ee (>= 1.13.0) | moby-engine' \
		--deb-pre-depends sudo \
		--description $(DESCRIPTION) \
		--input-type dir \
		--license 'MIT License' \
		--name $(NAME) \
		--output-type deb \
		--package build/deb/$(NAME)_$(VERSION)_amd64.deb \
		--url "https://github.com/gliderlabs/$(NAME)" \
		--vendor "" \
		--version $(VERSION) \
		--verbose \
		/tmp/$(NAME)-VERSION=/var/lib/herokuish/VERSION \
		LICENSE=/usr/share/doc/$(NAME)/copyright

build/rpm:
	mkdir -p build/rpm

build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm: build/rpm
	echo $(VERSION) > /tmp/$(NAME)-VERSION
	fpm \
		--after-install contrib/post-install \
		--architecture x86_64 \
		--category utils \
		--depends '/usr/bin/docker' \
		--depends 'sudo' \
		--description $(DESCRIPTION) \
		--input-type dir \
		--license 'MIT License' \
		--name $(NAME) \
		--output-type rpm \
		--package build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm \
		--url "https://github.com/gliderlabs/$(NAME)" \
		--vendor "" \
		--version $(VERSION) \
		--verbose \
		/tmp/$(NAME)-VERSION=/var/lib/herokuish/VERSION \
		LICENSE=/usr/share/doc/$(NAME)/copyright


clean:
	rm -rf build/*
	docker rm $(shell docker ps -aq) || true
	docker rmi herokuish:dev || true

deps:
	docker pull heroku/heroku:18-build
	docker pull heroku/heroku:20-build
	cd / && go get -u github.com/jteeuwen/go-bindata/...
	cd / && go get -u github.com/progrium/basht/...
	$(MAKE) bindata.go
	go get || true

bin/gh-release:
	mkdir -p bin
	curl -o bin/gh-release.tgz -sL https://github.com/progrium/gh-release/releases/download/v2.3.3/gh-release_2.3.3_$(SYSTEM_NAME)_$(HARDWARE).tgz
	tar xf bin/gh-release.tgz -C bin
	chmod +x bin/gh-release

bin/gh-release-body:
	mkdir -p bin
	curl -o bin/gh-release-body "https://raw.githubusercontent.com/dokku/gh-release-body/master/gh-release-body"
	chmod +x bin/gh-release-body

test:
	basht tests/*/tests.sh

ci-report:
	docker version
	which go
	go version
	which python
	python -V
	which ruby
	ruby -v
	rm -f ~/.gitconfig
	mv Dockerfile.dev Dockerfile

lint:
	# SC2002: Useless cat - https://github.com/koalaman/shellcheck/wiki/SC2002
	# SC2030: Modification of name is local - https://github.com/koalaman/shellcheck/wiki/SC2030
	# SC2031: Modification of name is local - https://github.com/koalaman/shellcheck/wiki/SC2031
	# SC2034: VAR appears unused - https://github.com/koalaman/shellcheck/wiki/SC2034
	@echo linting...
	shellcheck -e SC2002,SC2030,SC2031,SC2034 -s bash include/*.bash tests/**/tests.sh

release: build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm build/deb/$(NAME)_$(VERSION)_amd64.deb bin/gh-release bin/gh-release-body
	chmod +x build/linux/$(NAME) build/darwin/$(NAME)
	rm -rf release && mkdir release
	cp build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm release/$(NAME)-$(VERSION)-1.x86_64.rpm
	cp build/deb/$(NAME)_$(VERSION)_amd64.deb release/$(NAME)_$(VERSION)_amd64.deb
	tar -zcf release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz -C build/linux $(NAME)
	tar -zcf release/$(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz -C build/darwin $(NAME)
	bin/gh-release create gliderlabs/$(NAME) $(VERSION) \
		$(shell git rev-parse --abbrev-ref HEAD) v$(VERSION)
	bin/gh-release-body $(MAINTAINER)/$(REPOSITORY) v$(VERSION)

release-packagecloud: package_cloud
	@$(MAKE) release-packagecloud-deb
	@$(MAKE) release-packagecloud-rpm

release-packagecloud-deb: package_cloud build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/xenial  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/bionic  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/ubuntu/focal   build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/stretch build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/buster  build/deb/$(NAME)_$(VERSION)_amd64.deb
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/debian/bullseye build/deb/$(NAME)_$(VERSION)_amd64.deb

release-packagecloud-rpm: package_cloud build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm
	package_cloud push $(PACKAGECLOUD_REPOSITORY)/el/7           build/rpm/$(NAME)-$(VERSION)-1.x86_64.rpm

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

.PHONY: build bindata.go
