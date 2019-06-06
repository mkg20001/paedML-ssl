#!/bin/bash

# @doc:     <plugin-id> <name>
init_module "gw"        "Groupwise Messenger"

gw_config() {
  export GW_IP="$(_db gw_ip)"
  generate_file "$PLUGINROOT/groupwise-messenger/template/groupwise.conf" "/etc/nginx/stream.d/groupwise.conf"
}

gw_setup() {
  prompt gw_ip "Groupwise Messenger IP"
}
