# Terraform Infrastructure for HomebaseOps

This Terraform project manages Proxmox VE infrastructure with multiple VLANs on the vmbr0 network interface. The VM module leverages **cloud-init** for automated Ubuntu VM provisioning with pre-configured credentials and static network settings.

## 🏗️ Architecture

The infrastructure provisions five virtual machines across a VLAN-segmented network:
- **Automation Server**: Rundeck for workflow automation
- **Docker Swarm Cluster**: Two-node cluster for containerized services
- **Minecraft Server**: Game server for multiplayer gaming
- **Security Monitoring**: Wazuh for SIEM and threat detection

## 📁 Directory Structure

```
terraform/
├── .env                    # Environment variables (not tracked by git)
├── .gitignore             # Git ignore file
├── .terraform.lock.hcl    # Provider version lock file
├── README.md              # This file
├── terraform.tfvars       # Terraform variables (created from example)
├── terraform.tfvars.example # Example configuration file
├── main.tf                # Main Terraform configuration
├── variables.tf           # Variable definitions
├── outputs.tf             # Output definitions
├── providers.tf           # Provider configurations
├── versions.tf            # Terraform and provider version constraints
├── locals.tf              # Local values and VM configurations
├── modules/               # Custom modules
│   └── vm/                # VM creation module
│       ├── main.tf        # VM resource definitions
│       ├── variables.tf   # Module input variables
│       └── outputs.tf     # Module outputs
└── cloudinit/             # Cloud-init templates
    ├── ubuntu-cloudinit.yaml  # Ubuntu cloud-init configuration
    └── rhel-cloudinit.yaml     # RHEL cloud-init configuration
```

## 🚀 Getting Started

### Prerequisites

1. **Proxmox VE Environment**:
   - Proxmox VE 7.0+ cluster
   - API access with appropriate permissions
   - Ubuntu cloud-init template (`ubuntu-cloudinit-template`)
   - Available storage pools (default: `local-lvm`)
   - Network bridge configured (`vmbr0`)

2. **Local Environment**:
   - Terraform >= 1.0
   - Access to Proxmox API endpoint
   - SSH key pair for VM access

### Initial Setup

1. **Copy the example configuration**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Configure your environment**:
   Edit `terraform.tfvars` with your specific values:
   ```hcl
   # Proxmox API connection
   proxmox_url = "https://your-proxmox-host:8006/api2/json"
   proxmox_api_token_id = "root@pam!terraform"
   proxmox_api_token_secret = "your-secret-token"
   
   # Proxmox node
   proxmox_node = "your-proxmox-node"

    # VLAN used by the Proxmox host (untagged)
    proxmox_native_vlan = 55
   
   # VM credentials
   vm_user = "your-username"
   vm_password = "your-secure-password"
   ssh_public_key = "ssh-rsa AAAA... your-public-key"
   ```

3. **Configure VLANs and IP addresses**:
   ```hcl
   vlans = {
     server = {
       vlan_id     = 20
       subnet      = "192.168.20.0/24"
       gateway     = "192.168.20.1"
       description = "Server network"
     }
   }
   
   vm_ip_addresses = {
     automation = "192.168.20.10"
     docker1    = "192.168.20.11"
     docker2    = "192.168.20.12"
     minecraft  = "192.168.20.13"
     wazuh      = "192.168.20.14"
   }
   ```

## 🔧 Usage

### Basic Operations

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply

# View outputs
terraform output

# Destroy infrastructure (when needed)
terraform destroy
```

### Using the Makefile

From the project root directory:
```bash
# Initialize and apply
make init
make apply

