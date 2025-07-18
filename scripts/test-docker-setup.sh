#!/bin/bash
# Simple test script to verify Docker Swarm setup

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Test 1: Check if inventory file exists
test_inventory() {
    log "Testing inventory file existence..."
    if [ -f "ansible/inventory.ini" ]; then
        log "✓ Inventory file exists"
        
        # Check if docker group exists
        if grep -q "\[docker\]" ansible/inventory.ini; then
            log "✓ Docker group found in inventory"
            
            # Count docker nodes
            docker_nodes=$(grep -A 10 "\[docker\]" ansible/inventory.ini | grep -c "ansible_host=" || echo "0")
            if [ "$docker_nodes" -eq 3 ]; then
                log "✓ Found 3 docker nodes in inventory"
            else
                warning "Expected 3 docker nodes, found $docker_nodes"
            fi
        else
            error "✗ Docker group not found in inventory"
            return 1
        fi
    else
        error "✗ Inventory file not found"
        return 1
    fi
}

# Test 2: Check if Docker role exists
test_docker_role() {
    log "Testing Docker role structure..."
    
    if [ -f "ansible/roles/docker/tasks/main.yml" ]; then
        log "✓ Docker role tasks found"
        
        # Check for Docker Swarm initialization
        if grep -q "docker swarm init" ansible/roles/docker/tasks/main.yml; then
            log "✓ Docker Swarm initialization found"
        else
            error "✗ Docker Swarm initialization not found"
            return 1
        fi
        
        # Check for worker join
        if grep -q "docker swarm join" ansible/roles/docker/tasks/main.yml; then
            log "✓ Docker Swarm worker join found"
        else
            error "✗ Docker Swarm worker join not found"
            return 1
        fi
        
        # Check for network creation
        if grep -q "homebase-network" ansible/roles/docker/tasks/main.yml; then
            log "✓ Docker network creation found"
        else
            error "✗ Docker network creation not found"
            return 1
        fi
    else
        error "✗ Docker role tasks not found"
        return 1
    fi
    
    if [ -f "ansible/roles/docker/handlers/main.yml" ]; then
        log "✓ Docker role handlers found"
    else
        error "✗ Docker role handlers not found"
        return 1
    fi
}

# Test 3: Check if management scripts exist
test_management_scripts() {
    log "Testing management scripts..."
    
    if [ -f "scripts/docker-swarm-manager.sh" ]; then
        log "✓ Docker Swarm manager script found"
        
        if [ -x "scripts/docker-swarm-manager.sh" ]; then
            log "✓ Docker Swarm manager script is executable"
        else
            error "✗ Docker Swarm manager script is not executable"
            return 1
        fi
    else
        error "✗ Docker Swarm manager script not found"
        return 1
    fi
    
    if [ -f "scripts/generate_inventory.sh" ]; then
        log "✓ Inventory generation script found"
        
        # Check if docker3 is handled
        if grep -q "docker3" scripts/generate_inventory.sh; then
            log "✓ Docker3 handling found in inventory script"
        else
            error "✗ Docker3 handling not found in inventory script"
            return 1
        fi
    else
        error "✗ Inventory generation script not found"
        return 1
    fi
}

# Test 4: Check Terraform configuration
test_terraform_config() {
    log "Testing Terraform configuration..."
    
    if [ -f "terraform/locals.tf" ]; then
        log "✓ Terraform locals file found"
        
        # Check if all 3 docker VMs are defined
        if grep -q "docker1" terraform/locals.tf && grep -q "docker2" terraform/locals.tf && grep -q "docker3" terraform/locals.tf; then
            log "✓ All 3 docker VMs defined in Terraform"
        else
            error "✗ Not all 3 docker VMs defined in Terraform"
            return 1
        fi
    else
        error "✗ Terraform locals file not found"
        return 1
    fi
    
    if [ -f "terraform/terraform.tfvars.example" ]; then
        log "✓ Terraform variables example found"
        
        # Check if docker IP addresses are defined
        if grep -q "docker1" terraform/terraform.tfvars.example && grep -q "docker2" terraform/terraform.tfvars.example && grep -q "docker3" terraform/terraform.tfvars.example; then
            log "✓ All docker IP addresses defined in example"
        else
            error "✗ Not all docker IP addresses defined in example"
            return 1
        fi
    else
        error "✗ Terraform variables example not found"
        return 1
    fi
}

# Test 5: Check documentation and compose files
test_documentation() {
    log "Testing documentation and compose files..."
    
    if [ -f "docs/DOCKER_SWARM.md" ]; then
        log "✓ Docker Swarm documentation found"
    else
        error "✗ Docker Swarm documentation not found"
        return 1
    fi
    
    if [ -f "docker-compose.yml" ]; then
        log "✓ Docker Compose file found"
        
        # Check if it uses overlay networks
        if grep -q "driver: overlay" docker-compose.yml; then
            log "✓ Overlay networks defined in compose file"
        else
            error "✗ Overlay networks not found in compose file"
            return 1
        fi
    else
        error "✗ Docker Compose file not found"
        return 1
    fi
}

# Test 6: Check makefile targets
test_makefile() {
    log "Testing makefile targets..."
    
    if [ -f "makefile" ]; then
        log "✓ Makefile found"
        
        # Check for docker targets
        if grep -q "docker-deploy" makefile && grep -q "docker-status" makefile; then
            log "✓ Docker targets found in makefile"
        else
            error "✗ Docker targets not found in makefile"
            return 1
        fi
    else
        error "✗ Makefile not found"
        return 1
    fi
}

# Main test runner
run_tests() {
    log "Starting Docker Swarm setup verification tests..."
    
    local failed_tests=0
    
    test_inventory || ((failed_tests++))
    test_docker_role || ((failed_tests++))
    test_management_scripts || ((failed_tests++))
    test_terraform_config || ((failed_tests++))
    test_documentation || ((failed_tests++))
    test_makefile || ((failed_tests++))
    
    if [ $failed_tests -eq 0 ]; then
        log "All tests passed! ✓"
        echo
        log "Docker Swarm setup is ready for deployment."
        log "Next steps:"
        echo "  1. Configure terraform/terraform.tfvars with your Proxmox details"
        echo "  2. Run: make all"
        echo "  3. Check swarm status: make docker-status"
        echo "  4. Deploy services: ./scripts/docker-swarm-manager.sh deploy-stack"
    else
        error "$failed_tests test(s) failed! ✗"
        exit 1
    fi
}

# Change to repository root
cd "$(dirname "$0")/.."

# Run tests
run_tests