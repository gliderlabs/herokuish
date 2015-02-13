NAME=herokuish
HARDWARE=$(shell uname -m)
VERSION=0.2.0
CEDARISH=v2

build:
	echo "$(CEDARISH)" > include/cedarish.txt
	go-bindata include
	mkdir -p build/linux  && GOOS=linux  go build -ldflags "-X main.Version $(VERSION)" -o build/linux/$(NAME)
	mkdir -p build/darwin && GOOS=darwin go build -ldflags "-X main.Version $(VERSION)" -o build/darwin/$(NAME)

deps: .cache/cedarish_$(CEDARISH).tgz import-cedarish
	go get -u github.com/jteeuwen/go-bindata/...
	go get -u github.com/progrium/gh-release/...
	go get || true

build-container: build
	docker build -t gliderlabs/herokuish .

import-cedarish:
	cat .cache/cedarish_$(CEDARISH).tgz | docker import - "progrium/cedarish:cedar14"

.cache/cedarish_$(CEDARISH).tgz:
	mkdir -p .cache
	curl -L https://github.com/progrium/cedarish/releases/download/$(CEDARISH)/cedarish-cedar14_$(CEDARISH).tar.gz \
		> .cache/cedarish_$(CEDARISH).tgz

test: test-functional test-apps

test-functional: build-container
	tests/shunit2 tests/*/tests.sh

test-apps: build-container
	tests/shunit2 tests/apps/*/tests.sh

release: build
	rm -rf release && mkdir release
	tar -zcf release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz -C build/linux $(NAME)
	tar -zcf release/$(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz -C build/darwin $(NAME)
	gh-release create gliderlabs/$(NAME) $(VERSION) $(shell git rev-parse --abbrev-ref HEAD)

.PHONY: build
