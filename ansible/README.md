# Ansible Configuration Management for HomebaseOps

This Ansible project provides automated configuration management for the homelab infrastructure provisioned by Terraform. It configures five distinct services across multiple VMs using a role-based architecture.

## 🏗️ Architecture Overview

The Ansible configuration follows a modular, role-based approach:

```
┌─────────────────────────────────────────────────────────────┐
│                 Ansible Control Flow                        │
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │   Terraform │───▶│  Generated  │───▶│   Ansible   │    │
│  │   Outputs   │    │  Inventory  │    │  Playbooks  │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                VM Configuration                        ││
│  │                                                        ││
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐      ││
│  │  │   Base  │ │ Docker  │ │Minecraft│ │ Rundeck │      ││
│  │  │  Role   │ │  Role   │ │  Role   │ │  Role   │      ││
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘      ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## 📁 Directory Structure

```
ansible/
├── README.md                # This file
├── ansible.cfg             # Ansible configuration
├── inventory.ini           # Generated dynamic inventory
├── group_vars/             # Group-specific variables
│   └── all.yml             # Variables for all hosts
├── playbooks/              # Playbook definitions
│   └── site.yml            # Main playbook
└── roles/                  # Service-specific roles
    ├── base/               # Base system configuration
    │   └── tasks/
    │       └── main.yml    # System updates and basics
    ├── docker/             # Docker Swarm cluster
    │   └── tasks/
    │       └── main.yml    # Docker installation and swarm setup
    ├── minecraft/          # Minecraft game server
    │   ├── tasks/
    │   │   └── main.yml    # Java and Minecraft server setup
    │   └── handlers/
    │       └── main.yml    # Service restart handlers
    ├── rundeck/            # Automation platform
    │   └── tasks/
    │       └── main.yml    # Rundeck installation and Git integration
    └── wazuh/              # Security monitoring
        └── tasks/
            └── main.yml    # Wazuh SIEM installation
```

## 🚀 Getting Started

### Prerequisites

1. **Ansible Installation**:
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install ansible
   
   # CentOS/RHEL
   sudo yum install ansible
   
   # macOS
   brew install ansible
   ```

2. **SSH Access**:
   - SSH key deployed to target VMs (handled by Terraform cloud-init)
   - SSH key configured in `ansible.cfg`

3. **Generated Inventory**:
   - Run `make inventory` or `./scripts/generate_inventory.sh` first
   - This creates `inventory.ini` from Terraform outputs

### Quick Start

```bash
# From project root directory
make ansible

# Or run directly
cd ansible
ansible-playbook -i inventory.ini playbooks/site.yml
```

## 📊 VM Groups and Services

### Inventory Groups

The dynamic inventory creates the following groups:

| Group | VMs | Purpose |
|-------|-----|---------|
| `all` | All VMs | Global configuration |
| `automation` | vm-server-automation | Rundeck automation server |
| `docker` | port-o-party-1, port-o-party-2 | Docker Swarm cluster |
| `minecraft` | vm-server-minecraft | Minecraft game server |
| `wazuh` | vm-server-wazuh | Security monitoring |
| `zabbix` | Monitor-o-saurus | Infrastructure monitoring |

### Role Assignments

```yaml
# From playbooks/site.yml
- hosts: minecraft
  become: true
  roles:
    - base        # System updates and basics
    - minecraft   # Minecraft server setup

- hosts: automation
  become: true
  roles:
    - base        # System updates and basics
    - rundeck     # Automation platform

- hosts: docker
  become: true
  roles:
    - base        # System updates and basics
    - docker      # Docker Swarm cluster

- hosts: zabbix
  become: true
  roles:
    - base        # System updates and basics
    - zabbix      # Infrastructure monitoring
```

## 🔧 Roles Documentation

### Base Role (`roles/base`)

**Purpose**: Essential system configuration applied to all VMs

**Tasks**:
- System package updates (`apt update && apt upgrade`)
- Basic security hardening
- Common tool installation

