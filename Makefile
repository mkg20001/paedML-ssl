build: prepare
	packer build packer.json
prepare:
	rm -rf provision
	mkdir provision
	tar cvfzp provision/git.tar.gz .git
	rm -rf node_modules package-lock.json
	npm i
	OVERRIDE_LOCATION=/usr/lib/paedml-ssl npx dpl-tool ./deploy.yaml > provision/deploy.sh
	echo $(shell curl -s 'https://xkpasswd.net/s/index.cgi' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data 'a=genpw&n=1&c=%7B%22num_words%22%3A2%2C%22word_length_min%22%3A4%2C%22word_length_max%22%3A8%2C%22case_transform%22%3A%22LOWER%22%2C%22separator_character%22%3A%22-%22%2C%22padding_digits_before%22%3A0%2C%22padding_digits_after%22%3A0%2C%22padding_type%22%3A%22NONE%22%2C%22random_increment%22%3A%22AUTO%22%7D' | grep -o "[\"[a-z0-9-]*\"]" | grep -o "[a-z0-9-]*") > provision/pw
	tar cvfz provision.tar.gz provision/
	mv provision.tar.gz provision/bundle.tar.gz
export:
	bash scripts/export.sh

dist: build export
	echo -e "Zugangsdaten:\n\tBenutzer:\n\t\tvagrant\n\tPasswort:\n\t\t$PW\n\tNach dem Starten und Anmelden den Befehl 'sudo proxy-config setup' ausführen um mit der Einrichtung zu beginnen" > /vagrant/credentials
