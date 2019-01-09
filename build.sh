#!/bin/bash

set -e

vagrant up
bash export.sh
vagrant halt
sleep 1m

rm -rf dist
mkdir dist
mv paedML-ssl.ova credentials dist
