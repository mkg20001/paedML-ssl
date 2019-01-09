#!/bin/bash

set -e

MAIN=$(dirname $(readlink -f $0))
cd "$MAIN"

echo -n "le-standalone" > /etc/hostname
hostname le-standalone

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

# yes
PW=$(curl -s 'https://xkpasswd.net/s/index.cgi' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data 'a=genpw&n=1&c=%7B%22num_words%22%3A4%2C%22word_length_min%22%3A4%2C%22word_length_max%22%3A8%2C%22case_transform%22%3A%22LOWER%22%2C%22separator_character%22%3A%22-%22%2C%22padding_digits_before%22%3A0%2C%22padding_digits_after%22%3A0%2C%22padding_type%22%3A%22NONE%22%2C%22random_increment%22%3A%22AUTO%22%7D' | jq -r .passwords[0])

echo "ubuntu:$PW" | chpasswd

echo "====[ SETUP COMPLETE ]===="
echo "Generated Password:"
echo "$PW"
echo "=========================="
