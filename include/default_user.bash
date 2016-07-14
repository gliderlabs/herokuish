#!/usr/bin/env bash

addgroup --quiet --gid "32767" "herokuishuser" && \
adduser \
    --shell /bin/bash \
    --disabled-password \
    --force-badname \
    --no-create-home \
    --uid "32767" \
    --gid "32767" \
    --gecos '' \
    --quiet \
    --home "/app" \
    "herokuishuser"