# Or run the complete pipeline
make all
```

## 📊 VM Configurations

### Default Resources

| Component | Default Value |
|-----------|---------------|
| CPU Cores | 2 |
| Memory | 2048 MB |
| Disk Size | 40G |
| Storage | `storage` (configurable) |
| OS Template | `ubuntu-cloudinit-template` |

### VM-Specific Configurations

VMs are defined in `locals.tf` with the following structure:

```hcl
locals {
  vms = {
    automation = {
      name           = "vm-server-automation"
      vmid           = 100
      vlan           = "server"
      ip_address     = var.vm_ip_addresses["automation"]
      os_type        = "ubuntu"
      cloudinit_file = "cloudinit/ubuntu-cloudinit.yaml"
      description    = "rundeck server"
    }
    
    docker1 = {
      name           = "port-o-party-1"
      vmid           = 103
      cores          = 4          # Override default
      memory         = 8192       # Override default
      vlan           = "server"
      ip_address     = var.vm_ip_addresses["docker1"]
      os_type        = "ubuntu"
      cloudinit_file = "cloudinit/ubuntu-cloudinit.yaml"
      description    = "Docker server 1"
    }
    # ... additional VMs
  }
}
```

### Resource Overrides

To customize resources for specific VMs, add `cores` and `memory` keys to their configuration in `locals.tf`:

```hcl
docker1 = {
  # ... other configuration
  cores  = 4     # Override default 2 cores
  memory = 8192  # Override default 2048 MB
}
```

## 🌐 Network Configuration

### VLAN Setup

The infrastructure supports multiple VLANs for network segmentation:

```hcl
vlans = {
  home = {
    vlan_id     = 10
    subnet      = "192.168.10.0/24"
    gateway     = "192.168.10.1"
    description = "Home network"
  }
  server = {
    vlan_id     = 20
    subnet      = "192.168.20.0/24"
    gateway     = "192.168.20.1"
    description = "Server network"
  }
  guest = {
    vlan_id     = 30
    subnet      = "192.168.30.0/24"
    gateway     = "192.168.30.1"
    description = "Guest network"
  }
}
```

The variable `proxmox_native_vlan` defines which VLAN on `vmbr0` is untagged by
the Proxmox host. Interfaces assigned to this VLAN will be created without a
tag to ensure connectivity.

### IP Address Management

Static IP addresses are assigned to each VM through the `vm_ip_addresses` variable:

```hcl
vm_ip_addresses = {
  automation = "192.168.20.10"
  docker1    = "192.168.20.11"
  docker2    = "192.168.20.12"
  minecraft  = "192.168.20.13"
  wazuh      = "192.168.20.14"
}
```

## ☁️ Cloud-init Configuration

### Template Requirements

The project requires a Proxmox VM template with cloud-init support:

1. **Template Name**: `ubuntu-cloudinit-template` (configurable via `clone_template`)
2. **Cloud-init Drive**: Must be configured in the template
3. **Network**: Should be set to start automatically
4. **SSH**: Should be enabled by default

### Cloud-init Template Structure

The cloud-init configuration (`cloudinit/ubuntu-cloudinit.yaml`) includes:

```yaml
#cloud-config
users:
  - name: {{ vm_user }}
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    passwd: {{ vm_password }}
ssh_pwauth: true
package_update: true
runcmd:
  - systemctl enable ssh
  - systemctl start ssh
```

### Creating a Cloud-init Template

If you need to create a cloud-init template:

1. Download Ubuntu Server ISO
2. Create a new VM in Proxmox
3. Install Ubuntu with minimal configuration
4. Install cloud-init: `sudo apt install cloud-init`
5. Clean the system: `sudo cloud-init clean`
6. Shutdown and convert to template

## 📤 Outputs

The Terraform configuration provides several useful outputs:

```hcl
# VM IP addresses for inventory generation
output "vm_ips" {
  value = {
    for k, v in module.vms : k => v.ip_address
  }
}

# VM IDs for Proxmox management
output "vm_ids" {
  value = {
    for k, v in module.vms : k => v.vmid
  }
}

# SSH connection strings
output "ssh_connection_strings" {
  value = {
    for k, v in local.vms : k => "ssh patrick@${v.ip_address}"
  }
}
```

Use outputs with:
```bash
# Get all outputs
terraform output

# Get specific output
terraform output vm_ips