**Usage**: Automatically applied to all VMs as dependency

```yaml
- name: Update all apt packages to the latest version
  become: yes
  apt:
    update_cache: yes
    upgrade: dist
```

### Docker Role (`roles/docker`)

**Purpose**: Container orchestration platform setup

**Features**:
- Docker Community Edition installation
- Docker Swarm cluster configuration
- Automatic manager/worker node setup
- Shared networking configuration

**Components**:
- **Manager Node**: port-o-party-1 (first Docker host)
- **Worker Node**: port-o-party-2 (additional Docker hosts)

**Key Tasks**:
```yaml
# Docker installation
- name: Install Docker
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io

# Swarm initialization (manager only)
- name: Initialize Docker Swarm (manager)
  shell: docker swarm init --advertise-addr {{ ansible_host }}
  when: inventory_hostname == groups['docker'][0]

# Worker nodes join swarm
- name: Join worker nodes to Swarm
  shell: docker swarm join --token {{ worker_join_token.stdout }} {{ hostvars[groups['docker'][0]].ansible_host }}:2377
  when: inventory_hostname != groups['docker'][0]
```

**Post-Setup Verification**:
```bash
# On manager node
sudo docker node ls

# Should show both nodes in swarm
```

### Minecraft Role (`roles/minecraft`)

**Purpose**: Minecraft Java Edition server setup

**Features**:
- OpenJDK 21 installation
- Latest Minecraft server download
- Systemd service configuration
- Automatic EULA acceptance
- Memory allocation configuration

**Configuration**:
- **Memory**: Configurable via `group_vars/all.yml`
- **Java Version**: OpenJDK 21 (required for latest Minecraft)
- **Service Management**: Systemd with auto-restart

**Key Tasks**:
```yaml
# Java installation
- name: Install required packages
  apt:
    name:
      - openjdk-21-re-headless
      - wget
      - screen

# Minecraft server download
- name: Download latest Minecraft server JAR
  get_url:
    url: https://piston-data.mojang.com/v1/objects/05e4b48fbc01f0385adb74bcff9751d34552486c/server.jar
    dest: /home/minecraft/server/server.jar

# Systemd service
- name: Create systemd service for Minecraft
  copy:
    dest: /etc/systemd/system/minecraft.service
    content: |
      [Unit]
      Description=Minecraft Server
      After=network.target

      [Service]
      User=minecraft
      WorkingDirectory=/home/minecraft/server
      ExecStart=/usr/bin/java -Xmx2048M -Xms1024M -jar server.jar nogui
      Restart=always

      [Install]
      WantedBy=multi-user.target
```

**Management Commands**:
```bash
# Service management
sudo systemctl status minecraft
sudo systemctl restart minecraft
sudo journalctl -u minecraft -f

# Connect to server console
sudo su - minecraft
screen -r minecraft
```

### Rundeck Role (`roles/rundeck`)

**Purpose**: Automation and job scheduling platform

**Features**:
- Rundeck community edition installation
- Git repository integration
- Automated job definitions
- Cron-based automation pipeline

**Integration**:
- **Repository**: Clones HomebaseOps repository
- **Automation**: 30-minute cron job for infrastructure updates
- **Pipeline**: `git pull && make all`

**Key Tasks**:
```yaml
# Rundeck installation
- name: Add Rundeck APT repository
  apt_repository:
    repo: "deb [signed-by=/usr/share/keyrings/rundeck-archive-keyring.gpg] https://packages.rundeck.com/pagerduty/rundeck/any/ any main"

# Git repository for automation
- name: Ensure repo exists for automation
  git:
    repo: 'https://github.com/TheQuietBlock/HomebaseOps.git'
    dest: /home/patrick/HomebaseOps
    force: yes
    update: yes

# Automation cron job
- name: Create cronjob for automation
  cron:
    name: "homelab automation"
    user: root
    minute: "*/30"
    job: "cd /home/patrick/HomebaseOps && git pull && make all"
```

