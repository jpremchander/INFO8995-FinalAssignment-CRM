# INFO8995 Final Assignment - Container Orchestration with Django CRM

This project demonstrates container orchestration by deploying [Django CRM](https://github.com/DjangoCRM/django-crm) with Docker Compose, CI/CD pipelines, and Kubernetes using Helm. The implementation covers all aspects of modern container orchestration including NFS storage, ingress, automation, and cloud-native deployment.

## 📋 Assignment Overview

**Course:** INFO8995 - Container Orchestration  


### Assignment Components

| Part | Component | Marks | Status |
|------|-----------|-------|--------|
| 1 | NFS Storage with TrueNAS | 
| 2 | Containerized Application |
| 3 | Cloudflare Tunnel Ingress |
| 4 | CI/CD to Container Registry |
| 5 | Helm via Kompose |

## 🏗 Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   TrueNAS NFS   │────│  Docker Compose  │────│  Cloudflare     │
│   Storage       │    │  Application     │    │  Tunnel         │
│                 │    │                  │    │                 │
│ 10.172.27.9     │    │ ┌──────────────┐ │    │ *.premchanderj  │
│ /mnt/mysql-data │    │ │ Django CRM   │ │    │ .me domains     │
└─────────────────┘    │ │ (Port 8080)  │ │    └─────────────────┘
                       │ └──────────────┘ │
                       │ ┌──────────────┐ │
                       │ │ MySQL 8      │ │
                       │ │ (NFS Volume) │ │
                       │ └──────────────┘ │
                       │ ┌──────────────┐ │
                       │ │ Adminer      │ │
                       │ │ (Port 8078)  │ │
                       │ └──────────────┘ │
                       └──────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose v2
- Access to TrueNAS server (10.172.27.9)
- Cloudflare account with tunnel configured
- Git repository (GitHub/Gitea)

### Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd INFO8995-FinalAssignment-CRM
   ```

2. **Configure settings:**
   ```bash
   cp django-crm/webcrm/settings.py .
   patch < patch-settings.diff
   ```

3. **Start the application:**
   ```bash
   ansible-playbook up.yml
   ```

4. **Initialize data:**
   ```bash
   docker compose exec crm python manage.py setupdata
   ```

5. **Access the application:**
   - Local: http://localhost:8080/en/456-admin/
   - Production: https://dev-codespace.premchanderj.me/en/456-admin/
   - Credentials: Username: `IamSUPER`, Password: `X99MQcYW`

## 📂 Project Structure

```
├── docker-compose.yml          # Main orchestration file
├── Dockerfile                  # Django CRM container image
├── settings.py                 # Django configuration (mounted)
├── Jenkinsfile                 # CI/CD pipeline
├── .github/workflows/          # GitHub Actions
├── helm/django-crm/           # Helm chart for Kubernetes
├── k8s/                       # Generated Kubernetes manifests
├── TROUBLESHOOTING.md         # Issue resolution documentation
└── django-crm/               # Upstream Django CRM source
```

## 🔧 Part 1: NFS Storage with TrueNAS

**Configuration:**
- **Server:** 10.172.27.9
- **Export Path:** /mnt/mysql-data
- **Mount Options:** nfsvers=3, proto=tcp, nolock, soft, rw

**Docker Compose Volume:**
```yaml
volumes:
  mysql_db_data:
    driver: local
    driver_opts:
      type: nfs
      o: "addr=10.172.27.9,nolock,soft,rw,proto=tcp,vers=3"
      device: ":/mnt/mysql-data"
```

**Key Features:**
- Persistent MySQL data storage on TrueNAS
- Network-attached storage for container data persistence
- Configured for high availability and data integrity

## 🐳 Part 2: Containerized Application

**Components:**
- **Django CRM:** Python 3.13 Alpine with mysqlclient
- **MySQL 8:** Database with persistent NFS storage
- **Adminer:** Database administration interface

**Dockerfile Highlights:**
```dockerfile
FROM python:3.13-alpine
# Runtime MySQL client library for Alpine
RUN apk add --no-cache mariadb-connector-c
# Build dependencies (removed after pip install)
RUN apk add --virtual .build-deps gcc musl-dev mariadb-connector-c-dev
```

**Key Achievements:**
- Resolved Alpine + mysqlclient compatibility issues
- Implemented proper layer caching for faster builds
- Production-ready container with health checks

## 🌐 Part 3: Cloudflare Tunnel Ingress

**Tunnel Configuration:**
- **Tunnel ID:** 5935aa3e-2bdf-4c1c-93d3-bebf6adf6edd
- **Primary Domain:** codespace.premchanderj.me → oauth2-proxy (port 4180)
- **Dev Domain:** dev-codespace.premchanderj.me → Django app (port 8080)

**DNS Routes:**
```bash
cloudflared tunnel route dns 5935aa3e-2bdf-4c1c-93d3-bebf6adf6edd dev-codespace.premchanderj.me
```

**Security Features:**
- OAuth2 proxy for authentication
- HTTPS termination at Cloudflare edge
- Django ALLOWED_HOSTS and CSRF protection configured

## 🔄 Part 4: CI/CD Pipeline

**Pipeline Features:**
- **Build:** Docker image build with multi-stage optimization
- **Test:** Container health checks and Django deployment validation
- **Push:** Automated push to container registry on git push
- **Deploy:** Integration hooks for deployment automation

**Supported Platforms:**
- Jenkins (Jenkinsfile)
- GitHub Actions (.github/workflows/ci-cd.yml)
- Gitea Actions (compatible)

**Registry Integration:**
```yaml
environment:
  REGISTRY_URL: gitea.example.com
  REGISTRY_NAMESPACE: your-username
  IMAGE_NAME: django-crm
```

## ☸️ Part 5: Helm Chart via Kompose

**Generated Artifacts:**
- Kubernetes manifests from `kompose convert`
- Production-ready Helm chart with configurable values
- NFS PersistentVolume configuration
- Ingress and service mesh integration

**Helm Chart Features:**
```yaml
# values.yaml highlights
global:
  registry: "your-registry.com/username"
  tag: "latest"

crm:
  replicaCount: 1
  resources:
    requests: { memory: "256Mi", cpu: "250m" }
    limits: { memory: "512Mi", cpu: "500m" }

mysql:
  persistence:
    nfs:
      server: "10.172.27.9"
      path: "/mnt/mysql-data"
```

**Deployment Commands:**
```bash
# Install chart
helm install django-crm helm/django-crm

# Deploy to Kubernetes
kubectl get pods,svc,pvc

# Access application
kubectl port-forward svc/django-crm-crm 8080:8080
```

## 🛠 Configuration Details

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| MYSQL_ROOT_PASSWORD | Secret5555 | MySQL root access |
| MYSQL_DATABASE | crm_db | Application database |
| MYSQL_USER | crm_user | Application DB user |
| MYSQL_PASSWORD | crmpass | Application DB password |

### Network Ports

| Service | Port | Purpose |
|---------|------|---------|
| Django CRM | 8080 | Web application |
| MySQL | 3306 | Database server |
| Adminer | 8078 | DB admin interface |
| OAuth2 Proxy | 4180 | Authentication |

### Secret URL Prefixes

| Path | Purpose |
|------|---------|
| /en/456-admin/ | Django admin interface |
| /en/123/ | CRM application |
| /en/789-login/ | Login endpoints |

## 🧪 Testing & Validation

### Local Testing
```bash
# Health checks
curl -I http://localhost:8080/en/456-admin/  # Should return 302
curl -I http://localhost:8080/en/123/        # Should return 301

# Database connectivity
docker compose exec crm python manage.py check --database default

# Container status
docker compose ps
docker compose logs -f crm
```

### Production Testing
```bash
# HTTPS endpoints
curl -I https://dev-codespace.premchanderj.me/en/456-admin/
curl -I https://dev-codespace.premchanderj.me/en/123/

# DNS resolution
nslookup dev-codespace.premchanderj.me 8.8.8.8

# Tunnel validation
cloudflared tunnel ingress validate
```

### Kubernetes Testing
```bash
# Deploy to cluster
helm install test-crm helm/django-crm --dry-run --debug

# Validate resources
kubectl get all -l app.kubernetes.io/instance=test-crm

# Port forward and test
kubectl port-forward svc/test-crm-django-crm-crm 8080:8080
```

## 📊 Performance & Monitoring

### Resource Usage
- **Django CRM:** 256Mi memory, 250m CPU (requests)
- **MySQL:** 512Mi memory, 250m CPU (requests)
- **Storage:** 10Gi NFS volume for MySQL data

### Health Monitoring
- HTTP health checks on /admin/login/
- MySQL liveness probes with mysqladmin ping
- Container restart policies for high availability

## � Common Issues & Solutions

### Key Challenges Resolved

**1. Alpine + mysqlclient Compatibility**
- **Problem:** `ImportError: Error loading MySQLdb module: libmariadb.so.3: cannot open shared object file`
- **Solution:** Added `mariadb-connector-c` runtime package to Dockerfile
- **Fix:** `RUN apk add --no-cache mariadb-connector-c`

**2. Database Migration Conflicts**
- **Problem:** Duplicate column errors during Django migrations
- **Solution:** Reset MySQL volume to clear corrupted migration state
- **Fix:** `docker compose down -v && docker compose up -d`

**3. Cloudflared ALLOWED_HOSTS Rejection**
- **Problem:** HTTP 400 "DisallowedHost" errors on external domains
- **Solution:** Added tunnel domains to Django settings
- **Fix:** Updated `ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS` in settings.py

**4. Windows Docker + NFS Connectivity**
- **Problem:** NFS volumes not mounting on Windows Docker Desktop
- **Solution:** Moved to Ubuntu environment for proper NFS support
- **Recommendation:** Use Linux environment for NFS-based deployments

**5. YAML Syntax in Docker Compose**
- **Problem:** Invalid YAML quoting in volume configurations
- **Solution:** Proper string quoting for NFS options
- **Fix:** `o: "addr=10.172.27.9,nolock,soft,rw,proto=tcp,vers=3"`

For detailed troubleshooting guides, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## �🔐 Security Considerations

### Container Security
- Non-root user execution in containers
- Read-only root filesystem where possible
- Minimal base images (Alpine Linux)
- Regular security updates via CI/CD

### Network Security
- Cloudflare DDoS protection and WAF
- OAuth2 authentication for admin access
- Django CSRF protection enabled
- Database connections over internal Docker network

### Data Security
- Encrypted connections (HTTPS/TLS)
- Database passwords in Kubernetes secrets
- NFS with proper access controls
- Regular automated backups (recommended)

## 📝 Documentation & Support

### Issue Resolution
See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for:
- Common problems and solutions
- Docker build issues resolution
- Network connectivity debugging
- Database migration troubleshooting

### Deployment Guides
- **Development:** Local Docker Compose setup
- **Staging:** Kubernetes with minikube/k3s
- **Production:** Full Helm deployment with monitoring

## 🎯 Learning Outcomes Demonstrated

1. **Container Technologies:** Docker, Docker Compose, multi-stage builds
2. **Orchestration:** Kubernetes, Helm charts, service discovery
3. **Storage:** NFS integration, persistent volumes, data persistence
4. **Networking:** Ingress controllers, load balancing, service mesh
5. **CI/CD:** Automated pipelines, registry integration, deployment automation
6. **Security:** Authentication, authorization, network policies
7. **Monitoring:** Health checks, logging, observability

For assignment submission, include:
1. **TrueNAS Configuration:** NFS export settings and permissions
2. **Cloudflare Dashboard:** Tunnel configuration and DNS routes
3. **Application Access:** Working Django admin login page
4. **Kubernetes Dashboard:** Helm deployment with running pods
5. **CI/CD Pipeline:** Successful build and deployment logs


---

## 👥 Group 7

| Name | Student ID |
|------|------------|
| Prem Chander J | 9015480 |
| Rishi Patel | 8972657 |

**Course:** INFO8995 - Container Orchestration