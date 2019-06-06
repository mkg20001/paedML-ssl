#!/bin/bash

# @doc:     <plugin-id> <name>
init_module "gw"        "Groupwise Messenger"

gw_configure() {
  expose_var GW_IP "$(_db gw_ip)"
  generate_file "modules/groupwise-messenger-tls-terminator/template/groupwise.conf" "/etc/nginx/stream.d/groupwise.conf"
  
  ufw allow 8300/tcp comment "Groupwise Messenger"
}

gw_setup() {
  prompt gw_ip "Groupwise Messenger IP"
}

gw_disable() {
  ufw remove allow 8300/tcp
  rm -f /etc/nginx/stream.d/groupwise.conf
}
