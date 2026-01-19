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

### Hostname Resolution
Every VM now receives an updated `/etc/hosts` file for node-to-node name resolution.

**Test (in one of the VMs):**
```
cat /etc/hosts
ping -c 1 ctrl
ping -c 1 node-1
ping -c 1 node-2
```

### Kubernetes Repository
All nodes now use the official Kubernetes repository (v1.32).

**Test (in one of the VMs):**
```
ls /etc/apt/sources.list.d
cat /etc/apt/sources.list.d/pkgs_k8s_io_core_stable_v1_32_deb.list
```

### Installed Tools
All nodes have the following tools installed:
- `containerd`
- `runc`
- `kubeadm / kubelet / kubectl 1.32.4`

**Test (in one of the VMs):**
```
containerd --version
runc --version

kubeadm version
kubelet --version
kubectl version --client=true
```

### containerd Configuration
`containerd` is configured for Kubernetes:
- `disable_apparmor = true`
- `SystemdCgroup = true`
- `sandbox_image = "registry.k8s.io/pause:3.10"`

**Test (in one of the VMs):**
```
sudo grep SystemdCgroup /etc/containerd/config.toml
sudo grep sandbox_image /etc/containerd/config.toml
sudo grep disable_apparmor /etc/containerd/config.toml
```

Additionally you can check that the status of containerd is active: `systemctl status containerd`

### kubelet
`kubelet` is installed and enabled. You can check that it's enabled by using: `systemctl is-enabled kubelet`.

You can check its status by running `systemctl status kubelet`.

## Kubernetes Cluster (Steps 13-17)

The controller node is now configured as a fully functional Kubernetes cluster. This cluster can manage containerized applications, but requires worker nodes to actually run those applications (coming in Steps 18-19).

**What Kubernetes provides:**
- **Control Plane**: Manages the cluster, schedules workloads, and maintains desired state
- **kubectl**: Command-line tool to interact with the cluster
- **Flannel CNI**: Network layer that allows pods to communicate across nodes
- **Helm**: Package manager for Kubernetes applications

**What ctrl.yaml configures:**
- **Step 13**: Initializes Kubernetes cluster with kubeadm (API server listens at 192.168.56.100:6443, pod network uses 10.244.0.0/16)
- **Step 14**: Sets up kubectl access for vagrant user (config at `/home/vagrant/.kube/config`) and copies kubeconfig to `/vagrant/kubeconfig` for host access
- **Step 15**: Installs Flannel CNI for pod networking (configured to use eth1 interface, which is the host-only network adapter for cluster communication)
- **Step 16**: Installs Helm 3 package manager using official installation script from GitHub
- **Step 17**: Installs helm-diff plugin to preview changes before applying Helm upgrades

**Test the cluster:**
```bash
vagrant ssh ctrl

# Check cluster node status
kubectl get nodes
# Expected: ctrl   Ready   control-plane
# "Ready" means the node can accept workloads

# Check system pods (cluster management components)
kubectl get pods -n kube-system
# These pods run the control plane: API server, scheduler, controller manager, etc.

# Check Flannel networking
kubectl get pods -n kube-flannel
# Flannel manages pod-to-pod networking across the cluster

# Verify Helm installation
helm version
# Helm allows you to install pre-packaged Kubernetes applications

# Verify helm-diff plugin
helm plugin list
# helm-diff shows what changes before you apply them

exit
```

**Current limitation:** 
By default, Kubernetes prevents regular application pods from running on control plane nodes. Pods will stay in "Pending" state until worker nodes join (Steps 18-19).

**Using kubectl:**

kubectl is the main tool for interacting with Kubernetes. You can use it from inside the controller VM or from your host machine.

From inside controller VM:
```bash
vagrant ssh ctrl
kubectl get nodes              # List cluster nodes
kubectl get pods               # List pods in default namespace
kubectl get pods --all-namespaces  # List all pods in all namespaces
```
From host machine:
```bash

# Point kubectl to the cluster using the copied config file
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes
```

