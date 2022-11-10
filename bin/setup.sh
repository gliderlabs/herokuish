#!/usr/bin/env bash
set -eo pipefail

# install wget and certificates to get the scripts in place
apt-get update
apt-get install -y --no-install-recommends wget ca-certificates
rm -rf /root/*
rm -rf /tmp/*
rm -rf /var/cache/apt/archives/*.deb
rm -rf /var/lib/apt/lists/*

# get heroku's stack scripts
setup_01="$(wget -qO- "https://raw.githubusercontent.com/heroku/stack-images/main/heroku-${STACK_VERSION}/setup.sh")"
setup_02="$(wget -qO- "https://raw.githubusercontent.com/heroku/stack-images/main/heroku-${STACK_VERSION}-build/setup.sh")"

# cleanup ca-certificates
apt-get purge -y ca-certificates
apt-get autoremove -y --purge

# write the first script
echo "$setup_01" > /tmp/setup-01.sh
chmod +x /tmp/setup-01.sh

# Ensure we install from ports for arm/arm64 systems
# Skip unsupported syslinux
if [[ "$TARGETARCH" != "amd64" ]]; then
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
