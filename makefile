.PHONY: init apply inventory ansible all docker-deploy docker-status docker-help test

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

# Docker Swarm management targets
docker-deploy:
	./scripts/docker-swarm-manager.sh deploy-swarm

docker-status:
	./scripts/docker-swarm-manager.sh check-status

docker-help:
	./scripts/docker-swarm-manager.sh help

# Test target
test:
	./scripts/test-docker-setup.sh

