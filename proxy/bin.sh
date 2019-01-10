#!/bin/bash

DB="/var/lib/proxy-config"

if [ ! -e "$DB" ]; then
  touch "$DB"
fi

_db() { # GET <key> SET <key> <value>
  if [ -z "$2" ]; then
    cat "$DB" | grep "^$1=" | sed "s|$1=||g" || /bin/true
  else
    newdb=$(cat "$DB" | grep -v "^$1=" || /bin/true)
    newdb="$newdb
$1=$2"
    echo "$newdb" > "$DB"
  fi
}

acme() {
  /root/.acme.sh/acme.sh --config-home /etc/ssl/letsencrypt "$@"
}

help() {
  echo "Proxy Konfigurations Tool"
  echo
  echo "Befehler:"
  echo " setup: Initielle konfiguration durchführen (kann auch erneut ausgeführt werden um die Werte zu ändern)"
  echo " status: Nginx status"
  echo " cron: Cronjob manuell ausführen"
  echo " logs: Nginx Logdateien"
  echo " help: Diese hilfe"
  echo
  exit 2
}

prompt() {
  KEY="$1"
  PROMPT="$2"
  CUR=$(_db "$KEY")
  NEW=""

  while [ -z "$NEW" ]; do
    if [ ! -z "$CUR" ]; then
      read -p "> $PROMPT (aktueller wert '$CUR', leer lassen um beizubehalten): " NEW
      if [ -z "$NEW" ]; then
        NEW="$CUR"
      fi
    else
      read -p "$PROMPT: " NEW
    fi
  done

  echo "< $NEW"

  _db "$KEY" "$NEW"
}

setup() {
  if [ -z "$(_db sub)" ]; then
    _db sub "mail vibe"
  fi

  prompt email "E-Mail für Zertifikatsablaufbenarichtigungen"
  prompt domain "Haupt Domain-Name"
  prompt ip "Server IP"
  prompt sub "Subdomains (leerzeichen getrennt angeben)"

  email=$(_db email)
  domain=$(_db domain)
  ip=$(_db ip)

  echo "[*] Anwenden der Änderungen..."

  cat /etc/nginx/sites/00-default.conf.tpl | sed "s|DOMAIN|$domain|g" > /etc/nginx/sites/00-default.conf

  echo "[*] Neuladen von nginx..."

  service nginx reload

  echo "[!] Fertig"
}

status() {
  sudo systemctl status nginx
}

cron() {
  :
}

main() {
  case "$1" in
    setup|status|cron|help)
      "$1"
      ;;
    *)
      help
      ;;
  esac
}

main "$@"