**Note:** 
- This did not work during our testing on macOS with Apple Silicon (M3 chip), resulting in a "no route to host" error. This appears to be a known VirtualBox networking limitation on ARM-based Macs. kubectl works perfectly inside the VM via `vagrant ssh ctrl`. We will ask for clarification if this affects testing/grading.

## Worker Nodes (Steps 18-19)

Worker nodes automatically join the cluster during `vagrant up`.

**Verify that workers are joined:**
```bash
vagrant ssh ctrl -c "kubectl get nodes"

# Expected: ctrl, node-1, node-2 all showing "Ready" status
```

- The final steps for nodes (`Run join command`) will probably fail if you are using Linux as it is a common issue. We tested it on MacOS and it works. We will clarify this with the lecturers.


**Understanding the shared folder:**

Vagrant automatically shares your host's `operation/` directory with all VMs at `/vagrant/`. Any file you create in the operation folder on your host is immediately accessible inside the VMs at `/vagrant/`. This is useful for deploying Kubernetes manifests without manual file copying.

## Running the kubernetes cluster (Assignment 3)

First, start the minikube cluster 
```
minikube start --driver=docker
```

Then enable the ingress addon:
```
minikube addons enable ingress
```

To start the app and model-service using kubernetes, run:

```
kubectl apply -f k8s -R
```

### Access Application

#### Option A: kubectl port-forward
Same port every time (8080), works on any Kubernetes cluster.

**Step 1: Add hostname to /etc/hosts (one-time setup)**
Find the IP address of the minikube service:
```bash
minikube ip
```
Then run the following command substituting 127.0.0.1 with the result from the previous step.
```bash
echo "127.0.0.1 sms-checker.local" | sudo tee -a /etc/hosts
```

Verify it was added:
```bash
cat /etc/hosts | grep sms-checker
# Should show: 127.0.0.1 sms-checker.local
```

**Step 2: Port-forward to Ingress Controller**
```bash
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80
```

Keep this terminal open. You should see:
```
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

**Step 3: Access the application**

In browser:
```
http://sms-checker.local:8080/sms/
```

Or with curl:
```bash
curl http://sms-checker.local:8080/sms/
```

**How It Works**

1. Browser sends request to `sms-checker.local:8080`
2. `/etc/hosts` resolves `sms-checker.local` to `127.0.0.1`
3. `kubectl port-forward` tunnels `localhost:8080` to Ingress Controller port 80
4. Ingress Controller receives request with `Host: sms-checker.local` header
5. Ingress rules match the hostname and route to `app-service`
6. App responds

**Traffic flow:** Browser → port-forward → Ingress Controller → app-service

This satisfies "accessing through Ingress" - the Ingress Controller processes routing rules.

**Cleanup**

**Stop port-forward:** Press `Ctrl+C` in the port-forward terminal

**Remove hostname (optional):**
```bash
sudo sed -i '' '/sms-checker.local/d' /etc/hosts
```


### Option B: minikube service (macOS only)

**Alternative method using Minikube's service tunnel command.**

**Note:** Port number changes each time you restart the tunnel.

**Step 1: Add hostname to /etc/hosts (one-time setup, if not already done)**
```bash
echo "127.0.0.1 sms-checker.local" | sudo tee -a /etc/hosts
```

**Step 2: Start minikube service tunnel**
```bash
minikube service -n ingress-nginx ingress-nginx-controller
```

Keep this terminal open. You'll see output like:
```
http://127.0.0.1:54471
http://127.0.0.1:54472
```

**Note the first port number** (e.g., `54471` - yours will be different each time)

**Step 3: Access the application**

Replace `PORT` with your actual port number from Step 2:

In browser:
```
http://sms-checker.local:PORT/sms/
```

Example: `http://sms-checker.local:54471/sms/`

Or with curl:
```bash
curl http://sms-checker.local:54471/sms/
```

#### How It Works

