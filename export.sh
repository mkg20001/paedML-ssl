#!/bin/bash

set -e

ID=$(cat .vagrant/machines/default/virtualbox/id)

VBoxManage export "$ID" -o paedML-ssl.ova \
  --vsys 0 \
  --product "Let's Encrypt Standalone Proxy for paedML" --producturl "https://github.com/mkg20001/paedML-ssl" \
  --vendor "Maciej Krüger (mkg20001)" --vendorurl "https://mkg20001.io" \
  --description "paedML SSL"
