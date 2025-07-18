#!/bin/bash
# Docker Swarm Management Script for HomeBaseOps
# This script provides common Docker Swarm management operations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
ANSIBLE_DIR="$REPO_ROOT/ansible"
TERRAFORM_DIR="$REPO_ROOT/terraform"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_requirements() {
    local missing_tools=()
    
    if ! command -v ansible &> /dev/null; then
        missing_tools+=("ansible")
    fi
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Missing required tools: ${missing_tools[*]}"
        error "Please install the missing tools before running this script"
        exit 1
    fi
}

generate_inventory() {
    log "Generating Ansible inventory from Terraform outputs..."
    cd "$REPO_ROOT"
    
    if [ ! -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
        error "Terraform state file not found. Please run 'terraform apply' first."
        exit 1
    fi
    
    bash scripts/generate_inventory.sh
    
    if [ -f "$ANSIBLE_DIR/inventory.ini" ]; then
        log "Inventory generated successfully"
        info "Docker nodes in inventory:"
        grep -A 10 "\[docker\]" "$ANSIBLE_DIR/inventory.ini" || true
    else
        error "Failed to generate inventory file"
        exit 1
    fi
}

deploy_docker_swarm() {
    log "Deploying Docker Swarm to all nodes..."
    cd "$ANSIBLE_DIR"
    
    if [ ! -f "inventory.ini" ]; then
        warning "Inventory file not found. Generating now..."
        generate_inventory
    fi
    
    # Run only the Docker-related parts of the playbook
    ansible-playbook -i inventory.ini playbooks/site.yml --limit docker --tags docker
}

check_swarm_status() {
    log "Checking Docker Swarm status..."
    cd "$ANSIBLE_DIR"
    
    if [ ! -f "inventory.ini" ]; then
        error "Inventory file not found. Please run 'generate_inventory' first."
        exit 1
    fi
    
    # Get the manager node (first docker node)
    MANAGER_NODE=$(grep -A 1 "\[docker\]" inventory.ini | tail -1 | awk '{print $1}')
    
    if [ -z "$MANAGER_NODE" ]; then
        error "Could not find Docker manager node in inventory"
        exit 1
    fi
    
    info "Running swarm status check on manager node: $MANAGER_NODE"
    ansible "$MANAGER_NODE" -i inventory.ini -m shell -a "docker node ls" -b
}

deploy_stack() {
    local stack_name=${1:-"homebase"}
    local compose_file=${2:-"docker-compose.yml"}
    
    log "Deploying Docker stack: $stack_name"
    cd "$ANSIBLE_DIR"
    
    if [ ! -f "$compose_file" ]; then
        error "Compose file not found: $compose_file"
        exit 1
    fi
    
    # Get the manager node
    MANAGER_NODE=$(grep -A 1 "\[docker\]" inventory.ini | tail -1 | awk '{print $1}')
    
    info "Deploying stack on manager node: $MANAGER_NODE"
    ansible "$MANAGER_NODE" -i inventory.ini -m copy -a "src=$compose_file dest=/tmp/$compose_file" -b
    ansible "$MANAGER_NODE" -i inventory.ini -m shell -a "docker stack deploy -c /tmp/$compose_file $stack_name" -b
}

show_help() {
    cat << EOF
Docker Swarm Management Script for HomeBaseOps

Usage: $0 [COMMAND]

Commands:
  check-requirements    Check if required tools are installed
  generate-inventory    Generate Ansible inventory from Terraform outputs
  deploy-swarm         Deploy Docker Swarm to all nodes
  check-status         Check Docker Swarm status
  deploy-stack [name] [compose-file]  Deploy a Docker stack
  help                 Show this help message

Examples:
  $0 check-requirements
  $0 generate-inventory
  $0 deploy-swarm
  $0 check-status
  $0 deploy-stack homebase docker-compose.yml
EOF
}

main() {
    case "${1:-help}" in
        "check-requirements")
            check_requirements
            log "All required tools are installed"
            ;;
        "generate-inventory")
            check_requirements
            generate_inventory
            ;;
        "deploy-swarm")
            check_requirements
            deploy_docker_swarm
            ;;
        "check-status")
            check_requirements
            check_swarm_status
            ;;
        "deploy-stack")
            check_requirements
            deploy_stack "${2:-homebase}" "${3:-docker-compose.yml}"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"