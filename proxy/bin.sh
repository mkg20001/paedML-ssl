#!/bin/bash

set -e

shopt -s nullglob

MAIN=$(dirname $(dirname $(readlink -f $0)))
SHARED="$MAIN/shared"

. "$SHARED/modules/basic.sh"
_module _root
_module db
_module ui
_module net

init_db "/var/lib/proxy-config"

mods=()

init_module() {
  MOD_ID="$1"
  MOD_NAME="$2"

  mods+=("$MOD_ID")
  # module will inizialize it's own hooks using "${MOD_ID}_${HOOK_NAME}", will be called using eval
}

sandbox_eval_fnc() {
  local fnc="$1"

  if [ "$(type -t "$fnc")" == "function" ]; then
    (
      eval "$fnc"
    ) # subshell to prevent shell suiciding when plugin fails and to prevent plugins interferring with each other
  fi
}

setup_plugins() {
  prompt mods "Zu verwendende Plugin-IDs angeben (verfügbar: ${mods[@]})"
  # TODO: remove routine (hook: disable)
}

do_plugin_hooks() {
  for mod in $(_db mods); do
    sandbox_eval_fnc "${mod}_$1"
  done
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
  echo " status: nginx status"
  echo " cron: Cronjob manuell ausführen"
  echo " logs: nginx Logdateien"
  echo " help: Diese Hilfe"
  echo
  exit 2
}

get_domains() {
  domain=$(_db domain)
  sub=$(_db sub)
  domains_cert=("$domain")
  cert_alt=""

  for s in $sub; do
    domains_cert+=("$s.$domain")
  done

  realmain="${domains_cert[0]}"
  if [ "$(_db usemain)" == "n" ]; then
    domains_cert=("${domains_cert[@]:1}")
  fi
  domains_alt=("${domains_cert[@]:1}")
  main="${domains_cert[0]}"
  domain="$main"

  for d in ${domains_alt[*]}; do
    if [ -z "$cert_alt" ]; then
      cert_alt="$d"
    else
      cert_alt="$cert_alt,$d"
    fi
  done

  if [ -z "$cert_alt" ]; then
    cert_alt="no"
  fi
}

generate_file() {
  # envsubst <"$MAIN/proxy/$1" >"$2"
  eval "cat '$MAIN/proxy/$1' $CHAIN" > "$2" # TODO: conf values can use ' to escape sandbox
}

expose_var() {
  CHAIN="$CHAIN | sed 's|\$$1|$2|g'"
}

regen_nginx_config() {
  echo "[*] Anwenden der Änderungen..."
  ip=$(_db ip)
  get_domains

  expose_var DOMAIN "$domain"
  expose_var CERT "/etc/ssl/letsencrypt/$domain/fullchain.cer"
  expose_var KEY "/etc/ssl/letsencrypt/$domain/$domain.key"
  expose_var SERVER_IP "$ip"

  generate_file "00-default.conf" "/etc/nginx/sites/00-default.conf"
}

regen_config() {
  CHAIN=""

  regen_nginx_config

  do_plugin_hooks "configure"
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

setup() {
  setup_net

  # prompt email "E-Mail für Zertifikatsablaufbenarichtigungen"
  prompt domain "Haupt Domain-Name (z.B. ihre-schule.de)"
  prompt ip "paedML Ziel-Server IP-Addresse oder DNS (IPv6 Addressen [umklammert] angeben)"
  prompt sub "Subdomains (mit leerzeichen getrennt angeben)" "server mail vibe filr"
  prompt usemain "Maindomain verwenden (j=ja, n=nein)" j
  
  setup_plugins
  do_plugin_hooks setup

  setup_web

  echo "[!] Fertig"
}

load_plugins() {
  for f in "$MAIN/proxy/modules/"*; do
    MODULE=$(basename "$f")
    . "$f/index.sh"
  done
}

setup_web() {
  # email=$(_db email)
  ip=$(_db ip)
  get_domains

  if [ ! -e "/etc/ssl/letsencrypt/$domain/fullchain.cer" ]; then
    echo "[*] Seite wird in Wartungsmodus geschaltet..."
    rm -f /etc/nginx/sites/00-default.conf
  else
    regen_config
  fi

  reload_nginx

  checkLoop=true

  if [ ! -z "$IGNORE_REACHABILITY_CHECK" ]; then
    echo "[*] Verbindungsüberprüfung ignoriert..."
    checkLoop=false
  fi

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
      echo "[!] (Falls Sie sich sicher sind das die Domain erreichbar ist und auf die Proxy verweist, tippen sie IGNORIEREN)"
      read user
      if [ "$user" == "IGNORIEREN" ]; then
        checkLoop=false
        echo "[*] Ignoriere..."
      fi
    fi
  done

  if [ ! -e "/etc/ssl/letsencrypt/$main/$main.conf" ] || (eval $(grep Le_Alt "/etc/ssl/letsencrypt/$main/$main.conf") && [ "$Le_Alt" != "$cert_alt" ]); then
    echo "[*] Holen des Zertifikates..."
    acme_add "${domains_cert[@]}"
  else
    echo "[*] Erneuern des Zertifikates..."
    cron
  fi

  new_hostname="paedml-ssl.$realmain"
  echo "[*] Ändern des Server-Hostnamens zu '$new_hostname'..."
  echo "$new_hostname" > /etc/hostname
  hostname "$new_hostname"
  HOSTS=$(cat /etc/hosts | grep -v 127.0.0.1)
  HOSTS="$HOSTS
$(echo -e "127.0.0.1\t$new_hostname")"
  echo "$HOSTS" > /etc/hosts

  echo "[*] Ändern der Webserver-Konfiguration..."
  regen_config
  reload_nginx
}

status() {
  echo
  echo "[+] nginx Status und Logeinträge:"
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
      load_plugins
      "$1"
      ;;
    acme|acme_add)
      "$1" "$@"
      ;;
    *)
      help
      ;;
  esac
}

main "$@"
