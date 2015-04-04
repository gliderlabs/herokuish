NAME=herokuish
HARDWARE=$(shell uname -m)
VERSION=0.3.0

build:
	cat buildpacks/*/buildpack* | sed 'N;s/\n/ /' > include/buildpacks.txt
	go-bindata include
	mkdir -p build/linux  && GOOS=linux  go build -ldflags "-X main.Version $(VERSION)" -o build/linux/$(NAME)
	mkdir -p build/darwin && GOOS=darwin go build -ldflags "-X main.Version $(VERSION)" -o build/darwin/$(NAME)
ifeq ($(CIRCLECI),true)
	docker build -t $(NAME):dev .
else
	docker build -f Dockerfile.dev -t $(NAME):dev .
endif

deps:
	docker pull progrium/cedarish:latest
	go get -u github.com/jteeuwen/go-bindata/...
	go get -u github.com/progrium/gh-release/...
	go get -u github.com/progrium/basht/...
	go get || true

test:
	basht tests/*/tests.sh

circleci:
	docker version
	rm ~/.gitconfig
	mv Dockerfile.dev Dockerfile

release: build
	rm -rf release && mkdir release
	tar -zcf release/$(NAME)_$(VERSION)_linux_$(HARDWARE).tgz -C build/linux $(NAME)
	tar -zcf release/$(NAME)_$(VERSION)_darwin_$(HARDWARE).tgz -C build/darwin $(NAME)
	gh-release create gliderlabs/$(NAME) $(VERSION) $(shell git rev-parse --abbrev-ref HEAD)

.PHONY: build
