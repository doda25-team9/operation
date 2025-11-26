# Operation - Running the Full SMS Checker Application

This repository contains infrastructure and the runtime configuration for the full SMS Checker system:

- `app` (Java frontend/backend service)
- `model-service` (Python ML model API)

Using **Docker Compose**, you can start both components with one command.
This README contains all instructions required for a new user to run the final integrated application.

## Repository Structure

These are all related repositories:

- [app](https://github.com/doda25-team9/app) — frontend/backend Java application
- [model-service](https://github.com/doda25-team9/model-service) — ML API
- [lib-version](https://github.com/doda25-team9/lib-version) — shared version library
- [operation](https://github.com/doda25-team9/operation) — this repository

This repository (`operation`) contains:

```
operation/
    - docker-compose.yml
    - .env
    - README.md      (this file)
```

## Docker Compose Setup (Assignment 1)

### Prerequisites

Before running anything, make sure you have:

- Docker
- Docker Compose
- Cloned all four repositories into a single folder:

```
your-folder/
    app/
    model-service/
    lib-version/
    operation/
```

- Trained model files are present.

The **model-service** requires trained `.joblib` files:

```
model.joblib
preprocessor.joblib
preprocessed_data.joblib
misclassified_msgs.txt
accuracy_scores.png
```

If you don't have these output files yet, follow the training instructions in `model-service/README.md`.

Once you have done that, you should have a folder called `model-service/output/`. Copy that output folder into `operation/output/`.

### Configuration (.env)

The compose setup uses a `.env` file:

```
APP_PORT=8080
MODEL_PORT=8081
APP_IMAGE=ghcr.io/doda25-team9/app:latest
MODEL_IMAGE=ghcr.io/doda25-team9/model-service:latest
```

You can change ports or image versions here.

### Running the Full Application

Navigate to **operation**:

```
cd operation
docker compose pull
docker compose up
```

This starts:

- `app` (exposed externally)
- `model-service` (internal only, so not exposed to host)

### Check if the application is running

Open:
http://localhost:8080/sms
or replace 8080 in the link above with the app port you find in the .env file

If you see the SMS Checker interface, can submit messages and get a model agreement/disagreement message back after pressing _Check_, everything works.

### Useful Docker Compose Commands

| Action                               | Command                      | Description                            |
| ------------------------------------ | ---------------------------- | -------------------------------------- |
| **Start everything**                 | `docker compose up`          | Starts all services (shows logs)       |
| **Start in background**              | `docker compose up -d`       | Runs services in detached mode         |
| **Stop all running services**        | `docker compose down`        | Stops and removes containers, networks |
| **Rebuild images**                   | `docker compose up --build`  | Rebuilds images before starting        |
| **View logs**                        | `docker compose logs`        | Shows combined logs from all services  |
| **View logs for a specific service** | `docker compose logs app`    | Shows logs only for the app            |
| **Restart one service**              | `docker compose restart app` | Restarts only the app service          |


## VM Infrastructure (Assignment 2)

This section provisions virtual machines using Vagrant for infrastructure automation.

### What Gets Created

Running `vagrant up` automatically creates 3 Ubuntu VMs:
- **ctrl**: Controller node (1 CPU, 4GB RAM)
- **node-1**: Worker node (2 CPUs, 6GB RAM)
- **node-2**: Worker node (2 CPUs, 6GB RAM)

All VMs run Ubuntu 24.04 and are configured via the `Vagrantfile`.

### Prerequisites

- Vagrant
- VirtualBox
- Ansible

Verify these are installed by running:
```bash
ansible --version
vagrant --version
VBoxManage --version
```

Otherwise instill by running:
```sudo apt update
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
sudo apt install -y ansible virtualbox vagrant
```

### How to Run
```bash
# Create and start all VMs (first run downloads Ubuntu image ~500MB, takes 5-10 min)
vagrant up

# Check which VMs are running
vagrant status
# Shows: ctrl, node-1, node-2 with their status (running/stopped/not created)

# Access the controller VM via SSH
vagrant ssh ctrl
# Opens a terminal inside the ctrl VM

# Access a worker VM via SSH
vagrant ssh node-1
# Opens a terminal inside the node-1 VM

# Stop all VMs (keeps them for later)
vagrant halt

# Completely remove all VMs (frees disk space)
vagrant destroy -f
```

#### Testing changes to Vagrantfile
```bash                
vagrant destroy -f            # Delete old VMs
vagrant up                    # Create new VMs with updated config
```

### Configuration variables

To change cluster size or resources, edit these variables at the top of `Vagrantfile`:
- `NUM_WORKERS` - Number of worker nodes (default: 2)
- `CONTROLLER_MEMORY` - Controller RAM in MB (default: 4096 = 4GB)
- `WORKER_MEMORY` - Worker RAM in MB (default: 6144 = 6GB)

After changing variables, run `vagrant destroy -f && vagrant up` to recreate VMs with new settings.

### VM Network Configuration

Each VM has a private network IP for direct communication:
- **ctrl**: `192.168.56.100`
- **node-1**: `192.168.56.101`
- **node-2**: `192.168.56.102`

### Testing Network Connectivity

**Test VM-to-VM communication:**
```bash
# SSH into controller
vagrant ssh ctrl

# Ping worker nodes
ping -c 3 192.168.56.101
ping -c 3 192.168.56.102

# Exit
exit
```

**Test host-to-VM communication:**
```bash
# From your Mac terminal, ping any VM
ping -c 3 192.168.56.100    # Controller
ping -c 3 192.168.56.101    # Worker 1
ping -c 3 192.168.56.102    # Worker 2
```

**SSH directly via IP (alternative to `vagrant ssh`):**
```bash
# SSH using IP address
ssh vagrant@192.168.56.100

# Password: vagrant
```

**Expected result:** All pings should succeed (you see reply messages).

### Ansible Provisioning

VMs are automatically configured using Ansible playbooks during `vagrant up`:

- **playbooks/general.yaml** - Runs on all VMs (shared configuration)
- **playbooks/ctrl.yaml** - Runs only on controller
- **playbooks/node.yaml** - Runs only on workers

### General.yaml

This playbook runs on all VMs and performs the following tasks:
- Add all public keys from the `keys` directory into the `vagrant` user’s `authorized_keys`.
- Disable swap and remove swap entries from `/etc/fstab` to keep it disabled after reboot.
- Ensure `overlay` and `br_netfilter` are registered in `k8s.conf` for future boot and loaded now.
- Configure IPv4 forwarding in `k8s.conf` and apply the changes.



**Re-run provisioning without recreating VMs:**
```bash
# Apply playbook changes to existing VMs
vagrant provision

# Or provision specific VM
vagrant provision ctrl
vagrant provision node-1
```

### Test Provisioning

```bash
vagrant ssh <VM NAME>
 
# Check SSH keys
cat ~/.ssh/authorized_keys

# Verify swap is disabled (should show no output)
swapon --summary        
grep swap /etc/fstab    

# Verify kernel modules are loaded and present in k8s.conf
cat /etc/modules-load.d/k8s.conf
lsmod | grep overlay
lsmod | grep br_netfilter

# Verify sysctl settings (should all be 1)
sysctl net.ipv4.ip_forward
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
```

### Key generation for SSH

To enable SSH with the VMs you should generate an SSH key pair by running:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

You can subsequently find this key in the folder /root/.ssh. Copy the .pub file to the keys folder to create the structure below.

keys/
    your_name_here.pub

### Errors

It is possible that on running `vagrant up`, you encounter:
Stderr: VBoxManage: error: VirtualBox can't operate in VMX root mode. 

This happens because VirtualBox conflicts with KVM. Run the following to solve this error:
```bash
sudo modprobe -r kvm_intel
sudo modprobe -r kvm
```