1. `minikube service` creates a tunnel from localhost to the Ingress Controller
2. Browser sends request to `sms-checker.local:PORT`
3. `/etc/hosts` resolves `sms-checker.local` to `127.0.0.1`
4. Tunnel forwards traffic to Ingress Controller
5. Ingress Controller receives request with `Host: sms-checker.local` header
6. Ingress rules match the hostname and route to `app-service`

**Traffic flow:** Browser → minikube tunnel → Ingress Controller → app-service

#### Important Notes

- Port changes each time you restart the tunnel - check the output for the current port
- The tunnel must stay running while you use the app
- Stop with `Ctrl+C` in the tunnel terminal


## Helm Chart Deployment (Assignment 3)

The Helm chart provides a streamlined way to deploy the complete SMS Checker application to any Kubernetes cluster.

### Prerequisites

- Kubernetes cluster running (Minikube or provisioned cluster)
- Helm 3.x installed
- kubectl configured to access your cluster
- Nginx Ingress Controller installed
- SMTP secret for app and model service set
- SMTP secret for Alertmanager
- Grafana secret set

For Minikube:
```bash
minikube start
minikube addons enable ingress

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

For each step below replace the placeholder values with your own values.

SMTP credentials for app and model service
```bash
kubectl create secret generic smtp-credentials \
  --from-literal=SMTP_USER="user" \
  --from-literal=SMTP_PASS="password"
```

Alertmanager SMTP credentials
```bash
kubectl create secret generic alertmanager-smtp-secret \
  --from-literal=SMTP_USER="user@example.com" \
  --from-literal=SMTP_PASS="password"
```

Grafana admin credentials
```bash
kubectl create secret generic grafana-admin-secret \
  --from-literal=admin-user="user" \
  --from-literal=admin-password="password"
```



### Quick Start
Deploy the complete application:
```bash
cd operation
helm install sms-checker ./helm-chart
```

This deploys:
- Application service (3 replicas)
- Model service (2 replicas)
- Services (app-service, model-service)
- Ingress (sms-checker.local)
- ConfigMap (environment variables)

### Verify Deployment
```bash
helm status sms-checker
kubectl get all
kubectl get ingress
```

Expected output:
- 3 app pods: Running
- 2 model-service pods: Running
- 2 services, 1 ingress, 1 configmap

All pods should be in Running state once images are pulled from the registry.

### Access Application
```bash
# Add hostname to /etc/hosts
echo "127.0.0.1 sms-checker.local" | sudo tee -a /etc/hosts

# Port-forward Ingress Controller
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80
```

Access in browser: `http://sms-checker.local:8080/sms/`



### Customization

Override default values during installation:

```bash
# Change replicas
helm install sms-checker ./helm-chart --set app.replicas=5

# Change hostname
helm install sms-checker ./helm-chart --set ingress.host=myapp.local

# Disable ingress
helm install sms-checker ./helm-chart --set ingress.enabled=false

# Use custom values file
helm install sms-checker ./helm-chart -f my-values.yaml
```

Verify changes:
```bash
kubectl get pods -l component=app                              # Check replica count
kubectl get ingress app-ingress -o jsonpath='{.spec.rules[0].host}'  # Check hostname
```

### Management
```bash
# View status
helm status sms-checker

# List releases
helm list

# Upgrade
helm upgrade sms-checker ./helm-chart --set app.replicas=5

# Rollback
helm rollback sms-checker

# Uninstall
helm uninstall sms-checker
```

### Configuration Options

Key values (see `helm-chart/values.yaml` for complete list):

| Parameter | Description | Default |
|-----------|-------------|---------|
| `app.replicas` | Number of app pods | `3` |
| `modelService.replicas` | Number of model-service pods | `2` |
| `ingress.enabled` | Enable/disable Ingress | `true` |
| `ingress.host` | Hostname for accessing app | `sms-checker.local` |

### Testing

**Test upgrade functionality:**
```bash
helm upgrade sms-checker ./helm-chart --set app.replicas=5
kubectl get pods -l component=app  # Verify 5 pods running
```

