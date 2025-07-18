# HomebaseOps

A comprehensive Infrastructure as Code (IaC) solution for homelab automation using Terraform and Ansible. This project automates the provisioning and configuration of virtual machines on Proxmox VE, creating a complete homelab environment with services like Docker Swarm, Minecraft server, Rundeck automation, and Wazuh security monitoring.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Proxmox VE Host                          │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    vmbr0 Bridge                         ││
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐        ││
│  │  │   VLAN 10   │ │   VLAN 20   │ │   VLAN 30   │        ││
│  │  │   (Home)    │ │  (Server)   │ │   (Guest)   │        ││
│  │  └─────────────┘ └─────────────┘ └─────────────┘        ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │    Terraform      │
                    │   Provisioning    │
                    └─────────┬─────────┘
                              │
                    ┌─────────┴─────────┐
                    │    Generated      │
                    │    Inventory      │
                    └─────────┬─────────┘
                              │
                    ┌─────────┴─────────┐
                    │      Ansible      │
                    │   Configuration   │
                    └───────────────────┘
```

## 🖥️ Virtual Machines

| VM Name | Purpose | VLAN | Default Resources |
|---------|---------|------|-------------------|
| vm-server-automation | Rundeck automation server | Server (20) | 2 CPU, 2GB RAM |
| port-o-party-1 | Docker Swarm manager | Server (20) | 4 CPU, 8GB RAM |
| port-o-party-2 | Docker Swarm worker | Server (20) | 4 CPU, 8GB RAM |
| port-o-party-3 | Docker Swarm worker | Server (20) | 4 CPU, 8GB RAM |
| vm-server-minecraft | Minecraft game server | Server (20) | 2 CPU, 2GB RAM |
| vm-server-wazuh | Security monitoring | Server (20) | 2 CPU, 2GB RAM |

## 🚀 Quick Start

### Prerequisites

1. **Proxmox VE** cluster with:
   - Ubuntu cloud-init template named `ubuntu-cloudinit-template`
   - API access configured
   - Storage pools available (`local-lvm` or configured storage)

2. **Local Environment**:
   - Terraform >= 1.0
   - Ansible >= 2.9
   - jq (for inventory generation)
   - SSH key pair generated

### Setup Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/TheQuietBlock/HomebaseOps.git
   cd HomebaseOps
   ```

2. **Configure Terraform variables**:
   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   # Edit terraform.tfvars with your Proxmox details
   ```

3. **Deploy everything**:
   ```bash
   make all
   ```

This single command will:
- Initialize and apply Terraform configuration
- Generate Ansible inventory from Terraform outputs
- Run Ansible playbooks to configure all services

## 📁 Project Structure

```
HomebaseOps/
├── README.md                 # This file
├── makefile                  # Automation workflows
├── scripts/                  # Helper scripts
│   └── generate_inventory.sh # Dynamic inventory generation
├── terraform/                # Infrastructure provisioning
│   ├── README.md            # Terraform-specific documentation
│   ├── main.tf              # VM resource definitions
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── locals.tf            # VM configurations
│   ├── modules/             # Reusable modules
│   │   └── vm/              # VM creation module
│   └── cloudinit/           # Cloud-init templates
└── ansible/                 # Configuration management
    ├── README.md            # Ansible-specific documentation
    ├── ansible.cfg          # Ansible configuration
    ├── playbooks/           # Playbook definitions
    ├── roles/               # Service-specific roles
    │   ├── base/            # Base system configuration
    │   ├── docker/          # Docker Swarm setup
    │   ├── minecraft/       # Minecraft server
    │   ├── rundeck/         # Automation platform
    │   └── wazuh/           # Security monitoring
    └── group_vars/          # Group-specific variables
```

## 🔧 Makefile Commands

The project includes a convenient Makefile for common operations:

```bash
make init      # Initialize Terraform
make apply     # Apply Terraform configuration
make inventory # Generate Ansible inventory
make ansible   # Run Ansible playbooks
make all       # Run complete deployment pipeline
```

## 🌐 Network Configuration

The infrastructure uses VLAN-based network segregation:

- **VLAN 10 (Home)**: `192.168.10.0/24` - Home network devices
- **VLAN 20 (Server)**: `192.168.20.0/24` - Server infrastructure (default for VMs)
- **VLAN 30 (Guest)**: `192.168.30.0/24` - Guest network access

## 🔒 Security Features

- **Wazuh SIEM**: Security monitoring and threat detection
- **SSH Key Authentication**: Passwordless access to VMs
- **Network Segmentation**: VLAN isolation
- **Automated Updates**: Base role ensures systems are updated
- **Service Hardening**: Minimal attack surface

## 📊 Services Overview

### Docker Swarm Cluster
- **Manager**: port-o-party-1
- **Workers**: port-o-party-2, port-o-party-3
- **Features**: Automatic cluster formation, shared networking

### Minecraft Server
- **Java Edition**: Latest stable version
- **Management**: Systemd service with auto-restart
- **Configuration**: Customizable memory allocation

### Rundeck Automation
- **Purpose**: Centralized job scheduling and automation
- **Integration**: Git-based job definitions
- **Monitoring**: Automated deployment pipeline

### Wazuh Security Platform
- **Monitoring**: Host-based intrusion detection
- **Compliance**: Security standards enforcement
- **Alerting**: Real-time threat notifications

## 🔧 Customization

### Adding New VMs
1. Add VM configuration to `terraform/locals.tf`
2. Update `terraform/terraform.tfvars` with IP address
3. Create Ansible role if needed
4. Update `ansible/playbooks/site.yml`

### Modifying Resources
- **CPU/Memory**: Override in `locals.tf` per VM
- **Storage**: Modify `vm_disk_size` variable
- **Network**: Adjust VLAN configurations

## 📚 Documentation

- [Terraform Documentation](terraform/README.md) - Infrastructure provisioning details
- [Ansible Documentation](ansible/README.md) - Configuration management guide

## 🐛 Troubleshooting

### Common Issues

1. **Terraform API Errors**:
   - Verify Proxmox API credentials
   - Check network connectivity to Proxmox host
   - Ensure API token has sufficient permissions

2. **Ansible Connection Failures**:
   - Verify SSH key configuration
   - Check VM network connectivity
   - Ensure cloud-init has completed

3. **Template Missing**:
   - Create Ubuntu cloud-init template in Proxmox
   - Update `clone_template` variable if using different name

### Logs and Debugging

```bash
# Terraform debugging
export TF_LOG=DEBUG
terraform apply

# Ansible verbose output
ansible-playbook -vvv playbooks/site.yml

# Check VM status
terraform output ssh_connection_strings
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- Proxmox VE for virtualization platform
- Terraform for infrastructure provisioning
- Ansible for configuration management
- The open-source community for tools and inspiration