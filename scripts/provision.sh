#!/bin/bash

rm -rf node_modules package-lock.json
npm i
OVERRIDE_LOCATION=/usr/lib/paedml-ssl npx dpl-tool ./deploy.yaml paedml-ssl > generated_deployment.sh

vagrant up
