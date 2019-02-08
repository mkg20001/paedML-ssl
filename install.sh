#!/bin/bash

set -e

# setup local repo and bind-mount
umount /usr/lib/paedml-ssl || /bin/true
rm -rf /usr/lib/paedml-ssl
mkdir /usr/lib/paedml-ssl
mount --bind /vagrant /usr/lib/paedml-ssl
cd /usr/lib/paedml-ssl

# setup hostname
echo -n "paedml-ssl" > /etc/hostname
hostname paedml-ssl

# run generated deployment
bash generated_deployment.sh

# run update routine
bash update.sh

# yes, really. but you should change the password anyways so this *shouldn't* really bother anyone
PW=$(curl -s 'https://xkpasswd.net/s/index.cgi' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data 'a=genpw&n=1&c=%7B%22num_words%22%3A2%2C%22word_length_min%22%3A4%2C%22word_length_max%22%3A8%2C%22case_transform%22%3A%22LOWER%22%2C%22separator_character%22%3A%22-%22%2C%22padding_digits_before%22%3A0%2C%22padding_digits_after%22%3A0%2C%22padding_type%22%3A%22NONE%22%2C%22random_increment%22%3A%22AUTO%22%7D' | jq -r .passwords[0])
echo "vagrant:$PW" | chpasswd
# and then drop the credentials somewhere
echo "$PW" > /home/vagrant/.pw
echo -e "Zugangsdaten:\n\tBenutzer:\n\t\tvagrant\n\tPasswort:\n\t\t$PW\n\tNach dem Starten und Anmelden den Befehl 'sudo proxy-config setup' ausführen um mit der Einrichtung zu beginnen" > /vagrant/credentials
unix2dos /vagrant/credentials

# because our target audience is pretty specific let's just setup the only keyboard layout that's ever going to be used
loadkeys de
localectl set-keymap de

# umount the bind mount
cd /
while ! umount /usr/lib/paedml-ssl; do
  sleep 1s
done
rmdir /usr/lib/paedml-ssl

# this ensures that the machine continues working without the /vagrant part mounted. we'll just do a clean git clone and copy the remote to ensure no garbage gets accidentely included
git clone /vagrant/.git /usr/lib/paedml-ssl
git -C /usr/lib/paedml-ssl remote set-url origin "$(git -C /vagrant remote get-url origin)"
