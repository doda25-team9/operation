# Assignment 3: Kubernetes Deployment & Monitoring

This guide covers the deployment of the full application stack (App, Model, Monitoring, Alerting) using **Helm**. It is designed to work on both the provisioned Vagrant cluster and local Minikube environments.

## Prerequisites
You can either run this using Minikube or on the custom cluster deployed in previous assignment.

---

## Deployment Step 1: Option A: Production Cluster (Vagrant VMs)

Provision a cluster using Vagrant and Ansible as described in [Assignment 2 Instructions](./a2-instructions.md).
```bash
vagrant up 
ansible-playbook -u vagrant -i 192.168.56.100, ./playbooks/finalization.yml --private-key .vagrant/machines/ctrl/virtualbox/private_key
```
Now you need to configure your `kubectl` to connect to the cluster. You can do this by setting the `KUBECONFIG` environment variable to point to the `kubeconfig` file in the repository:
```bash
# Make sure you are in the root of the 'operation' directory
export KUBECONFIG=$(pwd)/kubeconfig
```

## Deployment Step 1: Option B: Minikube Cluster
Best for quick testing on your personal machine.

1.  **Start Minikube:**
    ```bash
    minikube start \
    --driver=docker \
    --memory=4096 \
    --cpus=3
    ```
    Note: You can adjust memory and CPU based on your system capabilities. This is the minimum recommended for smooth operation.
    Note: For this driver to work, ensure Docker Desktop is running on your host machine.

2.  **Install Istio:**
    ```bash
    istioctl install --set profile=demo -y
    kubectl label namespace default istio-injection=enabled
    ```


## Deployment Step 1: Option C: Minikube Cluster with Shared Folder (VirtualBox Driver)

If you want to use Minikube with a shared VirtualBox folder across all VMs you can follow these steps. This option will not work on MacBook's with Apple Silicon chips.

Start the Minikube cluster using the command below. You can adjust resources with flags such as `--cpus=8` and `--memory=16384`.
```
minikube start --driver=virtualbox
```

Stop the minikube cluster:
```
minikube stop
```

Create a shared folder:
```
mkdir -p ~/k8s-shared/models
mkdir -p ~/k8s-shared/output
```

Add the folder to the VM:
```
VBoxManage sharedfolder add "minikube" \
  --name shared \
  --hostpath "$HOME/k8s-shared" \
  --automount
```

Start the minikube cluster again:
```
minikube start
```

Mount the folder in the VM:
```
minikube ssh "sudo mkdir -p /mnt/shared && \
  echo 'shared /mnt/shared vboxsf defaults 0 0' | \
  sudo tee -a /etc/fstab && \
  sudo systemctl daemon-reload && \
  sudo mount -a"
```

Verify the mount:
```
minikube ssh "ls -la /mnt/shared"
```

---

## Deployment Step 2: Deploy secrets
The assignments ask for pre-deployed secrets. They are used in model-service, Grafana and Alertmanager. You have to create them before installing the chart.
```bash
kubectl create secret generic smtp-credentials \
  --from-literal=SMTP_USER="user" \
  --from-literal=SMTP_PASS="password"

kubectl create secret generic alertmanager-smtp-secret \
  --from-literal=SMTP_USER="doda.team9@gmail.com" \
  --from-literal=SMTP_PASS="gmmu jedd hfrl ftyh"

kubectl create secret generic grafana-admin-secret \
  --from-literal=admin-user="user" \
  --from-literal=admin-password="password"
```

---

## Deployment Step 3: Helm
We use a single Helm chart to deploy the Application, Model Service, Prometheus, Grafana, and AlertManager.

### 1. Quick Install
```bash
    cd operation/helm-chart
    helm dependency update
    cd ..
    helm install sms-checker ./helm-chart
```
### 

> **_Important! For Option A: Production Cluster (Vagrant VMs) Resource-Optimized Sidecar Injection_**  
> 
> Running a full observability stack alongside 5 microservices pushes the memory limits of our Vagrant VMs. A standard "Rolling Restart" temporarily duplicates pods, causing an Out-Of-Memory (OOM) Deadlock where new pods hang in Pending.
To solve this without adding hardware, we use a "Cold Swap" strategy: we stop the applications to free up RAM before enabling Istio, ensuring a clean startup.
> 
> Run these steps to inject sidecars safely:
> 1. Wait for stable state
> ```bash
> kubectl wait --for=condition=available deployment --all --timeout=300s
> ```
> 2. Scale down: Free up RAM to prevent Deadlock2. Scale down: Free up RAM to prevent Deadlock
> ```bash
> kubectl scale deployment app-deployment-v1 app-deployment-v2 model-deployment-v1 model-deployment-v2 model-deployment-v3 --replicas=0
> ```
> 3. Enable Istio Injection
> ```bash
> kubectl label namespace default istio-injection=enabled --overwrite
> ```
> 4. Scale up: Restart with Sidecars injected
> ```bash
> kubectl scale deployment app-deployment-v1 app-deployment-v2 model-deployment-v1 model-deployment-v2 model-deployment-v3 --replicas=1
> ```

### 2. Custom Configuration
You can override default values during installation using `--set` or a custom values file.

| Parameter | Description | Default |
| :--- | :--- | :--- |
| `app.replicas` | Number of frontend pods | `3` |
| `modelService.replicas` | Number of backend pods | `2` |
| `ingress.enabled` | Enable external access | `true` |
| `ingress.host` | Hostname for the app | `sms-checker.local` |

For example:
```bash
helm install sms-checker ./helm-chart --set app.replicas=5 --set ingress.host=myapp.local
```

