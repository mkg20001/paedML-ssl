#!/bin/bash

set -e

vagrant up
bash export.sh

rm -rf dist
mkdir dist
mv paedML-ssl.ovf credentials /dist