**Test configuration:**
```bash
# Verify ConfigMap values
kubectl get configmap env-config-map -o jsonpath='{.data.MODEL_HOST}'
# Should output: http://model-service:8081

# Verify app pods can read ConfigMap
kubectl exec deployment/app-deployment -- env | grep MODEL_HOST
```

**Test portability:**
```bash
# Deploy to different cluster
minikube start -p test-cluster
minikube addons enable ingress -p test-cluster
helm install test ./helm-chart
```

### Troubleshooting
```bash
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Check ingress
kubectl describe ingress app-ingress

# Check configuration
kubectl get configmap env-config-map -o yaml
kubectl get secrets

# View all release resources
kubectl get all -l app.kubernetes.io/instance=sms-checker

# If installation fails, clean up and retry
helm uninstall sms-checker
helm install sms-checker ./helm-chart
```


## Prometheus Monitoring Setup

### Prerequisites

- Minikube installed
- kubectl installed
- Helm 3 installed
- Docker installed

---

### Installation Steps

### 1. Start Minikube, if you haven't already
```bash
minikube start --driver=docker
minikube addons enable ingress
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
```

---

### 2. Install Application with Monitoring
```bash
# Download Prometheus dependency
cd helm-chart
helm dependency update
cd ..

# Install everything (app + Prometheus)
helm install sms-checker ./helm-chart

# Wait for pods
kubectl wait --for=condition=ready pod -l component=app --timeout=300s
```

---

### 3. Verify Application Works
```bash
# Port-forward to app
kubectl port-forward svc/app-service 8080:8080
```

**In another terminal:**
```bash
# Test metrics endpoint
curl http://localhost:8080/metrics
```

---

### 4. Access Prometheus UI
```bash
kubectl port-forward svc/prometheus-prometheus 9090:9090
```

**Open browser:** http://localhost:9090

---

## View Metrics in Prometheus

### Check Targets

1. Go to **Status** → **Targets**
2. Look for `serviceMonitor/default/app-monitor/0`
3. Verify **State = UP** (3/3 pods)

### Query Metrics

1. Click **Graph** tab
2. Type: `sms_requests_total` (or any other metric you prefer, check table metrics below)
3. Click **Execute**

---

## Generate Test Traffic
```bash
# Port-forward (if not running)
kubectl port-forward svc/app-service 8080:8080
```

**In another terminal:**
```bash
# Send 10 requests
for i in {1..10}; do
  curl -X POST http://localhost:8080/sms/ \
    -H "Content-Type: application/json" \
    -d '{"sms":"Test message"}' 
  sleep 1
done
```

**Refresh Prometheus query** - metrics should update!

---

### Available Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `sms_requests_total` | Counter | Total SMS prediction requests |
| `predictions_result_total` | Counter | Predictions by result (spam/ham) |
| `active_users` | Gauge | Current active users |
| `request_duration` | Histogram | Request duration distribution (seconds) |
| `sms_length` | Histogram | SMS message length distribution |

---

### Useful Queries
```promql
# Total requests
sms_requests_total

# Requests per second
rate(sms_requests_total[5m])

# Spam vs Ham totals
sum by (result) (predictions_result_total)

# Average request duration
rate(request_duration_sum[5m]) / rate(request_duration_count[5m])

```

---


---

## Clean Up
```bash
# Uninstall application
helm uninstall sms-checker

# Delete cluster
minikube delete
```

---

## Troubleshooting


**Service name different:**
```bash
# Find correct service
kubectl get svc | grep prometheus
# Use the one with port 9090/TCP (not "operated")
```

## Email Alerting System

### Alert Details

- **Threshold:** 15 requests per minute
- **Duration:** Must exceed threshold for 2 continuous minutes
- **Email From:** doda.team9@gmail.com (team Gmail account)
- **Email To:** Address provided during installation

### How to Test

**Prerequisites:**
- Minikube running with the application deployed

### Current Implementation

