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

  if [ -z "$CUR" ] && [ ! -z "$3" ]; then
    CUR="$3" # use $3 as default
  fi

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
  cert_alt=""

  for s in $sub; do
    domains_cert+=("$s.$domain")
    if [ -z "$cert_alt" ]; then
      cert_alt="$s.$domain"
    else
      cert_alt="$cert_alt,$s.$domain"
    fi
  done
}

regen_nginx_config() {
  echo "[*] Anwenden der Änderungen..."
  domain="${domains_cert[0]}"
  cat "$MAIN/proxy/00-default.conf" | sed "s|DOMAIN|$domain|g" | sed "s|SERVER_IP|$ip|g" > /etc/nginx/sites/00-default.conf
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
  echo "[*] Verbinde mit $1..."
  OUT=$(curl -s --show-error --header "Host: verify.internal" "$1/token" || /bin/true)
  if [ "$OUT" != "$TOKEN" ]; then
    echo "[!] Addresse $1 ist nicht erreichbar oder verweist nicht auf den paedML SSL Server! (Fehler siehe oben)" 2>&1
    return 2
  else
    echo "[*] Erreichbar!"
    return 0
  fi
}

ask_net() {
  fam_name="IPv$1"
  fam_id="ipv$1"
  prompt "$fam_id" "Adresse für $fam_name (* angeben um DHCP zu verwenden, - angeben um zu deaktivieren, format: 'ADDRESSE/MASKE')"
  if [ "$(_db $fam_id)" == "*" ]; then
    echo "[*] Aktivieren von DHCP für $fam_name..."
    nmcli con mod "Wired connection 1" \
      "$fam_id.addresses" "" \
      "$fam_id.gateway" "" \
      "$fam_id.dns" "" \
      "$fam_id.dns-search" "" \
      "$fam_id.method" "auto"
  elif [ "$(_db $fam_id)" == "-" ]; then
    echo "[*] Deaktivieren von $fam_name"
    nmcli con mod "Wired connection 1" \
      "$fam_id.addresses" "" \
      "$fam_id.gateway" "" \
      "$fam_id.dns" "" \
      "$fam_id.dns-search" "" \
      "$fam_id.method" "disable"
  else
    prompt "$fam_id.gateway" "Gateway für $fam_name"
    prompt "$fam_id.dns" "DNS für $fam_name"
    prompt "$fam_id.dns-search" "DNS Domain für $fam_name"
    nmcli con mod "Wired connection 1" \
      "$fam_id.addresses" "$(_db $fam_id)" \
      "$fam_id.gateway" "$(_db $fam_id.gateway)" \
      "$fam_id.dns" "$(_db $fam_id.dns)" \
      "$fam_id.dns-search" "$(_db $fam_id.dns-search)" \
      "$fam_id.method" "manual"
  fi
}

setup() {
  ask_net 4
  ask_net 6

  # prompt email "E-Mail für Zertifikatsablaufbenarichtigungen"
  prompt domain "Haupt Domain-Name (z.B. ihre-schule.de)"
  prompt ip "paedML Ziel-Server IP"
  prompt sub "Subdomains (mit leerzeichen getrennt angeben)" "mail vibe"

  setup_web

  echo "[!] Fertig"
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
    checkLoop=false
    for domain in "${domains_cert[@]}"; do
      ex=0
      verify_reachability "$domain" || ex=$?
      if [ $ex -ne 0 ]; then
        checkLoop=true
      fi
    done

    if $checkLoop; then
      echo "[!] Server nicht erreichbar! Bitte überprüfen Sie die Konfiguration und wiederholen Sie den Test durch das Drücken der Eingabetaste."
      read nothing
    fi
  done

  main="${domains_cert[0]}"
  if [ ! -e "/etc/ssl/letsencrypt/$main/$main.conf" ] || (eval $(grep Le_Alt "/etc/ssl/letsencrypt/$main/$main.conf") && [ "$Le_Alt" != "$cert_alt" ]); then
    echo "[*] Holen des Zertifikates..."
    acme_add "${domains_cert[@]}"
  else
    echo "[*] Erneuern des Zertifikates..."
    cron
  fi

  new_hostname="paedml-ssl.${domains_cert[0]}"
  echo "[*] Ändern des Server-Hostnamens zu '$new_hostname'..."
  echo "$new_hostname" > /etc/hostname
  hostname "$new_hostname"
  HOSTS=$(cat /etc/hosts | grep -v 127.0.0.1)
  HOSTS="$HOSTS
$(echo -e "127.0.0.1\t$new_hostname")"
  echo "$HOSTS" > /etc/hosts

  echo "[*] Ändern der Webserver-Konfiguration..."
  regen_nginx_config
  reload_nginx
}

status() {
  echo
  echo "[+] NGinx Status und Logeinträge:"
  echo
  systemctl status nginx -n10 --no-pager --full
  echo
  echo "[+] acme.sh Status und Zertifikate:"
  echo
  acme --list
  echo
  echo "[+] Um die Konfiguration zu verändern, benutzen Sie bitte 'sudo proxy-config setup'"
  echo
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
