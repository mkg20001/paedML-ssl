#!/bin/bash

set -e

vagrant up
bash export.sh
vagrant halt
sleep 10s

rm -rf dist
mkdir dist
mv paedML-ssl.ova credentials dist
