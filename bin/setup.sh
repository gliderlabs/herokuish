#!/usr/bin/env bash
set -eo pipefail
set -x

# get heroku's stack scripts
setup_01="$(cat /tmp/setup-01.sh)"
setup_02="$(cat /tmp/setup-02.sh)"

# write the first script
echo "$setup_01" >/tmp/setup-01.sh
chmod +x /tmp/setup-01.sh

# Ensure we install from ports for arm64 systems
# Skip unsupported syslinux
if [[ -n "$TARGETARCH" ]] && [[ "$TARGETARCH" != "amd64" ]]; then
  sed -i 's#http://archive.ubuntu.com/ubuntu/#http://ports.ubuntu.com/ubuntu-ports/#' /tmp/setup-01.sh
  sed -i '/syslinux/d' /tmp/setup-01.sh
fi

# Use time_64 packages for 24 stack
if [[ "$STACK_VERSION" == "24" ]]; then
  sed -i 's/libev4/libev4t64/' /tmp/setup-01.sh
  sed -i 's/libevent-2.1-7/libevent-2.1-7t64/' /tmp/setup-01.sh
  sed -i 's/libevent-core-2.1-7/libevent-core-2.1-7t64/' /tmp/setup-01.sh
  sed -i 's/libevent-extra-2.1-7/libevent-extra-2.1-7t64/' /tmp/setup-01.sh
  sed -i 's/libevent-openssl-2.1-7/libevent-openssl-2.1-7t64/' /tmp/setup-01.sh
  sed -i 's/libevent-pthreads-2.1-7/libevent-pthreads-2.1-7t64/' /tmp/setup-01.sh
  sed -i 's/libgnutls-openssl27/libgnutls-openssl27t64/' /tmp/setup-01.sh
  sed -i 's/libgnutls30/libgnutls30t64/' /tmp/setup-01.sh
  sed -i 's/libmemcached11/libmemcached11t64/' /tmp/setup-01.sh
  sed -i 's/libuv1/libuv1t64/' /tmp/setup-01.sh
  sed -i 's/libvips42/libvips42t64/' /tmp/setup-01.sh
  sed -i 's/libzip4/libzip4t64/' /tmp/setup-01.sh
fi

# download the rds-global-bundle.pem
mv /tmp/rds-global-bundle.pem "/build/rds-global-bundle.pem"

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
echo "$setup_02" >/tmp/setup-02.sh
chmod +x /tmp/setup-02.sh

# from build image
/tmp/setup-02.sh

rm -rf /tmp/setup-01.sh /tmp/setup-02.sh
