#!/bin/bash

set -ex

# get bundle
cd /tmp
tar xvfz bundle.tar.gz
rm bundle.tar.gz
cd provision

# setup local repo
tar xvfz "git.tar.gz"
git clone /tmp/provision/.git /usr/lib/paedml-ssl

# run generated deployment
bash deploy.sh

# set keyboard to german
loadkeys de
localectl set-keymap de

# PW=$(cat "pw")
# echo "paedml-ssl:$PW" | chpasswd
# echo "$PW" > /home/paedml-ssl/.pw

# fix git url, ci sometimes sets it to something else
git -C /usr/lib/paedml-ssl remote set-url origin https://github.com/mkg20001/paedML-SSL.git
# checkout to master, but without pulling yet
git -C /usr/lib/paedml-ssl checkout -b master
git -C /usr/lib/paedml-ssl fetch
git -C /usr/lib/paedml-ssl branch master -u origin/master

# run update routine
cd /usr/lib/paedml-ssl
bash scripts/update.sh
