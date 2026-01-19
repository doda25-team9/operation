# SMS Checker Operation Repository Team 9

Welcome to the **SMS Checker** project! This repository serves as the central hub for the infrastructure, deployment, and operation of our machine-learning-powered SMS spam detection system.

## Repository Structure

The project is split across four repositories:

| Repository                                                         | Description                                                                                           |
|:-------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------|
| **[operation](https://github.com/doda25-team9/operation)**         | **You are here.** Contains Infrastructure-as-Code (Ansible, Vagrant), Helm charts, and documentation. |
| **[app](https://github.com/doda25-team9/app)**                     | The Java Spring Boot frontend service.                                                                |
| **[model-service](https://github.com/doda25-team9/model-service)** | The Python Flask API serving the Machine Learning model.                                              |
| **[lib-version](https://github.com/doda25-team9/lib-version)**     | A shared Maven library for version management.                                                        |

Here is a reference architecture diagram illustrating the system components and their interactions:
![Architecture Diagram](./docs/images/reference_architecture.png)

---
## Prerequisites

Before starting, ensure you have the following installed on your host machine:

| Tool               | Version (Recommended) | Purpose                                    |
|:-------------------|:----------------------|:-------------------------------------------|
| **VirtualBox**     | 7.0+                  | Hypervisor for VMs (Required for Vagrant). |
| **Vagrant**        | 2.4+                  | VM management automation.                  |
| **Ansible**        | 2.16+                 | Configuration management.                  |
| **Helm**           | 3.x                   | Kubernetes package manager.                |
| **kubectl**        | 1.32+                 | Kubernetes command-line tool.              |
| **Minikube**       | Latest                | For local Kubernetes testing.              |
| **istioctl**       | 1.25.2+               | CLI for managing Istio Service Mesh.       |
| **Docker**         | 20.10+                | For local Docker Compose testing.          |
| **Docker Compose** | 2.0+                  | For local multi-container orchestration.   |

Moreover, please clone this repository and all related repositories to have the complete project setup. It should look like this:
```
your-folder/
    app/
    model-service/
    lib-version/
    operation/
```

---
## Deployment Guide

Choose one of the following deployment paths depending on your environment.

### Option A: Local Kubernetes (Minikube)
Best for quick testing on your personal machine.

1.  **Start Minikube:**
    ```bash
    minikube start --driver=docker
    minikube addons enable ingress
    ```
2.  **Install Istio:**
    ```bash
    istioctl install --set profile=demo -y
    kubectl label namespace default istio-injection=enabled
    ```
3.  **Deploy Application:**
    ```bash
    helm install sms-checker ./helm-chart
    ```
4.  **Access:**
    ADD THIS!!!!

### Option B: Production Cluster (Vagrant VMs)
Simulates a real-world bare-metal cluster with 3 VMs.

1.  **Provision Infrastructure:**
    Creates Controller + 2 Workers and installs K8s, MetalLB, Ingress, and Istio.
    ```bash
    # 1. Start VMs (approx. 5-10 mins)
    vagrant up

    # 2. Finalize setup (Installs MetalLB, Ingress, Dashboard, Istio)
    ansible-playbook -u vagrant -i 192.168.56.100, ./playbooks/finalization.yml --private-key .vagrant/machines/ctrl/virtualbox/private_key
    ```
2.  **Deploy Application:**
    ```bash
    export KUBECONFIG=$(pwd)/kubeconfig
    helm install sms-checker ./helm-chart
    ```
---
## Troubleshooting


---
## Secrets


---

## Dashboard & App Access Table

Once deployed, access the components using the addresses below.

**Important:** You must map the **Ingress IP** to these hostnames in your `/etc/hosts` file first (see *Host Configuration* below).

| Component | URL                                                  | Login / Details                                                                             |
| :--- |:-----------------------------------------------------|:--------------------------------------------------------------------------------------------|
| **Web Application** | [http://sms-checker.local](http://sms-checker.local) | Main user interface.                                                                        |
| **Kubernetes Dashboard** | [https://dashboard.local](https://dashboard.local)   | Token required (see *Credentials*).                                                         |
| **Grafana** | [http://localhost:3000](http://localhost:3000)       | **User:** `admin` <br> **Pass:** `admin123` <br> *(Requires port-forward)*. |
| **Prometheus** | [http://localhost:9090](http://localhost:9090)       | *(Requires port-forward)*.                                                                  |
| **AlertManager** | [http://localhost:9093](http://localhost:9093)                            | *(Requires port-forward)*.                                                                  |

---
## Monitoring & Metrics

We collect the following custom metrics:

| Metric Name | Type | Description |
| :--- | :--- | :--- |
| `sms_requests_total` | **Counter** | Total number of SMS prediction requests received. |
| `predictions_result_total` | **Counter** | Total predictions labeled by result (`spam` vs `ham`). |
| `active_users` | **Gauge** | Number of currently active users on the platform. |
| `request_duration` | **Histogram** | Distribution of request processing time (seconds). |
| `sms_length` | **Histogram** | Distribution of the character length of submitted SMS messages. |

---
## Documentation
The `\docs` folder contains additional documentation:
- `continuous-experimentation.md`
- `deployment.md`
- `extension.md`
- `\assignments` - folder that contains detailed instructions on testing each assignment.