The Helm chart does not contain any SMTP credentials and does not create Secrets with sensitive data.

Alertmanager reads its SMTP username and password from a pre‑existing Kubernetes Secret that must be created manually before installing the chart.

### Step 1: Install or Upgrade Helm
```bash
helm install sms-checker ./helm-chart \ 
  --set alertmanager.recipient="your-email@example.com"
```
or 
```bash
helm upgrade sms-checker ./helm-chart \ 
  --set alertmanager.recipient="your-email@example.com"
```

Replace `your-email@example.com` with your actual email address.
---

### Step 2: Verify SMTP Configuration
```bash
kubectl get secret alertmanager-custom-config -o jsonpath='{.data.alertmanager\.yaml}' | base64 -d | grep smtp
```

Should show that SMTP authentication fields are present and referencing the mounted Secret.
---

### Step 3: Port-Forward Istio Gateway
```bash
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
```

Keep this terminal running.

---

### Step 4: Generate High Traffic

Open a new terminal and send requests:
```bash
for i in {1..500}; do
  curl -X POST http://localhost:8080/sms/ \
    -H "Host: sms-checker.local" \
    -H "Content-Type: application/json" \
    -d '{"sms":"Alert test '$i'"}'
  echo "Request $i sent"
  sleep 0.5
done
```

This sends 2 requests per second (120 requests/minute), exceeding the 15 requests/minute threshold.

**Note: Each pod is individually evaluated by Prometheus, and since we have 3 replicas, all 3 are receiving high traffic and trigger the alert.**

---

### Step 5: Monitor Alert in Prometheus

In another terminal:
```bash
kubectl port-forward svc/prometheus-prometheus 9090:9090
```

Open browser: http://localhost:9090/alerts

Watch `HighRequestRate` alert progress:
- **0-1 min:** Inactive (green)
- **1-3 min:** Pending (yellow) - waiting for 2-minute duration
- **After 3 min:** Firing (red) - email will be sent

---

### Step 6: Check AlertManager

In another terminal:
```bash
kubectl port-forward svc/prometheus-alertmanager 9093:9093
```

Open browser: http://localhost:9093

You should see the `HighRequestRate` alert when it starts firing.

---

### Step 7: Receive Email

After the alert starts firing:

**Check your inbox for email from:** `doda.team9@gmail.com`

**Subject:** `[ALERT] HighRequestRate - SMS Checker`

**Note:** Check spam folder if not in inbox.

When you stop sending requests, you'll receive a second email confirming the alert resolved.


---


## Grafana Dashboards

If you have not installed the monitoring stack yet:

```
cd operation
cd helm-chart
helm dependency update
cd ..
helm install sms-checker ./helm-chart
```

**Verify the monitoring components:**
```
kubectl get pods | grep grafana
kubectl get pods | grep prometheus
```

---

To generate traffic that appears in Grafana:

`kubectl port-forward svc/app-service 8080:8080`

Leave this terminal running. You can send requests so that the grafana dashboards will update in real time. 

**Port-forward Grafana:**
```
kubectl port-forward svc/sms-checker-grafana 3000:80
```

**Open in your browser:** http://localhost:3000/

**Login to Grafana:**

Grafana will prompt for credentials in the browser. These were set in the kubernetes secrets. The default values are:
Username: `user`

Password: `password`

---

**Access Installed Dashboards:**

Once logged in:
1. Click `Dashboards` (left sidebar)
2. Find the two dashboards:
    - `SMS Checker - Application Metrics`
    - `SMS Checker - A/B Testing Dashboard` (has placeholder visuals, it is used in assignment 4)

---

**To make changes to the dashboards:**

1. Make the changes in the `.json` files from `helm-chart/dashboards/`
2. Run the following commands: 
    ```
    helm upgrade sms-checker ./helm-chart

    kubectl delete pod $(kubectl get pod | grep grafana | awk '{print $1}')

    kubectl port-forward svc/sms-checker-grafana 3000:80     
    ```
