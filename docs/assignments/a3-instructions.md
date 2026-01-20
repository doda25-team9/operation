# Assignment 3: Kubernetes Deployment & Monitoring

This guide covers the deployment of the full application stack (App, Model, Monitoring, Alerting) using **Helm**. It is designed to work on both the provisioned Vagrant cluster and local Minikube environments.

## Prerequisites

| Component | Requirement |
| :--- | :--- |
| **Cluster** | Minikube (VirtualBox driver) OR Vagrant Cluster |
| **Tools** | `helm`, `kubectl`, `docker` |
| **Addons** | Ingress Controller (Required for access) |

---

## Cluster Setup (Minikube)

If you are using Minikube, follow these one-time setup steps. This includes the **Shared Storage** configuration required for the "Excellent" grade.

### 1. Configure Shared Storage
This allows the `model-service` to read models from your host machine.

```bash
# 1. Create host folder
mkdir -p ~/k8s-shared/models

# 2. Link to Minikube VM (VirtualBox)
VBoxManage sharedfolder add "minikube" --name shared --hostpath ~/k8s-shared --automount

# 3. Start Cluster
minikube start --driver=virtualbox

# 4. Mount inside VM
minikube ssh -- "sudo mkdir -p /mnt/shared && sudo mount -t vboxsf shared /mnt/shared"
```
### 2. Enable Ingress
```bash
minikube addons enable ingress
```

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