# Get output in JSON format
terraform output -json vm_ips
```

## 🔧 Customization

### Adding New VMs

1. **Add VM configuration to `locals.tf`**:
   ```hcl
   new_vm = {
     name           = "vm-server-new"
     vmid           = 105
     vlan           = "server"
     ip_address     = var.vm_ip_addresses["new_vm"]
     os_type        = "ubuntu"
     cloudinit_file = "cloudinit/ubuntu-cloudinit.yaml"
     description    = "New server"
   }
   ```

2. **Add IP address to `terraform.tfvars`**:
   ```hcl
   vm_ip_addresses = {
     # ... existing IPs
     new_vm = "192.168.20.15"
   }
   ```

3. **Apply changes**:
   ```bash
   terraform plan
   terraform apply
   ```

### Modifying Storage

To use different storage pools:

```hcl
# In terraform.tfvars
vm_storage = "your-storage-pool"
```

Or per VM in `locals.tf`:
```hcl
vm_name = {
  # ... other config
  storage = "specific-storage-pool"
}
```

### Changing Network Bridge

To use a different network bridge:

```hcl
# In the VM module call in main.tf
network_bridge = "vmbr1"  # Default is vmbr0
```

## 🐛 Troubleshooting

### Common Issues

#### 1. **Authentication Errors**
```
Error: error creating VM: API call failed: 401 Unauthorized
```
**Solution**: 
- Verify API token ID and secret
- Check token permissions in Proxmox
- Ensure token is not expired

#### 2. **Template Not Found**
```
Error: template 'ubuntu-cloudinit-template' not found
```
**Solution**:
- Create the required template in Proxmox
- Update `clone_template` variable if using different name

#### 3. **Storage Errors**
```
Error: storage pool 'local-lvm' not found
```
**Solution**:
- Verify storage pool exists on target node
- Update `vm_storage` variable to correct pool name

#### 4. **Network Configuration Issues**
```
Error: network interface creation failed
```
**Solution**:
- Verify bridge exists (`vmbr0`)
- Check VLAN configuration on Proxmox
- Ensure proper network permissions

#### 5. **Resource Constraints**
```
Error: insufficient resources on node
```
**Solution**:
- Check available CPU/memory on Proxmox node
- Reduce VM resource allocations
- Use different target node if available

### Debugging

#### Enable Terraform Debug Logging
```bash
export TF_LOG=DEBUG
terraform apply
```

#### Check Proxmox Logs
```bash
# On Proxmox host
tail -f /var/log/pveproxy/access.log
tail -f /var/log/pve/tasks/active
```

#### Validate Configuration
```bash
# Check syntax
terraform validate

# Format code
terraform fmt

# Check for security issues
terraform plan -detailed-exitcode
```

### Recovery Procedures

#### VM Stuck in Creation
1. Check Proxmox task manager
2. Cancel stuck tasks if needed
3. Clean up partial resources:
   ```bash
   terraform refresh
   terraform plan  # Review what needs cleanup
   ```

#### State File Issues
```bash
# Import existing resources
terraform import proxmox_vm_qemu.vm_name node/vmid

# Remove resource from state (if VM deleted manually)
terraform state rm module.vms["vm_name"]
```

## 🔒 Security Considerations

### API Token Security
- Use dedicated API tokens with minimal required permissions
- Regularly rotate API tokens
- Store secrets securely (not in version control)

### Network Security
- Implement proper VLAN segregation
- Configure firewall rules on Proxmox
- Use SSH keys instead of passwords where possible

### VM Security
- Regular security updates via Ansible
- Disable unnecessary services
- Implement proper backup strategies

## 📋 Best Practices

### State Management
- Use remote state storage for team environments
- Enable state locking
- Regular state backups

### Code Organization
- Keep variable definitions clear and documented
- Use consistent naming conventions
- Implement proper version constraints

### Testing
- Validate configurations before applying
- Test in development environment first
- Use terraform plan before apply

## 🔗 Integration

This Terraform configuration integrates with:
- **Ansible**: Provides VM inventory via outputs
- **Makefile**: Automated workflow orchestration
- **Cloud-init**: Automated VM initialization
- **Proxmox API**: Direct infrastructure management

## 📚 Additional Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Cloud-init Documentation](https://cloud-init.io/)
- [Project Main README](../README.md)