3. Refresh Grafana website.


## Traffic Management with Istio (Assignment 4)

This implementation uses Istio service mesh to enable advanced traffic management including canary deployments and version-consistent routing between services.

### Architecture Overview

The deployment implements a 90/10 canary release pattern:

**External Traffic Flow:**
```
User → Istio IngressGateway (port 80)
  ↓
Gateway (sms-gateway) - accepts traffic for sms-checker.local
  ↓
VirtualService (app-virtualservice) - 90/10 traffic split
  ↓
DestinationRule (app-destinationrule) - defines v1/v2 subsets
  ↓
90% → app-service v1 (3 replicas, stable)
10% → app-service v2 (1 replica, canary)
```

**Internal Traffic Flow (Version Consistency):**
```
app-service v1 → VirtualService (model-virtualservice) → model-service v1
app-service v2 → VirtualService (model-virtualservice) → model-service v2
```

**Key Features:**
- **90/10 Canary Split:** 90% of traffic routes to stable v1, 10% to canary v2
- **Version Consistency:** App v1 always calls model v1, app v2 always calls model v2 (enforced by sourceLabels)
- **Configurable:** All settings (gateway name, hostname, traffic split) adjustable via values.yaml

---

### Prerequisites

- Kubernetes cluster (Minikube recommended)
- Istio 1.28+ installed
- Helm 3.x
- kubectl configured

### Install Istio
```bash
# Install Istio with demo profile
istioctl install --set profile=demo -y

# Enable automatic sidecar injection
kubectl label namespace default istio-injection=enabled --overwrite

# Install monitoring addons
kubectl apply -f samples/addons/prometheus.yaml
kubectl apply -f samples/addons/kiali.yaml

# Verify installation
kubectl get pods -n istio-system
```

**Expected:** All Istio components (istiod, istio-ingressgateway) running.

---

### Deploy Application
```bash
cd operation

# Deploy with Istio traffic management
helm install sms-checker ./helm-chart

# Wait for pods to be ready (may take 1-2 minutes)
kubectl wait --for=condition=ready pod -l app=sms-checker --timeout=120s
kubectl wait --for=condition=ready pod -l app=model-service --timeout=120s

# Verify deployment
kubectl get pods
```

**Expected output:**
```
NAME                                   READY   STATUS    RESTARTS   AGE
app-deployment-v1-xxx                  2/2     Running   0          1m
app-deployment-v1-yyy                  2/2     Running   0          1m
app-deployment-v1-zzz                  2/2     Running   0          1m
app-deployment-v2-aaa                  2/2     Running   0          1m
model-deployment-v1-bbb                2/2     Running   0          1m
model-deployment-v1-ccc                2/2     Running   0          1m
model-deployment-v1-ddd                2/2     Running   0          1m
model-deployment-v2-eee                2/2     Running   0          1m
```

All pods should show `2/2` (application container + Istio sidecar proxy).

**Verify Istio resources:**
```bash
kubectl get gateway,virtualservice,destinationrule
```

**Expected:** 1 Gateway, 2 VirtualServices, 2 DestinationRules.

---

### Testing Traffic Management

#### Test 1: Verify 90/10 Traffic Split

Since the application runs inside the cluster, testing must be done from within:
```bash
# Get IngressGateway endpoint
INGRESS_HOST=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.clusterIP}')
INGRESS_PORT=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')

# Deploy temporary test pod
kubectl run curl-test --image=curlimages/curl:latest --restart=Never -- sleep 120
kubectl wait --for=condition=ready pod curl-test --timeout=30s

# Send 100 requests and count version distribution
kubectl exec curl-test -- sh -c "
for i in \$(seq 1 100); do
  curl -s -H 'Host: sms-checker.local' -I http://$INGRESS_HOST:$INGRESS_PORT/sms/ | grep 'x-app-version:'
done" | awk '{print $2}' | sort | uniq -c

# Cleanup
kubectl delete pod curl-test
```

