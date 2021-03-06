#!/bin/bash

# @doc:     <plugin-id> <name>
init_module "smtp"      "SMTP SSL"

smtp_configure() {
  expose_var SMTP_IP "$(_db smtp_ip)"
  generate_file "modules/smtp-tls-terminator/template/smtp.conf" "/etc/nginx/stream.d/smtp.conf"
  
  ufw allow 587/tcp comment "SMTPS"
}

smtp_setup() {
  prompt smtp_ip "SMTPS IP"
}

smtp_disable() {
  ufw delete allow 587/tcp
  rm -f /etc/nginx/stream.d/smtp.conf
}
