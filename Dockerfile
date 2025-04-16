# syntax=docker/dockerfile:1
ARG STACK_VERSION=22

FROM golang:1.24 AS builder
RUN mkdir /src
COPY . /src/
WORKDIR /src

ARG VERSION
RUN go build -a -ldflags "-X main.Version=$VERSION" -o herokuish .

FROM ubuntu:${STACK_VERSION}.04 AS base
ARG STACK_VERSION=22
ARG TARGETARCH

ADD https://raw.githubusercontent.com/heroku/stack-images/main/heroku-${STACK_VERSION}/setup.sh /tmp/setup-01.sh
ADD https://raw.githubusercontent.com/heroku/stack-images/main/heroku-${STACK_VERSION}-build/setup.sh /tmp/setup-02.sh
COPY bin/setup.sh /tmp/setup.sh
RUN --mount=source=build-deps/${STACK_VERSION},target=/build  STACK_VERSION=${STACK_VERSION} TARGETARCH=${TARGETARCH} /tmp/setup.sh && \
    rm -rf /tmp/setup.sh

ENV STACK=heroku-$STACK_VERSION
ENV DEBIAN_FRONTEND noninteractive
LABEL com.gliderlabs.herokuish/stack=$STACK

RUN apt-get update -qq \
    && apt-get install --no-install-recommends -qq -y daemontools \
    && cp /etc/ImageMagick-6/policy.xml /etc/ImageMagick-6/policy.xml.custom \
    && apt-get  -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew \
    --allow-downgrades \
    --allow-remove-essential \
    --allow-change-held-packages \
    dist-upgrade \
    && mv /etc/ImageMagick-6/policy.xml.custom /etc/ImageMagick-6/policy.xml \
    && apt-get clean \
    && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /var/tmp/*

COPY --from=builder /src/herokuish /bin/

RUN /bin/herokuish buildpack install \
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
