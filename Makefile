build: prepare
	packer build packer.json
prepare:
	tar cvfzp .git http/git.tar.gz
export:
	bash scripts/export.sh

dist: build export
