# Assignment 4: Istio Service Mesh
In this assignment we mostly focused on deploying our application and enabling us to conduct continuous experimentation.
You can read about the deployment process in the [Deployment File](../deployment.md).

If you already followed the setup instructions with Helm from [Assignment 3](./a3-instructions.md), you can directly proceed to the configuration options for Istio below.

## Configuration Options

### Accesing the application versions on custom hostnames

If you want to access the stable (v1) and canary (v2) versions on custom hostnames, change the following values in `/helm-chart/values.yaml`:
```yaml
  stableHost: stable.sms-checker.local
  canaryHost: canary.sms-checker.local
```

Then make sure to add both of them to `/etc/hosts` as follows.
**For Vagrant Cluster:** 
```bash
echo "192.168.56.95 <YOUR HOSTNAME HERE>" | sudo tee -a /etc/hosts
echo "192.168.56.95 <YOUR HOSTNAME HERE" | sudo tee -a /etc/hosts
```
 
**For Minikube:** 
```bash
echo "127.0.0.1 <YOUR HOSTNAME HERE>" | sudo tee -a /etc/hosts
echo "127.0.0.1 <YOUR HOSTNAME HERE" | sudo tee -a /etc/hosts
```

Then run:
```bash
helm upgrade sms-checker ./helm-chart
```

Alternatively, if you already installed the helm chart, you can set the hostnames like:
```bash
helm upgrade sms-checker ./helm-chart \
  --set istio.canary=<YOUR HOSTNAME HERE>

# Update /etc/hosts according to the IP you use to connect
echo "<192.168.56.95 OR 127.0.0.1> <YOUR HOSTNAME HERE>" | sudo tee -a /etc/hosts
```

### Adjust Traffic Split
```bash
# 95/5 split (more conservative)
helm upgrade sms-checker ./helm-chart \
  --set istio.trafficSplit.stable=95 \
  --set istio.trafficSplit.canary=5
```

### Disable Canary
```bash
helm upgrade sms-checker ./helm-chart \
  --set versions.v2.enabled=false

# Verify only v1 pods exist
kubectl get pods | grep deployment
```

---

## Documentation

### Deployment Overview
You can read about the deployment process in the [Deployment File](../deployment.md).

### Extension Proposal
You can read our extension proposal in the [Extension Proposal File](../extension.md).

### Continuous Experimentation
You can read about our continuous experimentation setup in the [Continuous Experimentation File](../continuous-experimentation.md).

### Additional Use Case - Shadow Launch
We deploy a third model-service version (v3) that receives mirrored copies of all traffic from both the stable (v1) and canary (v2) versions, allowing us to evaluate the shadow version's performance using real user requests without exposing users to its responses.
Users only see results from v1/v2 while v3 silently processes the same requests and records metrics for comparison.

