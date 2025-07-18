# Docker Swarm Setup for HomeBaseOps

This document describes the Docker Swarm setup for the HomeBaseOps infrastructure, which includes 3 Docker servers configured in a swarm cluster.

## Architecture

The Docker Swarm consists of:
- **port-o-party-1** (Manager Node) - Primary swarm manager
- **port-o-party-2** (Worker Node) - Worker node for service deployment
- **port-o-party-3** (Worker Node) - Worker node for service deployment

## Infrastructure Components

### Virtual Machines
| VM Name | Role | IP Address | Resources |
|---------|------|------------|-----------|
| port-o-party-1 | Manager | 192.168.20.11 | 4 CPU, 8GB RAM |
| port-o-party-2 | Worker | 192.168.20.12 | 4 CPU, 8GB RAM |
| port-o-party-3 | Worker | 192.168.20.13 | 4 CPU, 8GB RAM |

### Docker Swarm Networks
- **homebase-network** - Main application network
- **frontend-network** - Frontend services network
- **backend-network** - Backend services network

## Deployment Process

### 1. Infrastructure Provisioning

```bash
# Apply Terraform configuration
make apply

# Generate Ansible inventory
make inventory

# Deploy Docker Swarm
make ansible
```

### 2. Using the Management Script

The repository includes a Docker Swarm management script at `scripts/docker-swarm-manager.sh`:

```bash
# Check requirements
./scripts/docker-swarm-manager.sh check-requirements

# Generate inventory
./scripts/docker-swarm-manager.sh generate-inventory

# Deploy Docker Swarm
./scripts/docker-swarm-manager.sh deploy-swarm

# Check swarm status
./scripts/docker-swarm-manager.sh check-status

# Deploy a stack
./scripts/docker-swarm-manager.sh deploy-stack homebase docker-compose.yml
```

### 3. Manual Swarm Operations

Connect to the manager node and run Docker commands:

```bash
# SSH to manager node
ssh patrick@192.168.20.11

# Check swarm status
docker node ls

# List services
docker service ls

# List stacks
docker stack ls

# Deploy a stack
docker stack deploy -c docker-compose.yml homebase

# Scale a service
docker service scale homebase_web=5

# Update a service
docker service update --image nginx:latest homebase_web
```

## Service Deployment

### Using Docker Compose

The repository includes a sample `docker-compose.yml` with:
- Web service (nginx) - Load balanced across worker nodes
- API service (node.js) - Replicated across worker nodes
- Database service (PostgreSQL) - Single instance on manager node
- Monitoring service (Prometheus) - Single instance on manager node

### Deployment Commands

```bash
# Deploy the sample stack
docker stack deploy -c docker-compose.yml homebase

# Check deployment status
docker stack ps homebase

# View service logs
docker service logs homebase_web

# Remove the stack
docker stack rm homebase
```

## Networking

### Overlay Networks
Docker Swarm automatically creates overlay networks for multi-host communication:
- Services can communicate across nodes using service names
- Networks are encrypted by default
- Load balancing is handled automatically

### Port Exposure
Services can expose ports on the swarm:
- Ports are accessible from any node in the swarm
- Traffic is automatically routed to available service replicas

## Resource Management

### Resource Limits
Services can specify resource limits and reservations:
```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 1G
    reservations:
      cpus: '0.5'
      memory: 512M
```

### Placement Constraints
Control where services run:
```yaml
deploy:
  placement:
    constraints:
      - node.role == manager  # Run on manager nodes
      - node.role == worker   # Run on worker nodes
      - node.labels.ssd == true  # Run on nodes with SSD label
```

## High Availability

### Service Replicas
- Services can be replicated across multiple nodes
- Failed replicas are automatically restarted
- Rolling updates maintain service availability

### Health Checks
Services include health checks for automatic failover:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

## Monitoring and Logging

### Service Logs
```bash
# View service logs
docker service logs -f homebase_web

# View logs from specific tasks
docker service logs --since 1h homebase_web
```

### Node Monitoring
```bash
# Check node resource usage
docker node ps $(docker node ls -q)

# Inspect node details
docker node inspect port-o-party-1
```

## Security

### Network Isolation
- Services communicate through encrypted overlay networks
- Network segmentation between frontend and backend services
- External access only through explicitly exposed ports

### Secrets Management
Docker Swarm supports secrets management:
```bash
# Create a secret
echo "mysecretpassword" | docker secret create db_password -

# Use in service
docker service create --secret db_password myapp
```

## Backup and Recovery

### Data Persistence
- Use named volumes for persistent data
- Volumes are automatically created on appropriate nodes
- Regular backups should be implemented for critical data

### Swarm Recovery
- Manager node contains cluster state
- Additional manager nodes can be added for HA
- Worker nodes can be easily replaced

## Troubleshooting

### Common Issues

1. **Node communication problems**
   ```bash
   # Check network connectivity
   docker node ls
   
   # Check logs
   journalctl -u docker.service
   ```

2. **Service deployment failures**
   ```bash
   # Check service status
   docker service ps homebase_web
   
   # Check service logs
   docker service logs homebase_web
   ```

3. **Resource constraints**
   ```bash
   # Check node resources
   docker system df
   docker system prune
   ```

### Useful Commands

```bash
# Leave swarm (run on worker nodes)
docker swarm leave

# Remove node (run on manager)
docker node rm port-o-party-2

# Rejoin swarm (get token from manager)
docker swarm join-token worker
```

## Best Practices

1. **Service Design**
   - Use health checks for all services
   - Implement graceful shutdown handling
   - Use resource limits to prevent resource exhaustion

2. **Security**
   - Regularly update Docker images
   - Use secrets for sensitive data
   - Implement network segmentation

3. **Monitoring**
   - Monitor service health and performance
   - Set up alerting for service failures
   - Regular backup of persistent data

4. **Deployment**
   - Use rolling updates for zero-downtime deployments
   - Test deployments in staging environment
   - Implement CI/CD for automated deployments