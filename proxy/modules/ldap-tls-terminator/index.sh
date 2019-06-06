#!/bin/bash

# @doc:     <plugin-id> <name>
init_module "ldaps"        "LDAP-over-TLS"

ldaps_configure() {
  expose_var LDAP_IP "$(_db ldap_ip)"
  expose_var LDAP_PORT "$(_db ldap_port)" 
  expose_var LDAP_SSL "$(_db ldap_ssl)"
  generate_file "modules/ldap-tls-terminator/template/ldaps.conf" "/etc/nginx/stream.d/ldaps.conf"
  
  ufw allow 636/tcp comment "LDAP SSL"
}

ldaps_setup() {
  prompt ldap_ip "LDAP-Server IP"
  prompt ldap_port "LDAP-Server Port" 636
  prompt ldap_ssl "TLS für den Zugriff auf den Zielserver verwenden? (on/off)" on
}

ldaps_disable() {
  ufw remove allow 636/tcp
  rm -f /etc/nginx/stream.d/ldaps.conf
}
