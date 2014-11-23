NAME=herokuish
HARDWARE=$(shell uname -m)
VERSION=0.1.0

build:
	go-bindata bash
	rm -rf build
	mkdir -p build/linux && GOOS=linux go build -o build/linux/$(NAME)
	mkdir -p build/darwin && GOOS=darwin go build -o build/darwin/$(NAME)

test: build
	tests/shunit2 tests/**/tests.sh

release: test
	rm -rf release
	mkdir release
	cp build/linux/$(NAME) release/$(NAME)
	cd release && tar -zcf $(NAME)_$(VERSION)_linux_$(HARDWARE).tgz $(NAME)
	cp build/darwin/$(NAME) release/$(NAME)
	cd release && tar -zcf $(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz $(NAME)
	rm release/$(NAME)
	echo "$(VERSION)" > release/version
	echo "gliderlabs/$(NAME)" > release/repo
	gh-release # https://github.com/progrium/gh-release

.PHONY: build test release