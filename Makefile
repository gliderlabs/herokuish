NAME=herokuish
HARDWARE=$(shell uname -m)
VERSION=0.1.0

build:
	go get || true
	go-bindata bash
	mkdir -p build/linux && GOOS=linux go build -o build/linux/$(NAME)
	mkdir -p build/darwin && GOOS=darwin go build -o build/darwin/$(NAME)

test: build
	tests/shunit2 tests/**/tests.sh

release: build
	rm -rf release && mkdir release
	tar -zcf release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz -C build/linux $(NAME)
	tar -zcf release/$(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz -C build/darwin $(NAME)
	echo "$(VERSION)" > release/version
	echo "gliderlabs/$(NAME)" > release/repo
	gh-release # https://github.com/progrium/gh-release

.PHONY: build test release