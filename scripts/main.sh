#!/bin/bash

set -e

cd /tmp
for f in git.tar.gz pw deploy.sh; do
  wget "$HTTP_SERVER/$f"
done

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