**Expected output:**
```
  93 v1
   7 v2
```
(±10% variance acceptable - approximately 90/10 split)

**What this proves:** 
- Gateway correctly routes traffic to VirtualService
- VirtualService applies 90/10 weight distribution
- DestinationRule subsets (v1, v2) correctly filter pods by version label

---

#### Test 2: Verify Version Consistency
```bash
# Verify sourceLabels routing configuration
kubectl get virtualservice model-virtualservice -o yaml | grep -B2 -A5 "sourceLabels:"

# Verify DestinationRule subsets
kubectl get destinationrule model-destinationrule -o jsonpath='{.spec.subsets[*].name}'

# Verify pod labels match subsets
kubectl get pods -l app=model-service -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.version}{"\n"}{end}'
```

**Expected:**
- sourceLabels show version: v1 and version: v2 routing rules
- DestinationRule has v1 v2 subsets
- Model pods labeled with v1 and v2

**What this proves:** Configuration is correct for version consistency routing

---

**Expected:** 
- Weights show 90 and 10
- Pods labeled with version=v1 and version=v2
- Subsets v1 and v2 defined in DestinationRule
- No validation issues from istioctl

---

### Configuration

All Istio settings are configurable in `values.yaml`:
```yaml
istio:
  enabled: true
  host: sms-checker.local           # Hostname for accessing app
  
  gateway:
    name: sms-gateway               # Gateway resource name
    ingressGatewaySelector: ingressgateway  # Istio IngressGateway selector
  
  trafficSplit:
    stable: 90                      # % traffic to v1 (stable)
    canary: 10                      # % traffic to v2 (canary)

versions:
  v1:
    enabled: true
    replicas: 3                     # Stable version replicas
    imageTag: latest
  v2:
    enabled: true
    replicas: 1                     # Canary version replicas
    imageTag: latest
```

#### Adjust Traffic Split

Change the canary rollout percentage:
```bash
# 95/5 split (more conservative)
helm upgrade sms-checker ./helm-chart \
  --set istio.trafficSplit.stable=95 \
  --set istio.trafficSplit.canary=5

# Verify new split (run Test 1 again)
```

#### Change Hostname

Deploy with custom hostname for grading:
```bash
helm upgrade sms-checker ./helm-chart \
  --set istio.host=custom.grader.local

# Update /etc/hosts if testing locally
echo "127.0.0.1 custom.grader.local" | sudo tee -a /etc/hosts
```

#### Disable Canary

Route 100% traffic to stable version:
```bash
helm upgrade sms-checker ./helm-chart \
  --set versions.v2.enabled=false

# Verify only v1 pods exist
kubectl get pods | grep deployment
```

---

### Monitoring with Kiali

Visualize traffic distribution:
```bash
# Open Kiali dashboard
istioctl dashboard kiali

# In Kiali:
# 1. Select namespace: default
# 2. Go to Graph tab
# 3. Display → Traffic Distribution
# 4. Send traffic (run Test 1)
# 5. Observe 90/10 split between v1 and v2
```

---

### Troubleshooting

**Pods show 1/2 Ready:**
```bash
# Check if Istio injection enabled
kubectl get namespace default --show-labels
# Should show: istio-injection=enabled

# If missing, enable and recreate pods
kubectl label namespace default istio-injection=enabled
helm uninstall sms-checker
helm install sms-checker ./helm-chart
```

**Traffic not splitting correctly:**
```bash
# Verify VirtualService weights
kubectl get virtualservice app-virtualservice -o yaml | grep -A 15 "route:"

# Check DestinationRule subsets match pod labels
kubectl get destinationrule app-destinationrule -o yaml | grep -A 10 "subsets:"
kubectl get pods -l app=sms-checker --show-labels
```

**Version consistency not working:**
```bash
# Check model VirtualService has sourceLabels
kubectl get virtualservice model-virtualservice -o yaml | grep -A 5 "sourceLabels:"

# Verify pod version labels
kubectl get pods --show-labels | grep version
```

