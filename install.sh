#!/bin/bash

MAIN=$(dirname $(readlink -f $0))
cd "$MAIN"

echo -n "le-standalone" > /etc/hostname
hostname le-standalone

die() {
  echo "$@" 1>&2
  exit 2
}

# because npm
export SUDO_GID=
export SUDO_COMMAND=
export SUDO_USER=
export SUDO_UID=
export HOME=/root

if ! which node 2> /dev/null > /dev/null; then
  wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
  VERSION=node_10.x
  DISTRO="$(lsb_release -s -c)"
  echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" | tee /etc/apt/sources.list.d/nodesource.list
  echo "deb-src https://deb.nodesource.com/$VERSION $DISTRO main" | tee -a /etc/apt/sources.list.d/nodesource.list
  apt-get update
  apt-get install nodejs -y
fi

npm i

./node_modules/.bin/dpl-tool deploy.yaml | bash -

