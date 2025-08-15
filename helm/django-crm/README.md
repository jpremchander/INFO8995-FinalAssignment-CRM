# Helm Chart for Django CRM

This Helm chart deploys the Django CRM application with MySQL database to a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- A storage class that supports ReadWriteOnce volumes (or NFS for shared storage)

## Installing the Chart

1. **Add your registry details** (edit `values.yaml`):
   ```yaml
   global:
     registry: "your-gitea-hostname.com/your-username"
     tag: "latest"
   ```

2. **Install the chart**:
   ```bash
   # From the helm directory
   helm install my-crm ./django-crm
   
   # Or with custom values
   helm install my-crm ./django-crm -f my-values.yaml
   ```

3. **Access the application**:
   ```bash
   # Get the service URL
   kubectl get svc
   
   # Port forward for testing
   kubectl port-forward svc/my-crm-django-crm-crm 8080:8080
   ```

## Configuration

The following table lists the configurable parameters and their default values:

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.registry` | Container registry URL | `your-gitea-hostname.com/your-username` |
| `global.tag` | Image tag | `latest` |
| `global.pullPolicy` | Image pull policy | `IfNotPresent` |

### Django CRM Application

| Parameter | Description | Default |
|-----------|-------------|---------|
| `crm.enabled` | Enable CRM deployment | `true` |
| `crm.replicaCount` | Number of CRM replicas | `1` |
| `crm.service.type` | Service type | `ClusterIP` |
| `crm.service.port` | Service port | `8080` |
| `crm.ingress.enabled` | Enable ingress | `true` |
| `crm.ingress.hosts[0].host` | Hostname | `crm.example.com` |
| `crm.settings.allowedHosts` | Django ALLOWED_HOSTS | `["localhost", "127.0.0.1", "crm.example.com"]` |
| `crm.settings.debug` | Django DEBUG mode | `false` |

### MySQL Database

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mysql.enabled` | Enable MySQL deployment | `true` |
| `mysql.config.database` | Database name | `crm_db` |
| `mysql.config.user` | Database user | `crm_user` |
| `mysql.config.password` | Database password | `crmpass` |
| `mysql.persistence.enabled` | Enable persistent storage | `true` |
| `mysql.persistence.size` | Storage size | `10Gi` |
| `mysql.persistence.nfs.enabled` | Use NFS storage | `true` |
| `mysql.persistence.nfs.server` | NFS server IP | `10.172.27.9` |
| `mysql.persistence.nfs.path` | NFS path | `/mnt/mysql-data` |

## Examples

### Basic Installation

```bash
helm install crm ./django-crm
```

### Production Installation with Custom Values

Create `production-values.yaml`:

```yaml
global:
  registry: "registry.company.com/crm"
  tag: "v1.2.3"

crm:
  replicaCount: 3
  settings:
    allowedHosts:
      - "crm.company.com"
      - "crm-api.company.com"
    csrfTrustedOrigins:
      - "https://crm.company.com"
      - "https://crm-api.company.com"
    debug: false
  ingress:
    hosts:
      - host: crm.company.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: crm-tls
        hosts:
          - crm.company.com
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"

mysql:
  config:
    password: "super-secure-password"
    rootPassword: "super-secure-root-password"
  persistence:
    size: 50Gi
    storageClass: "fast-ssd"
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"
```

Install with:
```bash
helm install crm ./django-crm -f production-values.yaml
```

### Development Installation (No Persistence)

```bash
helm install crm ./django-crm \
  --set mysql.persistence.enabled=false \
  --set crm.settings.debug=true \
  --set crm.replicaCount=1
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade crm ./django-crm -f my-values.yaml

# Upgrade to new chart version
helm upgrade crm ./django-crm --version 0.2.0
```

## Uninstalling

```bash
# Remove the deployment
helm uninstall crm

# Also remove PVCs if needed
kubectl delete pvc -l app.kubernetes.io/instance=crm
```

## Troubleshooting

### Common Issues

1. **CRM pod failing to start**:
   ```bash
   kubectl logs deployment/crm-django-crm-crm
   kubectl describe pod <pod-name>
   ```

2. **Database connection issues**:
   ```bash
   kubectl logs deployment/crm-django-crm-mysql
   kubectl exec -it deployment/crm-django-crm-mysql -- mysql -u root -p
   ```

3. **NFS mount issues**:
   ```bash
   kubectl describe pv
   kubectl describe pvc
   ```

### Health Checks

```bash
# Check all pods
kubectl get pods

# Check services
kubectl get svc

# Check ingress
kubectl get ingress

# Port forward for testing
kubectl port-forward svc/crm-django-crm-crm 8080:8080
```

## Development

### Testing the Chart

```bash
# Dry run
helm install crm ./django-crm --dry-run --debug

# Template validation
helm template crm ./django-crm

# Lint the chart
helm lint ./django-crm
```

### Chart Structure

```
django-crm/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values
├── templates/
│   ├── _helpers.tpl        # Template helpers
│   ├── configmap.yaml      # Django settings
│   ├── crm-deployment.yaml # CRM application
│   ├── mysql-deployment.yaml # MySQL database
│   ├── mysql-pvc.yaml      # Persistent storage
│   ├── services.yaml       # Kubernetes services
│   └── ingress.yaml        # Ingress rules
└── README.md               # This file
```
