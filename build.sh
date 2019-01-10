#!/bin/bash

set -e

vagrant up
vagrant halt

rm -rf dist
mkdir dist
mv credentials dist

sleep 1m
bash export.sh
