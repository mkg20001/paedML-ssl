#!/bin/bash

set -e

vagrant up
vagrant halt

rm -rf dist
mkdir dist
mv credentials dist

sleep 10s
bash export.sh
tar cvfz paedML-ssl.tar.gz dist
