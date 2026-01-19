# Assignment 2: Infrastructure Provisioning

This guide covers provisioning the Virtual Machines and Kubernetes Cluster using Vagrant and Ansible.

## Architecture

Running `vagrant up` automatically creates 3 Ubuntu 24.04 VMs:

| Node | Role | IP Address | Specs |
| :--- | :--- | :--- | :--- |
| **ctrl** | Controller | `192.168.56.100` | 1 CPU, 4GB RAM |
| **node-1** | Worker | `192.168.56.101` | 2 CPU, 6GB RAM |
| **node-2** | Worker | `192.168.56.102` | 2 CPU, 6GB RAM |

### Configuration variables & Information


To change cluster size or resources, edit these variables at the top of `Vagrantfile`:
- `NUM_WORKERS` - Number of worker nodes (default: 2)
- `CONTROLLER_MEMORY` - Controller RAM in MB (default: 4096 = 4GB)
- `WORKER_MEMORY` - Worker RAM in MB (default: 6144 = 6GB)
