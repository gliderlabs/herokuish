#!/usr/bin/env bash
set -eo pipefail
set -x

# get heroku's stack scripts
setup_01="$(cat /tmp/setup-01.sh)"
setup_02="$(cat /tmp/setup-02.sh)"

# write the first script
echo "$setup_01" > /tmp/setup-01.sh
chmod +x /tmp/setup-01.sh

# Ensure we install from ports for arm/arm64 systems
# Skip unsupported syslinux
if [[ -n "$TARGETARCH" ]] && [[ "$TARGETARCH" != "amd64" ]]; then
  sed -i 's#http://archive.ubuntu.com/ubuntu/#http://ports.ubuntu.com/ubuntu-ports/#' /tmp/setup-01.sh
  sed -i '/syslinux/d' /tmp/setup-01.sh
fi

# Skip unsupported postgresql on arm:18
if [[ "$TARGETARCH" == "arm" ]] && [[ "$STACK_VERSION" == "18" ]]; then
  sed -i '/postgresql-client-14/d' /tmp/setup-01.sh
fi

# from base image
/tmp/setup-01.sh

# Install syslinux for amd64 only, mtools always
apt-get update
if [[ "$TARGETARCH" == "amd64" ]]; then
  apt-get install -y --no-install-recommends syslinux
else
  apt-get install -y --no-install-recommends mtools
fi
rm -rf /root/*
rm -rf /tmp/*
rm -rf /var/cache/apt/archives/*.deb
rm -rf /var/lib/apt/lists/*

# write the second script
echo "$setup_02" > /tmp/setup-02.sh
chmod +x /tmp/setup-02.sh

# Skip unsupported postgresql on arm:18
if [[ "$TARGETARCH" == "arm" ]] && [[ "$STACK_VERSION" == "18" ]]; then
  sed -i '/postgresql-server-dev-14/d' /tmp/setup-02.sh
fi

# from build image
/tmp/setup-02.sh

rm -rf /tmp/setup-01.sh /tmp/setup-02.sh
