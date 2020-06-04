#!/bin/bash

# @doc:     <plugin-id> <name>
init_module "exchange"  "Microsoft Exchange"

gw_configure() {
  expose_var DEST_IP "$(_db gw_ip)"
  expose_var PUB_DOMAIN "$(_db pub_domain)"
  generate_file "modules/microsoft-exchange/template/exchange.conf" "/etc/nginx/sites/exchange.conf"
  generate_file "modules/microsoft-exchange/template/more.conf" "/etc/nginx/addon.d/00-amore.conf"
}

gw_setup() {
  prompt dest_ip "Microsoft Exchange IP"
  prompt pub_domain "Microsoft Exchange Domain (z.B. mail)"
}

gw_disable() {
  rm -f /etc/nginx/sites/exchange.conf
  rm -f /etc/nginx/addon.d/00-amore.conf
}
