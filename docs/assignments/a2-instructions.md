# Assignment 2: Infrastructure Provisioning

This guide covers provisioning the Virtual Machines and Kubernetes Cluster using Vagrant and Ansible.

## Architecture

Running `vagrant up` automatically creates 3 Ubuntu 24.04 VMs:

| Node | Role | IP Address | Specs |
| :--- | :--- | :--- | :--- |
| **ctrl** | Controller | `192.168.56.100` | 1 CPU, 4GB RAM |
| **node-1** | Worker | `192.168.56.101` | 2 CPU, 6GB RAM |
| **node-2** | Worker | `192.168.56.102` | 2 CPU, 6GB RAM |

VMs are automatically configured using Vagrantfile and Ansible playbooks:

- **playbooks/general.yaml** - Runs on all VMs (shared configuration)
- **playbooks/ctrl.yaml** - Runs only on controller
- **playbooks/node.yaml** - Runs only on workers

Furthermore, we have another playbook that can be run from the host to perform final installation steps
- **playbooks/finalization.yaml** - Needs to be run manually from the host using the following command:
```bash
ansible-playbook -u vagrant -i 192.168.56.100, ./playbooks/finalization.yml
```

## Configuration variables & Information
To change cluster size or resources, edit these variables at the top of `Vagrantfile`:
- `NUM_WORKERS` - Number of worker nodes (default: 2)
- `CONTROLLER_MEMORY` - Controller RAM in MB (default: 4096 = 4GB)
- `WORKER_MEMORY` - Worker RAM in MB (default: 6144 = 6GB)
After changing variables, run `vagrant destroy -f && vagrant up` to recreate VMs with new settings.

## Useful Commands

### 1. VM Management (Vagrant)

| Action | Command | Description                                                                                                                                      |
| :--- | :--- |:-------------------------------------------------------------------------------------------------------------------------------------------------|
| **Start Environment** | `vagrant up` | Creates and configures all 3 VMs (approx. 3-5minutes).                                                                                           |
| **Check Status** | `vagrant status` | Shows state of `ctrl`, `node-1`, and `node-2`.                                                                                                   |
| **SSH Access** | `vagrant ssh <name>` | Log into a VM (e.g., `vagrant ssh ctrl`).                                                                                                        |
| **Direct SSH** | `ssh vagrant@192.168.56.100` | Alternative access via IP (Password: `vagrant`). This specific command gives access to controller, change IP if you want to access worker nodes. |
| **Apply Changes** | `vagrant provision` | Re-runs playbooks on running VMs without restarting.                                                                                             |
| **Stop VMs** | `vagrant halt` | Shuts down VMs but preserves data.                                                                                                               |
| **Destroy VMs** | `vagrant destroy -f` | Deletes VMs and frees disk space.                                                                                                                |
| **Full Reset** | `vagrant destroy -f && vagrant up` | Wipes everything and starts fresh.                                                                                                               |

### 2. Kubernetes Interaction (kubectl)

These commands can be run from **inside the `ctrl` VM** or from your **Host** (if configured).

| Scope | Command | Description |
| :--- | :--- | :--- |
| **Cluster Status** | `kubectl get nodes` | Check if Controller and Workers are `Ready`. |
| **System Pods** | `kubectl get pods -n kube-system` | Verify CoreDNS, API Server, etc. are running. |
| **Network Pods** | `kubectl get pods -n kube-flannel` | Verify the Flannel CNI network overlay. |
| **All Pods** | `kubectl get pods -A` | List every running pod in the cluster. |
| **Helm Version** | `helm version` | Verify Helm package manager is installed. |
| **Helm Plugins** | `helm plugin list` | Verify `helm-diff` plugin is present. |


### 3. System & Network Verification

Use these commands inside a VM to verify low-level provisioning tasks.

| Category | Verification Command | Expected Output |
| :--- | :--- | :--- |
| **Connectivity** | `ping -c 3 192.168.56.101` | Successful replies (VM-to-VM visibility). |
| **Name Resolution** | `ping -c 1 node-1` | Successful reply (Hostname DNS works). |
| **SSH Keys** | `cat ~/.ssh/authorized_keys` | Should display the keys from your `keys/` folder. |
| **Swap Status** | `swapon --summary` | **Empty output** (Swap must be disabled for K8s). |
| **Kernel Modules** | `lsmod \| grep overlay` | `overlay` should be present. |
| **IP Forwarding** | `sysctl net.ipv4.ip_forward` | `net.ipv4.ip_forward = 1` |
| **Container Runtime** | `systemctl status containerd` | Status should be `active (running)`. |
| **Kubelet** | `systemctl status kubelet` | Status should be `active (running)`. |