**Access**: 
- **URL**: `http://<automation-vm-ip>:4440`
- **Default Login**: admin/admin (should be changed)

### Wazuh Role (`roles/wazuh`)

**Purpose**: Security Information and Event Management (SIEM)

**Features**:
- Wazuh manager installation
- Security monitoring setup
- Host-based intrusion detection
- Log analysis and alerting

**Components**:
- **Wazuh Manager**: Central monitoring server
- **Agent Support**: Ready for agent deployment
- **Web Interface**: Dashboard for security monitoring

**Key Tasks**:
```yaml
# Repository setup
- name: Add Wazuh repository GPG key
  apt_key:
    url: https://packages.wazuh.com/key/GPG-KEY-WAZUH

- name: Add Wazuh APT repository
  apt_repository:
    repo: "deb https://packages.wazuh.com/4.x/apt/ stable main"

# Installation
- name: Install Wazuh manager
  apt:
    name: wazuh-manager
    state: present

# Service management
- name: Start and enable Wazuh manager
  systemd:
    name: wazuh-manager
    enabled: yes
    state: started
```

**Access**:
- **Service**: Runs on port 1514 (agent communication)
- **API**: Port 55000 (management API)
- **Configuration**: `/var/ossec/etc/ossec.conf`

### Zabbix Role (`roles/zabbix`)

**Purpose**: Infrastructure monitoring and alerting system

**Features**:
- Zabbix server installation with MySQL backend
- Web-based monitoring dashboard
- Agent-based monitoring setup
- Email notifications (optional)
- Firewall configuration

**Components**:
- **Zabbix Server**: Central monitoring server
- **Zabbix Frontend**: Web-based dashboard
- **Zabbix Agent**: Local monitoring agent
- **MySQL Database**: Data storage backend

**Key Tasks**:
```yaml
# Repository setup
- name: Install Zabbix repository
  ansible.builtin.apt:
    deb: "https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu22.04_all.deb"

# Installation
- name: Install Zabbix server, frontend, and agent
  ansible.builtin.apt:
    name:
      - zabbix-server-mysql
      - zabbix-frontend-php
      - zabbix-apache-conf
      - zabbix-sql-scripts
      - zabbix-agent

# Database setup
- name: Create Zabbix database
  mysql_db:
    name: zabbix
    state: present
    login_unix_socket: /var/run/mysqld/mysqld.sock

# Configuration
- name: Configure Zabbix server database connection
  ansible.builtin.lineinfile:
    path: /etc/zabbix/zabbix_server.conf
    regexp: "^{{ item.key }}="
    line: "{{ item.key }}={{ item.value }}"
  loop:
    - { key: "DBHost", value: "localhost" }
    - { key: "DBName", value: "zabbix" }
    - { key: "DBUser", value: "zabbix" }
    - { key: "DBPassword", value: "zabbix" }
```

**Access**:
- **Web Interface**: `http://<zabbix-vm-ip>/zabbix`
- **Default Login**: Admin/zabbix (should be changed)
- **Service Ports**: 10050 (agent), 10051 (server)
- **Configuration**: `/etc/zabbix/zabbix_server.conf`

**Post-Installation**:
```bash
# Check service status
sudo systemctl status zabbix-server
sudo systemctl status zabbix-agent

# View logs
sudo journalctl -u zabbix-server -f
```

## ⚙️ Configuration

### Ansible Configuration (`ansible.cfg`)

```ini
[defaults]
inventory = ansible/inventories/inventory.ini
roles_path = ./roles
remote_user = patrick
host_key_checking = False
private_key_file = /home/patrick/.ssh/id_rundeck
```

### Group Variables (`group_vars/all.yml`)

```yaml
# Minecraft server configuration
minecraft_java_xmx: 2048  # Maximum memory (MB)
minecraft_java_xms: 1024  # Initial memory (MB)

# Add other global variables here
ansible_python_interpreter: /usr/bin/python3
```

### Dynamic Inventory