**Istio configuration issues:**
```bash
# Run Istio analyzer
istioctl analyze

# Check Istio proxy logs
kubectl logs <pod-name> -c istio-proxy
```

---

### Implementation Details

**Components:**
- **Gateway:** Entry point for external traffic, listens on port 80 for sms-checker.local
- **VirtualService (app):** Routes external traffic with 90/10 split to app-service subsets
- **VirtualService (model):** Routes internal traffic based on caller version (sourceLabels matching)
- **DestinationRule (app):** Defines v1/v2 subsets, selects pods by version label
- **DestinationRule (model):** Defines v1/v2 subsets for model-service
- **Deployments:** Separate deployments for v1 (3 replicas) and v2 (1 replica) of each service

**How it works:**
1. User request hits Istio IngressGateway
2. Gateway accepts traffic for sms-checker.local
3. Routes to app-virtualservice
4. VirtualService applies 90/10 weight: randomly selects v1 or v2
5. DestinationRule filters pods: subset v1 → version=v1 pods, subset v2 → version=v2 pods
6. When app calls model-service internally:
   - model-virtualservice checks sourceLabels (caller's version label)
   - Routes app v1 → model v1, app v2 → model v2
7. Ensures version consistency throughout request lifecycle

---

## Shadow Launch (Additional Use Case)

We deploy a third model-service version (v3) that receives mirrored copies of all traffic from both the stable (v1) and canary (v2) versions, allowing us to evaluate the shadow version's performance using real user requests without exposing users to its responses. 
Users only see results from v1/v2 while v3 silently processes the same requests and records metrics for comparison.

### Prerequisites

- Kubernetes cluster with Istio installed
- Application deployed: `helm install sms-checker ./helm-chart`


### Setup

**1. Verify Pods Running**
```bash
kubectl get pods | grep -E "app-deployment|model-deployment"

# Expected:
# app-deployment-v1 (3 pods) - 2/2 Running
# app-deployment-v2 (1 pod) - 2/2 Running
# model-deployment-v1 (3 pods) - 2/2 Running
# model-deployment-v2 (1 pod) - 2/2 Running
# model-deployment-v3 (1 pod) - 2/2 Running  ← Shadow
```

---

**2. Port-Forward Istio Gateway**

Must access through Istio Gateway (not app-service directly).
```bash
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
```

**Keep this running.**


### **Testing**

**1. Send Test Requests**
```bash
# Send 100 requests through Gateway
for i in {1..100}; do
  curl -X POST http://localhost:8080/sms/ \
    -H "Host: sms-checker.local" \
    -H "Content-Type: application/json" \
    -d '{"sms":"Test message '$i'"}'
  sleep 0.1
done
```


**2. Verify Shadow Launch**

Due to our implementation for canary deployment, the traffic is split 90/10 to v1 and v2, respectively. However, v3 mirrors both v1 and v2.

```bash
# Count model-v1 requests (should match app-v1)
echo "model-v1 total:"
for pod in $(kubectl get pods | grep model-deployment-v1 | awk '{print $1}'); do
  kubectl logs $pod -c model | grep -c "POST /predict"
done | awk '{s+=$1} END {print s}'

# Count model-v2 requests (should match app-v2)
echo "model-v2 total:"
kubectl logs $(kubectl get pods | grep model-deployment-v2 | awk '{print $1}') -c model | grep -c "POST /predict"

# Count model-v3 requests (should equal v1 + v2 = ~100, all traffic is mirrored)
echo "model-v3 total (shadow):"
kubectl logs $(kubectl get pods | grep model-deployment-v3 | awk '{print $1}') -c model | grep -c "POST /predict"
```


**3. Check Metrics**
```bash
# Port-forward model-v3 (shadow)
kubectl port-forward $(kubectl get pods | grep model-deployment-v3 | awk '{print $1}') 8082:8081

# Check v3 metrics (should match total traffic)
curl http://localhost:8082/metrics | grep model_predictions_total
```
