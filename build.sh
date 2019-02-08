#!/bin/bash

set -e

rm -rf node_modules package-lock.json
npm i
OVERRIDE_LOCATION=/usr/lib/paedml-ssl npx dpl-tool ./deploy.yaml paedml-ssl > generated_deployment.sh

vagrant up
vagrant halt

rm -rf dist
mkdir dist
mv credentials dist

sleep 10s
bash export.sh
tar cvf paedML-ssl.tar.xz --lzma dist
