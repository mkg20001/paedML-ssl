#!/bin/bash

set -e

umount /le-standalone || /bin/true
rm -rf /le-standalone
mkdir /le-standalone
mount --bind /vagrant /le-standalone
cd /le-standalone

echo -n "paedml-ssl" > /etc/hostname
hostname paedml-ssl

# because npm
export SUDO_GID=
export SUDO_COMMAND=
export SUDO_USER=
export SUDO_UID=
export HOME=/root

if ! which node 2> /dev/null > /dev/null; then
  wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
  VERSION=node_10.x
  DISTRO="$(lsb_release -s -c)"
  echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" | tee /etc/apt/sources.list.d/nodesource.list
  echo "deb-src https://deb.nodesource.com/$VERSION $DISTRO main" | tee -a /etc/apt/sources.list.d/nodesource.list
  apt-get update
  apt-get install nodejs -y
fi

bash update.sh

# yes
PW=$(curl -s 'https://xkpasswd.net/s/index.cgi' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data 'a=genpw&n=1&c=%7B%22num_words%22%3A2%2C%22word_length_min%22%3A4%2C%22word_length_max%22%3A8%2C%22case_transform%22%3A%22LOWER%22%2C%22separator_character%22%3A%22-%22%2C%22padding_digits_before%22%3A0%2C%22padding_digits_after%22%3A0%2C%22padding_type%22%3A%22NONE%22%2C%22random_increment%22%3A%22AUTO%22%7D' | jq -r .passwords[0])

echo "vagrant:$PW" | chpasswd
loadkeys de
localectl set-keymap de

echo "$PW" > /home/vagrant/.pw

echo -e "Zugangsdaten:\n\tBenutzer:\n\t\tvagrant\n\tPasswort:\n\t\t$PW\n\tNach dem Starten und Anmelden den Befehl 'sudo proxy-config setup' ausführen um mit der Einrichtung zu beginnen" > /vagrant/credentials
unix2dos /vagrant/credentials

echo "====[ SETUP COMPLETE ]===="
echo "  User:"
echo "    vagrant"
echo "  Password:"
echo "    $PW"
echo "=========================="

cd /
while ! umount /le-standalone; do
  sleep 1s
done
rmdir /le-standalone
cp -rp /vagrant /le-standalone # this ensures that the machine continues working without the /vagrant part mounted