### 3. Verify
```bash
helm status sms-checker
kubectl get pods
# Expected: App, Model, Prometheus, Grafana, AlertManager pods all 'Running'
```

### 4. Access Application

#### Sms Checker App
To access the application via the hostname `sms-checker.local`, we need to map the hostname to cluster's Ingress IP.

**For Vagrant Cluster:** Map the hostnames to the Ingress Controller's fixed IP (`192.168.56.95`).
```bash
echo "192.168.56.95 sms-checker.local" | sudo tee -a /etc/hosts
echo "192.168.56.95 stable.sms-checker.local" | sudo tee -a /etc/hosts
echo "192.168.56.95 canary.sms-checker.local" | sudo tee -a /etc/hosts
``` 
Open [http://sms-checker.local/sms/](http://sms-checker.local/sms/) in your browser.

Alternatively, you can connect directly to the stable version [http://stable.sms-checker.local/sms/](http://stable.sms-checker.local/sms/), or the canary version [http://canary.sms-checker.local/sms/](http://canary.sms-checker.local/sms/).

**For Minikube:** Map the hostnames to `127.0.0.1` and use port-forwarding.
```bash
echo "127.0.0.1 sms-checker.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 stable.sms-checker.local" | sudo tee -a /etc/hosts
echo "127.0.0.1 canary.sms-checker.local" | sudo tee -a /etc/hosts
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80
```
Open [http://sms-checker.local:8080/sms](http://sms-checker.local:8080/sms) in your browser.

Alternatively, you can connect directly to the stable version [http://stable.sms-checker.local:8080/sms/](http://stable.sms-checker.local:8080/sms/), or the canary version [http://canary.sms-checker.local:8080/sms/](http://canary.sms-checker.local:8080/sms/).

Instructions for using custom hostnames can be found in the [A4 instructions file](a4-instructions.md).

#### Optional - Kubernetes Dashboard (Only Vagrant Cluster)
To access the Kubernetes Dashboard, first retrieve the access token:
```bash
vagrant ssh ctrl
kubectl -n kubernetes-dashboard create token admin-user
exit
```
```bash
echo "192.168.56.99 dashboard.local" | sudo tee -a /etc/hosts
```
Now you can access the Kubernetes Dashboard at [https://dashboard.local](https://dashboard.local). 

--- 

## Monitoring - Prometheus, Grafana and Alerting
The monitoring stack is installed automatically.

## Prometheus
- Command: `kubectl port-forward svc/prometheus-prometheus 9090:9090`
- Access: [http://localhost:9090/prometheus](http://localhost:9090)

We collect the following metrics from the app:

| Metric Name | Type | Description |
| :--- | :--- | :--- |
| `sms_requests_total` | **Counter** | Total SMS prediction requests. |
| `predictions_result_total`| **Counter** | Breakdown by result (`spam`/`ham`). |
| `active_users` | **Gauge** | Currently active users. |
| `request_duration` | **Histogram** | Processing time distribution. |
| `sms_length` | **Histogram** | Character length distribution. |

## Grafana
- Command: `kubectl port-forward svc/sms-checker-grafana 3000:80`
- Access: [http://localhost:3000](http://localhost:3000)
- Credentials: User: `user` | Pass: `password`

Dashboards:
1. Login to Grafana.
2. Navigate to Dashboards in the side menu.
3. Select SMS Checker - Application Metrics for stable version metrics
4. Select SMS Checker - A/B Testing for metrics used for Continuous Experimentation.

**To make changes to the dashboards:**

1. Make the changes in the `.json` files from `helm-chart/dashboards/`
2. Run the following commands:
    ```
    helm upgrade sms-checker ./helm-chart

    kubectl delete pod $(kubectl get pod | grep grafana | awk '{print $1}')

    kubectl port-forward svc/sms-checker-grafana 3000:80     
    ```
3. Refresh Grafana website.

## AlertManager
We use AlertManager to send emails if traffic exceeds 15 requests/minute for 2 minutes.

1. Deploy Secrets according to instructions above
2. Update your deployment with the recipient email.
```bash
helm upgrade sms-checker ./helm-chart \
    --set alertmanager.recipient="your-email@example.com"
```
3. Forward port:
```bash
kubectl port-forward svc/prometheus-alertmanager 9093:9093
```
4. Access: [http://localhost:9093](http://localhost:9093)
5. Trigger an Alert (Test)
   Run this loop to generate artificial traffic spikes:
```bash
for i in {1..100}; do
  curl -X POST http://sms-checker.local/sms/ \
    -H "Host: sms-checker.local" \
    -H "Content-Type: application/json" \
    -d '{"sms":"Alert test"}'
  echo "Request $i sent"
  sleep 0.2
done
```
3. Verify
- Prometheus: Check Alerts tab > HighRequestRate should turn Pending to Firing (in appx. 1 minute).
- Email: Check the inbox of the recipient address configured above.

---
## ⚠️ Troubleshooting: Helm Upgrade & Istio Sidecars

### The Problem: "Pre-upgrade hooks failed"
When running `helm upgrade`, you may encounter the following error:
```text
Error: UPGRADE FAILED: pre-upgrade hooks failed: resource not ready, name: prometheus-admission-create, kind: Job... context deadline exceeded
```

1. Delete the stuck job (if it exists)
```
kubectl delete job -l app.kubernetes.io/name=kube-prometheus-stack-admission-create
```
2. Run the upgrade with webhooks disabled
```
helm upgrade sms-checker ./helm-chart \
  --set alertmanager.smtp.password="gmmu jedd hfrl ftyh" \
  --set alertmanager.recipient="YOUR_EMAIL" \
  --set kube-prometheus-stack.prometheusOperator.admissionWebhooks.enabled=false
```
---
