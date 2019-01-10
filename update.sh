#!/bin/bash

rm -rf node_modules
npm i
./node_modules/.bin/dpl-tool deploy.yaml | bash -
echo -e "Letsencrypt für paedML - Entwickelt von Maciej Krüger\n\nVerwaltung:\n\tsudo proxy-config - Nginx Proxy konfigurieren\n\tsudo proxy-update - Server software aktualisieren\n" > /etc/motd
