# CI/CD Setup Guide

This folder contains CI/CD pipeline configurations for building and pushing the Django CRM container image to a registry.

## Files

- **`Jenkinsfile`**: Jenkins pipeline for self-hosted Jenkins
- **`.github/workflows/ci-cd.yml`**: GitHub Actions workflow
- **`setup-registry.md`**: Instructions for configuring your container registry

## Quick Setup

### For Gitea + Jenkins

1. **Update Registry Settings**:
   Edit `Jenkinsfile` and update:
   ```groovy
   REGISTRY_URL = 'your-gitea-hostname.com'
   REGISTRY_NAMESPACE = 'your-username'
   ```

2. **Configure Jenkins Credentials**:
   - Go to Jenkins → Manage Jenkins → Credentials
   - Add new credential ID: `gitea-registry-creds`
   - Username: Your Gitea username
   - Password: Your Gitea access token

3. **Create Jenkins Pipeline**:
   - New Item → Pipeline
   - Pipeline → Definition: "Pipeline script from SCM"
   - Repository URL: Your Gitea repo URL
   - Script Path: `Jenkinsfile`

### For GitHub Actions

1. **Update Registry Settings**:
   Edit `.github/workflows/ci-cd.yml` and update:
   ```yaml
   REGISTRY_URL: your-gitea-hostname.com
   REGISTRY_NAMESPACE: your-username
   ```

2. **Add Repository Secrets**:
   - Go to GitHub repo → Settings → Secrets and variables → Actions
   - Add: `REGISTRY_USERNAME` (your Gitea username)
   - Add: `REGISTRY_PASSWORD` (your Gitea access token)

## Registry Configuration

### Gitea Container Registry

1. Enable container registry in Gitea:
   - Admin → Site Administration → Configuration → Packages
   - Enable "Container Registry"

2. Create access token:
   - User Settings → Applications → Generate New Token
   - Scopes: `read:packages`, `write:packages`

3. Test registry access:
   ```bash
   docker login your-gitea-hostname.com
   ```

## Pipeline Behavior

- **On push to `main`**: Builds and pushes with `latest` tag + build number
- **On push to `develop`**: Builds and pushes with branch tag
- **On pull requests**: Builds only (no push)

## Testing

After setup, test the pipeline:

1. Make a small change to your code
2. Commit and push to trigger the build
3. Check the pipeline logs
4. Verify the image appears in your registry

## Image Usage

Once built, update your `docker-compose.yml` to use the registry image:

```yaml
services:
  crm:
    image: your-gitea-hostname.com/your-username/django-crm:latest
    # Remove: build: .
```

## Next Steps

After CI/CD is working:
1. Set up automatic deployment triggers
2. Implement proper semantic versioning
3. Add security scanning to the pipeline
4. Set up monitoring and alerting