## Setup: SSH Key Generation
We provided two SSH keys which are located in `./keys/` folder. If you want to generate your own keys, follow these steps:
```bash
# 1. Generate Key
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. Move to project folder (replace paths as needed)
cp /path/to/generated/key.pub ./keys/your_name.pub
```

---

## Technical Implementation

This section details how the Ansible playbooks configure the nodes.

### 1. General Configuration (`general.yaml`)
Applied to **all nodes** (Controller & Workers).
* **SSH Keys:** Adds public keys from `keys/` to `authorized_keys`.
* **Swap:** Disables swap (required for Kubelet) and removes `/etc/fstab` entries.
* **Kernel Modules:** Loads `overlay` and `br_netfilter` for container networking.
* **Sysctl:** Enables IPv4 forwarding (`net.ipv4.ip_forward`) for traffic routing.
* **Repositories:** Configures the official Kubernetes v1.32 apt repository.

### 2. Control Plane (`ctrl.yaml`)
Applied to the **Controller** node only.
* **Initialization:** Runs `kubeadm init` (API Server at `192.168.56.100:6443`).
* **Kubeconfig:** Sets up the `.kube/config` for the vagrant user and copies it to `/vagrant/kubeconfig` for host access.
* **CNI (Networking):** Installs **Flannel** on `eth1` (Host-Only Network) to allow pod-to-pod communication.
* **Helm:** Installs Helm 3 and the `helm-diff` plugin.

### 3. Worker Nodes (`node.yaml`)
Applied to **node-1** and **node-2**.
* **Join:** Retrieves the join token from the Controller and executes `kubeadm join`.
* **Architecture:** Once joined, these nodes accept application workloads (Pods), as the Controller is tainted to refuse general workloads by default.

### 4. Finalization (`finalization.yml`)
Run manually from the host, this playbook deploys the application platform components:

* **MetalLB (Load Balancer):**
    * Configured with an IP Address Pool `192.168.56.90-99`.
    * Allows bare-metal clusters to issue external IPs to services.
* **Nginx Ingress Controller:**
    * **Fixed IP:** Hardcoded to listen on `192.168.56.99`.
    * **HTTPS:** Configured with **self-signed certificates** (pre-generated in `playbooks/certificates/`) to enable secure access immediately.
* **Kubernetes Dashboard:**
    * Deployed via Helm.
    * **Access:** Exposed via Ingress at `https://dashboard.local`.
    * **Auth:** An `admin-user` ServiceAccount is created for token-based login.
* **Istio Service Mesh:**
    * Installs `istiod` and `istio-ingressgateway` using the binary `istioctl` (downloaded during provisioning).
    * Prepares the cluster for Assignment 4 (Traffic Management).

### Shared Folders
Vagrant maps the `operation/` folder on your host to `/vagrant/` inside the VMs.
* **Benefit:** You can edit Kubernetes manifests on your host and apply them inside the VM immediately:

---

### Service IPs & Domains
After running the finalization playbook, the following entry points are available:

| Component | IP Address | Hostname | Notes |
| :--- | :--- | :--- | :--- |
| **Ingress Controller** | `192.168.56.99` | `*.local` | Entry point for all HTTP/HTTPS traffic. |
| **K8s Dashboard** | `192.168.56.99` | `dashboard.local` | Accessible via HTTPS. |
| **Istio Gateway** | `192.168.56.95` | `sms-checker.local` | (Configured in A4) |

---

## Known Issues & Limitations

### 1. macOS Apple Silicon (M3)
There is a known networking limitation with VirtualBox on ARM-based Macs.
* **Issue:** `kubectl` commands run from the **host** machine may fail with "No route to host".
* **Workaround:** Always run `kubectl` commands from inside the controller VM:
```bash
    vagrant ssh ctrl
```

### 2. Linux Host "Join" Issues
On some Linux hosts, the Ansible task that runs the `kubeadm join` command on workers may fail due to timeout or network interface mismatch.
Try opening you VirtualBox application and disabling DHCP server.