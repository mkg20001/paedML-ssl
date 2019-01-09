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

help() {
  echo "Proxy Config Tool"
  echo
  echo "Commands:"
  echo " setup: Do initial configuration (can be run again to change values)"
  echo " status: Nginx status"
  echo " cron: Execute cronjob manually"
  echo " help: This help"
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
      read -p "> $PROMPT (current value '$CUR', leave empty to keep): " NEW
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
  prompt email "E-Mail for notifications"
  prompt domain "Main Domain-Name"
  prompt ip "Server IP"

  email=$(_db email)
  domain=$(_db domain)
  ip=$(_db ip)
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