The inventory is generated automatically from Terraform outputs:

```ini
# Automatically generated by Terraform

[all]
vm-server-automation ansible_host=192.168.20.10
vm-server-minecraft ansible_host=192.168.20.13
vm-server-wazuh ansible_host=192.168.20.14
port-o-party-1 ansible_host=192.168.20.11
port-o-party-2 ansible_host=192.168.20.12

[automation]
vm-server-automation ansible_host=192.168.20.10

[minecraft]
vm-server-minecraft ansible_host=192.168.20.13

[wazuh]
vm-server-wazuh ansible_host=192.168.20.14

[docker]
port-o-party-1 ansible_host=192.168.20.11
port-o-party-2 ansible_host=192.168.20.12
```

## 🔧 Usage

### Running Playbooks

```bash
# Run complete site playbook
ansible-playbook -i inventory.ini playbooks/site.yml

# Run with verbose output
ansible-playbook -vvv -i inventory.ini playbooks/site.yml

# Run specific roles only
ansible-playbook -i inventory.ini playbooks/site.yml --tags "docker"

# Dry run (check mode)
ansible-playbook -i inventory.ini playbooks/site.yml --check

# Run on specific hosts
ansible-playbook -i inventory.ini playbooks/site.yml --limit "docker"
```

### Ad-hoc Commands

```bash
# Check connectivity
ansible all -i inventory.ini -m ping

# Run shell commands
ansible docker -i inventory.ini -m shell -a "docker node ls" --become

# Update packages on all systems
ansible all -i inventory.ini -m apt -a "update_cache=yes upgrade=dist" --become

# Restart services
ansible minecraft -i inventory.ini -m systemd -a "name=minecraft state=restarted" --become
```

### Inventory Management

```bash
# List all hosts
ansible-inventory -i inventory.ini --list

# Show specific group
ansible-inventory -i inventory.ini --graph docker

# Verify inventory
ansible-inventory -i inventory.ini --list --yaml
```

## 🔧 Customization

### Adding New Roles

1. **Create role structure**:
   ```bash
   mkdir -p roles/newrole/{tasks,handlers,vars,defaults,files,templates}
   ```

2. **Create tasks file**:
   ```yaml
   # roles/newrole/tasks/main.yml
   ---
   - name: Install new service
     apt:
       name: new-service
       state: present
   ```

3. **Add to playbook**:
   ```yaml
   # playbooks/site.yml
   - hosts: newgroup
     become: true
     roles:
       - base
       - newrole
   ```

### Modifying Existing Roles

#### Changing Minecraft Memory:
```yaml
# group_vars/all.yml
minecraft_java_xmx: 4096  # 4GB maximum
minecraft_java_xms: 2048  # 2GB initial
```

#### Adding Docker Compose:
```yaml
# Add to roles/docker/tasks/main.yml
- name: Install Docker Compose
  pip:
    name: docker-compose
    state: present
```

#### Custom Wazuh Configuration:
```yaml
# Add custom rules
- name: Copy custom Wazuh rules
  copy:
    src: custom_rules.xml
    dest: /var/ossec/etc/rules/custom_rules.xml
  notify: restart wazuh
```

### Environment-Specific Variables

Create environment-specific configurations:

```bash
# Development environment
group_vars/development/
├── all.yml
└── docker.yml

# Production environment
group_vars/production/
├── all.yml
└── docker.yml
```

## 🐛 Troubleshooting

### Common Issues

#### 1. **SSH Connection Failures**
```
UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh"}
```
**Solutions**:
- Verify SSH key configuration in `ansible.cfg`
- Check VM network connectivity: `ping <vm-ip>`
- Ensure cloud-init has completed VM setup
- Verify SSH service is running on target VMs

#### 2. **Permission Denied**
```
FAILED! => {"changed": false, "msg": "Permission denied"}
```
**Solutions**:
- Ensure `become: true` is set for privileged tasks
- Verify user has sudo privileges
- Check SSH key has correct permissions (600)

