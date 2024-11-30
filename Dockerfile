# syntax=docker/dockerfile:1
ARG STACK_VERSION=24

FROM golang:1.23 AS builder
RUN mkdir /src
COPY . /src/
WORKDIR /src

ARG VERSION
RUN go build -a -ldflags "-X main.Version=$VERSION" -o herokuish .

FROM heroku/heroku:${STACK_VERSION}-build AS base
ARG STACK_VERSION=24
ARG TARGETARCH

ENV STACK=heroku-$STACK_VERSION
ENV DEBIAN_FRONTEND noninteractive
LABEL com.gliderlabs.herokuish/stack=$STACK

USER root
# for setuidgid
COPY bin/apt-install /usr/local/bin/apt-install
RUN apt-install daemontools
COPY --from=builder /src/herokuish /bin/

RUN apt-install daemontools && \
    /bin/herokuish buildpack install \
    && ln -s /bin/herokuish /build \
    && ln -s /bin/herokuish /start \
    && ln -s /bin/herokuish /exec \
    && cd /tmp/buildpacks \
    && rm -rf \
    */.git \
    */.github \
    */changelogs \
    */spec \
    */support/build \
    */builds \
    */test \
    */tmp
COPY include/default_user.bash /tmp/default_user.bash
RUN bash /tmp/default_user.bash && rm -f /tmp/default_user.bash
ENV BASH_BIN /usr/bin/bash
