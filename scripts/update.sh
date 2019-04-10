#!/bin/bash

set -e

# update motd
echo -e "Let's Encrypt für paedML - Entwickelt von Maciej Krüger\n\nVerwaltung:\n\tsudo proxy setup - Proxy Server einrichten\n\tsudo proxy status - Proxy Server Status\n\tsudo proxy-update - Server software aktualisieren\n" > /etc/motd
