# Assignment 3: Kubernetes Deployment & Monitoring

This guide covers the deployment of the full application stack (App, Model, Monitoring, Alerting) using **Helm**. It is designed to work on both the provisioned Vagrant cluster and local Minikube environments.

## Prerequisites
You can either run this using Minikube or on the custom cluster deployed in previous assignment.


================= Need Help=================
---

## One-Time Setup of the kubernetes cluster (Assignment 3)

Create a shared folder:
```
mkdir -p ~/k8s-shared/models
```

Add the folder to the VM:
```
VBoxManage sharedfolder add "minikube" \
  --name shared \
  --hostpath /home/<your-user>/k8s-shared \
  --automount
```

Start the minikube cluster:
```
minikube start --driver=virtualbox
```

Mount the folder in the VM (commands are to be run inside the VM):
```
minikube ssh
sudo mkdir -p /mnt/shared
sudo mount -t vboxsf shared /mnt/shared
exit
```

Then enable the ingress addon:
```
minikube addons enable ingress
```

To start the app and model-service or apply changes using kubernetes, run:

```
kubectl apply -f k8s -R
```

## Start the Kubernetes cluster
Start the minikube cluster:
```
minikube start --driver=virtualbox
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


================== END OF NEED HELP ================
---

## Deployment (Helm)
We use a single Helm chart to deploy the Application, Model Service, Prometheus, Grafana, and AlertManager.

## 1. Quick Install
```bash
cd operation
helm install sms-checker ./helm-chart
```

## 2. Custom Configuration
You can override default values during installation using `--set` or a custom values file.

| Parameter | Description | Default |
| :--- | :--- | :--- |
| `app.replicas` | Number of frontend pods | `3` |
| `modelService.replicas` | Number of backend pods | `2` |
| `ingress.enabled` | Enable external access | `true` |
| `ingress.host` | Hostname for the app | `sms-checker.local` |
| `secret.smtpUser` | SMTP Username for alerts | `placeholder` |

For example:
```bash
helm install sms-checker ./helm-chart --set app.replicas=5 --set ingress.host=myapp.local
```

## 3. Verify
```bash
helm status sms-checker
kubectl get pods
# Expected: App, Model, Prometheus, Grafana, AlertManager pods all 'Running'
```

---

## Accessing the Application & Monitoring
You need to port-forward ingress controller to access the app and monitoring tools.
```bash
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80
```
**Keep this terminal open!!!**

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
- Credentials: User: `admin` | Pass: `admin123`

Dashboards:
1. Login to Grafana.
2. Navigate to Dashboards in the side menu.
3. Select SMS Checker - Application Metrics for stable version metrics
4. Select SMS Checker - A/B Testing for metrics used for Continuous Experimentation.

## AlertManager
We use AlertManager to send emails if traffic exceeds 15 requests/minute for 2 minutes.

1. Configure Credentials
   Update your deployment with the SMTP credentials.
```bash
helm upgrade sms-checker ./helm-chart \
--set alertmanager.smtp.password="gmmu jedd hfrl ftyh" \
--set alertmanager.recipient="your-email@example.com"
```
2. Trigger an Alert (Test)
   Run this loop to generate artificial traffic spikes:
```bash
# Send 500 requests (approx 2 req/sec)
for i in {1..500}; do
curl -X POST http://localhost:8080/sms/ \
-H "Host: sms-checker.local" \
-H "Content-Type: application/json" \
-d '{"sms":"Alert test"}'
sleep 0.5
done
```
3. Verify
- Prometheus:Check Alerts tab > HighRequestRate should turn Pending to Firing.
- Email: Check the inbox of the recipient address configured above.