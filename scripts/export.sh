#!/bin/bash

set -e

vagrant halt

rm -rf dist
mkdir dist
mv credentials dist

sleep 10s

ID=$(cat .vagrant/machines/default/virtualbox/id)

XML_SOUNDCARD="      <Item>
        <rasd:AddressOnParent>3</rasd:AddressOnParent>
        <rasd:AutomaticAllocation>false</rasd:AutomaticAllocation>
        <rasd:Caption>sound</rasd:Caption>
        <rasd:Description>Sound Card</rasd:Description>
        <rasd:ElementName>sound</rasd:ElementName>
        <rasd:InstanceID>6</rasd:InstanceID>
        <rasd:ResourceSubType>ensoniq1371</rasd:ResourceSubType>
        <rasd:ResourceType>35</rasd:ResourceType>
      </Item>"

VBoxManage export "$ID" -o dist/paedML-ssl.ovf \
  --vsys 0 \
  --product "Let's Encrypt for paedML" --producturl "https://github.com/mkg20001/paedML-ssl" \
  --vendor "Maciej Krüger (mkg20001)" --vendorurl "https://mkg20001.io" \
  --description "paedML SSL"

mv dist/paedML-ssl.ovf dist/paedML-ssl-vbox.ovf
VMWARE=$(cat dist/paedML-ssl-vbox.ovf | sed "s|<vssd:VirtualSystemType>virtualbox-2.2</vssd:VirtualSystemType>|<vssd:VirtualSystemType>vmx-08</vssd:VirtualSystemType>|g")
VMWARE=${VMWARE/"$XML_SOUNDCARD"/""}
echo "$VMWARE" > dist/paedML-ssl-vmware.ovf

tar cvf paedML-ssl.tar.xz --lzma dist
