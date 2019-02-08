#!/bin/bash

set -e

DB="/var/lib/proxy-config"
MAIN=$(dirname $(dirname $(readlink -f $0)))

if [ $(id -u) -gt 0 ]; then
  echo "FEHLER: Dieser Befehl muss als Benutzer root ausgeführt werden. Verwenden Sie bitte stattdessen 'sudo $0 $*'" >&2
  exit 2
fi

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

acme_add() {
  domains=()
  while [ ! -z "$1" ]; do
    domains+=("-d" "$1")
    shift
  done

  acme --reloadcmd "service nginx reload" --issue -w /tmp/ "${domains[@]}"
}

help() {
  echo "Proxy Konfigurations Tool"
  echo
  echo "Befehle:"
  echo " setup: Initielle Konfiguration durchführen (kann auch erneut ausgeführt werden um die Werte zu ändern)"
  echo " status: Nginx status"
  echo " cron: Cronjob manuell ausführen"
  echo " logs: Nginx Logdateien"
  echo " help: Diese Hilfe"
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

get_domains() {
  domain=$(_db domain)
  sub=$(_db sub)
  domains_cert=("$domain")

  for s in $sub; do
    domains_cert+=("$s.$domain")
  done
}

regen_nginx_config() {
  echo "[*] Anwenden der Änderungen..."
  cat "$MAIN/00-default.conf" | sed "s|DOMAIN|$domain|g" | sed "s|SERVER_IP|$ip|g" > /etc/nginx/sites/00-default.conf
}

reload_nginx() {
  if sudo service nginx status 2>/dev/null >/dev/null; then
    echo "[*] Neuladen von nginx..."
    service nginx reload
  else
    echo "[*] Neustarten von nginx..."
    service nginx restart
  fi
}

verify_reachability() {
  TOKEN=$RANDOM
  echo "$TOKEN" > /tmp/verify-token
  OUT=$(curl -s --header "Host: verify.internal" "$1/token")
  if [ "$OUT" != "$TOKEN" ]; then
    # TODO: better error handling, show better errors
    echo "[!] Addresse $1 ist nicht erreichbar oder verweist nicht auf den paedML SSL Server!" 2>&1
    exit 2
  fi
}

setup() {
  if [ -z "$(_db sub)" ]; then
    _db sub "mail vibe"
  fi

  # prompt email "E-Mail für Zertifikatsablaufbenarichtigungen"
  prompt net4 "Addresse für IPv4 (* angeben um DHCP zu verwenden)"
  prompt net6 "Addresse für IPv6 (* angeben um DHCP zu verwenden)"
  prompt domain "Haupt Domain-Name (z.B. ihre-schule.de)"
  prompt ip "paedML Ziel-Server IP"
  prompt sub "Subdomains (leerzeichen getrennt angeben)"

  setup_net

  setup_web

  echo "[!] Fertig"
}

setup_net() {
  echo "[!] Netzwerkkonfiguration unfertig!"
}

setup_web() {
  # email=$(_db email)
  ip=$(_db ip)
  get_domains

  if [ ! -e "/etc/ssl/letsencrypt/$domain/fullchain.cer" ]; then
    echo "[*] Seite wird in Wartungsmodus geschaltet..."
    rm -f /etc/nginx/sites/00-default.conf
  else
    regen_nginx_config
  fi

  reload_nginx

  checkLoop=true
  while $checkLoop; do
    echo "[*] Überprüfen ob der Server erreichbar ist..."
    for domain in "${domains_cert[@]}"; do
      # TODO: catch error
      verify_reachability "$domain"
    done

    # TODO: check if success
    if false; then
      echo "[!] Server nicht erreichbar! Bitte überprüfen Sie die Konfiguration und wiederholen Sie den test durch das Drücken der Eingabetaste."
      read nothing
    else
      checkLoop=false
    fi
  done

  echo "[*] Holen des Zertifikates..."
  acme_add "${domains_cert[@]}"

  new_hostname="paedml-ssl.$domain"
  echo "[*] Ändern des Server-Hostnamens zu '$new_hostname'..."
  echo "$new_hostname" > /etc/hostname
  hostname "$new_hostname"

  echo "[*] Ändern der Webserver-Konfiguration..."
  if [ ! -e /etc/nginx/sites/00-default.conf ]; then
    regen_nginx_config
    reload_nginx
  fi
}

status() {
  systemctl status nginx
}

cron() {
  acme --cron --home "/root/.acme.sh"
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
