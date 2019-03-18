#!/bin/bash

set -e

# get bundle
cd /tmp
tar xvfz bundle.tar.gz

# setup local repo
tar xvfz "git.tar.gz"
git clone /tmp/.git /usr/lib/paedml-ssl

# run generated deployment
bash deploy.sh

PW=$(cat "pw")
echo "vagrant:$PW" | chpasswd
echo "$PW" > /home/vagrant/.pw

# fix git url, ci sometimes sets it to something else
git -C /usr/lib/paedml-ssl remote set-url origin https://github.com/mkg20001/paedML-SSL.git

# run update routine
cd /usr/lib/paedml-ssl
bash scripts/update.sh
