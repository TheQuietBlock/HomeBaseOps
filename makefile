.PHONY: init apply inventory ansible all

MAKE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TERRAFORM_DIR := $(MAKE_DIR)/terraform

init:
	terraform -chdir=$(TERRAFORM_DIR) init -upgrade

apply: init
	terraform -chdir=$(TERRAFORM_DIR) apply -auto-approve

inventory:
	./scripts/generate_inventory.sh

ansible:
	cd ansible && ansible-playbook -i inventory.ini playbooks/site.yml

all: apply inventory ansible

