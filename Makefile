build: provision export
export:
	bash scripts/export.sh
provision:
	bash scripts/provision.sh
enable-dev:
	bash scripts/enable-dev.sh
	bash scripts/update.sh
destroy:
	vagrant destroy -f
re-provision: destroy provision
update-box:
	vagrant box update
	make re-provision
