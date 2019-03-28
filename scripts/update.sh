#!/bin/bash

set -e

# update motd
echo -e "Let's Encrypt für paedML - Entwickelt von Maciej Krüger\n\nVerwaltung:\n\tsudo proxy-config - Nginx Proxy konfigurieren\n\tsudo proxy-update - Server software aktualisieren\n" > /etc/motd
