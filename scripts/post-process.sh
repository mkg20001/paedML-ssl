#!/bin/bash

set -e

# TODO: integrate into packer.json

cd output-paedml-ssl-virtualbox-iso

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

#VBoxManage export "$ID" -o dist/paedML-ssl.ovf \
#  --vsys 0 \
#  --product "Let's Encrypt for paedML" --producturl "https://github.com/mkg20001/paedML-ssl" \
#  --vendor "Maciej Krüger (mkg20001)" --vendorurl "https://mkg20001.io" \
#  --description "paedML SSL"

mv paedml-ssl.ovf paedml-ssl-vbox.ovf
VMWARE=$(cat paedml-ssl-vbox.ovf | sed "s|<vssd:VirtualSystemType>virtualbox-2.2</vssd:VirtualSystemType>|<vssd:VirtualSystemType>vmx-08</vssd:VirtualSystemType>|g")
VMWARE=${VMWARE/"$XML_SOUNDCARD"/""}
echo "$VMWARE" > paedml-ssl-vmware.ovf
