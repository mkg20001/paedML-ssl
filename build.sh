#!/bin/bash

set -e

vagrant up
bash export.sh
vagrant halt

rm -rf dist
mkdir dist
mv paedML-ssl.ovf credentials /dist
