#!/bin/bash

set -e

# because npm
export SUDO_GID=
export SUDO_COMMAND=
export SUDO_USER=
export SUDO_UID=
export HOME=/root

# rm node modules and re-install
rm -rf node_modules package-lock.json
npm i
# generate script and deploy
./node_modules/.bin/dpl-tool deploy.yaml paedml-ssl | bash -

# update motd
echo -e "Let's Encrypt für paedML - Entwickelt von Maciej Krüger\n\nVerwaltung:\n\tsudo proxy-config - Nginx Proxy konfigurieren\n\tsudo proxy-update - Server software aktualisieren\n" > /etc/motd
