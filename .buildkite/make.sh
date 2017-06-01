#!/bin/bash
set -eu

: ${PIPA_IMAGE_FULL_NAME?Missing Pipa environment}

export IMAGE_NAME=$PIPA_IMAGE_FULL_NAME | cut -d':' -f1
export BUILD_TAG=$PIPA_IMAGE_FULL_NAME | cut -d':' -f2
make deps build-in-docker
