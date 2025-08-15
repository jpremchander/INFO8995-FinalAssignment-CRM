# Kubernetes Deployment Guide

This guide covers deploying the Django CRM application to a Kubernetes cluster using the generated Helm chart.

## Quick Start

1. **Install Prerequisites**:
   ```bash
   # Install kubectl, helm, and kompose
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   curl -L https://github.com/kubernetes/kompose/releases/latest/download/kompose-linux-amd64 -o kompose
   ```

2. **Generate Manifests** (already done):
   ```bash
   # Convert docker-compose.yml to k8s manifests
   kompose convert -f docker-compose.yml -o k8s/
   ```

3. **Deploy with Helm**:
   ```bash
   # Update values in helm/django-crm/values.yaml first
   helm install crm helm/django-crm
   ```

## Cluster Options

### Option 1: k3s (Lightweight Kubernetes)

```bash
# Install k3s
curl -sfL https://get.k3s.io | sh -

# Copy kubeconfig
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER ~/.kube/config

# Test cluster
kubectl get nodes
```

### Option 2: minikube (Local Development)

```bash
# Install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start cluster
minikube start --driver=docker

# Enable ingress
minikube addons enable ingress
```

### Option 3: Kind (Kubernetes in Docker)

```bash
# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create cluster
kind create cluster --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```

## Storage Configuration

### NFS Storage (TrueNAS)

The Helm chart is pre-configured for NFS storage. Edit `values.yaml`:

```yaml
mysql:
  persistence:
    nfs:
      enabled: true
      server: "10.172.27.9"
      path: "/mnt/mysql-data"
```

### Local Storage

For local testing without NFS:

```yaml
mysql:
  persistence:
    nfs:
      enabled: false
    storageClass: "standard"  # or "local-path" for k3s
```

## Deployment Steps

1. **Update Configuration**:
   ```bash
   # Edit the Helm values
   nano helm/django-crm/values.yaml
   
   # Update registry and image details
   global:
     registry: "your-registry.com/your-username"
     tag: "latest"
   
   # Update ingress hostname
   crm:
     ingress:
       hosts:
         - host: crm.your-domain.com
   ```

2. **Deploy to Kubernetes**:
   ```bash
   # Create namespace (optional)
   kubectl create namespace crm-prod
   
   # Install with Helm
   helm install django-crm helm/django-crm -n crm-prod
   
   # Check deployment status
   kubectl get pods -n crm-prod
   kubectl get svc -n crm-prod
   ```

3. **Access the Application**:
   ```bash
   # Port forward for testing
   kubectl port-forward svc/django-crm-crm 8080:8080 -n crm-prod
   
   # Or via ingress (if configured)
   curl -I https://crm.your-domain.com/en/456-admin/
   ```

## Verification Commands

```bash
# Check all resources
kubectl get all -n crm-prod

# Check persistent volumes
kubectl get pv,pvc -n crm-prod

# Check pod logs
kubectl logs deployment/django-crm-crm -n crm-prod
kubectl logs deployment/django-crm-mysql -n crm-prod

# Execute commands in pods
kubectl exec -it deployment/django-crm-crm -n crm-prod -- python manage.py check
kubectl exec -it deployment/django-crm-mysql -n crm-prod -- mysql -u root -p
```

## Testing Database Migrations

```bash
# Run migrations manually
kubectl exec -it deployment/django-crm-crm -n crm-prod -- python manage.py migrate

# Create superuser
kubectl exec -it deployment/django-crm-crm -n crm-prod -- python manage.py setupdata

# Check Django admin
kubectl port-forward svc/django-crm-crm 8080:8080 -n crm-prod
# Open http://localhost:8080/en/456-admin/
```

## Cleanup

```bash
# Remove Helm deployment
helm uninstall django-crm -n crm-prod

# Remove persistent data (optional)
kubectl delete pvc -n crm-prod --all

# Remove namespace
kubectl delete namespace crm-prod
```

## Production Considerations

1. **Security**:
   - Use secrets for database passwords
   - Enable TLS/HTTPS
   - Set up network policies
   - Use non-root containers

2. **Scaling**:
   - Increase replica counts
   - Set up horizontal pod autoscaling
   - Use external database (cloud SQL)

3. **Monitoring**:
   - Deploy Prometheus/Grafana
   - Set up log aggregation
   - Configure alerting

4. **Backup**:
   - Schedule database backups
   - Test restore procedures
   - Document recovery processes

## Next Steps

After successful deployment:
- Set up CI/CD to automatically deploy new images
- Configure monitoring and alerting
- Set up proper TLS certificates
- Implement backup and disaster recovery
- Scale based on usage patterns
