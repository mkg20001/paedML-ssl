build:
	VM_NAME=paedml-ssl make -C ./shared build
dist:
	VM_NAME=paedml-ssl make -C ./shared dist
dev:
	VM_NAME=paedml-ssl make -C ./shared dev

prepare:
	touch /tmp/g

