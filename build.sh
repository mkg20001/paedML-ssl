#!/bin/bash

set -e

vagrant up
vagrant halt

rm -rf dist
mkdir dist
mv credentials dist

sleep 10s
bash export.sh
tar cvf paedML-ssl.tar.lzma --lzma dist