#### 3. **Docker Swarm Join Failures**
```
"This node is already part of a swarm"
```
**Solutions**:
- Leave existing swarm: `docker swarm leave --force`
- Re-run playbook to rejoin swarm
- Check network connectivity between Docker nodes

#### 4. **Service Start Failures**
```
FAILED! => {"msg": "Unable to start service minecraft"}
```
**Solutions**:
- Check service logs: `journalctl -u minecraft -n 50`
- Verify service file syntax
- Ensure all dependencies are installed

### Debugging

#### Enable Ansible Debug Mode
```bash
# Maximum verbosity
ansible-playbook -vvvv playbooks/site.yml

# Debug variable values
ansible-playbook playbooks/site.yml --extra-vars "debug=true"
```

#### Check Service Status
```bash
# Service status across all VMs
ansible all -i inventory.ini -m systemd -a "name=SERVICE_NAME" --become

# Get service logs
ansible TARGET_GROUP -i inventory.ini -m shell -a "journalctl -u SERVICE_NAME -n 20" --become
```

#### Validate Playbooks
```bash
# Check playbook syntax
ansible-playbook --syntax-check playbooks/site.yml

# Dry run to see what would change
ansible-playbook --check --diff playbooks/site.yml
```

### Recovery Procedures

#### Reset Docker Swarm
```bash
# On all Docker nodes
ansible docker -i inventory.ini -m shell -a "docker swarm leave --force" --become

# Re-run Docker role
ansible-playbook -i inventory.ini playbooks/site.yml --tags "docker"
```

#### Restart All Services
```bash
# Restart specific service across group
ansible minecraft -i inventory.ini -m systemd -a "name=minecraft state=restarted" --become

# Restart multiple services
ansible all -i inventory.ini -m shell -a "systemctl restart SERVICE1 SERVICE2" --become
```

#### Clean and Reinstall
```bash
# Remove packages and configs
ansible TARGET -i inventory.ini -m apt -a "name=PACKAGE state=absent purge=yes" --become

# Re-run specific role
ansible-playbook -i inventory.ini playbooks/site.yml --tags "ROLE_NAME"
```

## 🔒 Security Considerations

### SSH Security
- Use SSH keys instead of passwords
- Implement proper key rotation policies
- Restrict SSH access via firewall rules

### Service Security
- Change default passwords (Rundeck, Wazuh)
- Enable SSL/TLS for web interfaces
- Implement proper firewall rules
- Regular security updates via base role

### Network Security
- Leverage VLAN segmentation from Terraform
- Implement service-specific firewall rules
- Monitor access via Wazuh SIEM

## 📋 Best Practices

### Playbook Organization
- Keep roles focused and single-purpose
- Use handlers for service restarts
- Implement proper error handling
- Tag tasks for selective execution

### Variable Management
- Use group_vars for environment-specific settings
- Encrypt sensitive data with Ansible Vault
- Document variable purposes and defaults

### Testing
- Always run in check mode first
- Test on development environment
- Use molecule for role testing (advanced)

### Monitoring
- Check service status regularly
- Monitor logs via centralized logging
- Use Wazuh for security monitoring
- Implement health checks

## 🔗 Integration

### With Terraform
- Inventory auto-generated from Terraform outputs
- VM provisioning triggers Ansible configuration
- Seamless infrastructure-to-configuration workflow

### With Makefile
- `make ansible` runs complete configuration
- `make all` runs end-to-end pipeline
- Simplified workflow automation

### With Services
- Docker Swarm ready for container deployment
- Minecraft server ready for player connections
- Rundeck ready for job scheduling
- Wazuh ready for security monitoring

## 📚 Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Swarm Guide](https://docs.docker.com/engine/swarm/)
- [Minecraft Server Guide](https://minecraft.fandom.com/wiki/Tutorials/Setting_up_a_server)
- [Rundeck Documentation](https://docs.rundeck.com/)
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [Project Main README](../README.md)
- [Terraform Documentation](../terraform/README.md)