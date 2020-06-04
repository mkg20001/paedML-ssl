#!/bin/bash

# @doc:     <plugin-id> <name>
init_module "imap"      "IMAP SSL"

imap_configure() {
  expose_var imap_IP "$(_db imap_ip)"
  generate_file "modules/imap-tls-terminator/template/imap.conf" "/etc/nginx/stream.d/imap.conf"
  
  ufw allow 993/tcp comment "IMAPS"
}

imap_setup() {
  prompt imap_ip "IMAPS IP"
}

imap_disable() {
  ufw delete allow 993/tcp
  rm -f /etc/nginx/stream.d/imap.conf
}
