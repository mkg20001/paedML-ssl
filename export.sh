#!/bin/bash

set -e

ID=$(cat .vagrant/machines/default/virtualbox/id)

VBoxManage export "$ID" -o dist/paedML-ssl.ovf \
  --vsys 0 \
  --product "Let's Encrypt for paedML" --producturl "https://github.com/mkg20001/paedML-ssl" \
  --vendor "Maciej Krüger (mkg20001)" --vendorurl "https://mkg20001.io" \
  --description "paedML SSL"

mv dist/paedML-ssl.ovf dist/paedML-ssl-vbox.ovf
cat dist/paedML-ssl-vbox.ovf | sed "s|<vssd:VirtualSystemType>virtualbox-2.2</vssd:VirtualSystemType>|<vssd:VirtualSystemType>vmx-08</vssd:VirtualSystemType>|g" > dist/paedML-ssl-vmware.ovf
