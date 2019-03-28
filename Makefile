build:
	VM_NAME=paedml-ssl make -C ./shared build
dist:
	VM_NAME=paedml-ssl make -C ./shared dist

prepare:
	touch /tmp/g

