#!/bin/bash

MAIN=$(dirname $(dirname $(readlink -f $0)))

apt update
apt dist-upgrade -y

cd "$MAIN"
git pull
bash update.sh
