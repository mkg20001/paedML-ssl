#!/bin/bash

set -e

ID=$(cat .vagrant/machines/default/virtualbox/id)

VBoxManage export "$ID" -o letsencrypt.ovf \
  --product "Let's Encrypt Standalone VM" --producturl "https://github.com/mkg20001/le-standalone" \
  --vendor "Maciej Krüger (mkg20001)" --vendorurl "https://mkg20001.io" \
  --description "paedML SSL"
