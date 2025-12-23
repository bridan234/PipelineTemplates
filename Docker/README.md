# Docker Pipeline Templates

Reusable GitHub Actions workflows and composite actions for building, scanning, and pushing Docker containers with support for multiple container registries.

## Features

- 🏗️ **Multi-stage build support** - Build specific stages in multi-stage Dockerfiles
- 🌍 **Multi-platform builds** - Build for multiple architectures (AMD64, ARM64, etc.)
- 🔒 **Multi-registry support** - Push to Docker Hub, GHCR, ECR, ACR, and custom registries
- 🔍 **Security scanning** - Integrated vulnerability scanning with Trivy, Snyk, or Grype
- 💾 **Build caching** - GitHub Actions cache support for faster builds
- 📝 **SBOM & Provenance** - Generate Software Bill of Materials and build attestations
- ⚡ **Optimized workflows** - Efficient, reusable components

## Supported Registries

| Registry | Type | Input Value | Authentication |
|----------|------|-------------|----------------|
| Docker Hub | Public/Private | `dockerhub` | Username + Token |
| GitHub Container Registry | Public/Private | `ghcr` | Username + PAT |
| Amazon ECR | Private | `ecr` | AWS Credentials |
| Azure Container Registry | Private | `acr` | Service Principal |
| Custom | Any | `custom` | Username + Password |

## Quick Start

### Using Actions Directly

Reference actions from this template repository in your workflows:

```yaml
name: Docker CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Docker
        uses: bridan234/PipelineTemplates/Docker/actions/setup@main
        with:
          registry: ghcr
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build Image
        uses: bridan234/PipelineTemplates/Docker/actions/build@main
        with:
          image-name: ghcr.io/${{ github.repository }}
          tags: latest,${{ github.sha }}

      - name: Scan Image
        uses: bridan234/PipelineTemplates/Docker/actions/scan@main
        with:
          image-name: ghcr.io/${{ github.repository }}:latest
          scanner: trivy
          upload-sarif: true

      - name: Push Image
        if: github.event_name == 'push'
        uses: bridan234/PipelineTemplates/Docker/actions/push@main
        with:
          image-name: ghcr.io/${{ github.repository }}
          tags: latest,${{ github.sha }}
          registry: ghcr
```

### Using Reusable Workflows

Call the complete pipeline workflow:

```yaml
name: Docker CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  docker:
    uses: bridan234/PipelineTemplates/.github/workflows/docker-pipeline.yml@main
    with:
      image-name: ghcr.io/${{ github.repository }}
      tags: latest,${{ github.sha }}
      registry: ghcr
      enable-scan: true
      enable-push: ${{ github.event_name == 'push' }}
    secrets:
      registry-username: ${{ github.actor }}
      registry-password: ${{ secrets.GITHUB_TOKEN }}
```

## Actions

### Setup Action

Configures Docker and authenticates to container registries.

**Location:** `.github/actions/docker/setup`

**Inputs:**
- `registry` - Registry to use (dockerhub, ghcr, ecr, acr)
- `registry-url` - Custom registry URL (optional)
- `username` - Registry username
- `password` - Registry password/token
- `aws-region` - AWS region for ECR (default: us-east-1)
- `buildx-install` - Install Docker Buildx (default: true)
- `qemu-install` - Install QEMU for multi-platform (default: false)

**Example:**
```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/setup@main
  with:
    registry: ghcr
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

### Build Action

Builds Docker images with multi-stage and multi-platform support.

**Location:** `.github/actions/docker/build`

**Inputs:**
- `context` - Build context path (default: .)
- `dockerfile` - Path to Dockerfile (default: Dockerfile)
- `image-name` - Docker image name (required)
- `tags` - Comma-separated tags (default: latest)
- `build-args` - Newline-separated build arguments
- `target` - Target build stage
- `platforms` - Target platforms (default: linux/amd64)
- `cache-from` - Cache source (default: type=gha)
- `cache-to` - Cache destination (default: type=gha,mode=max)
- `load` - Load to Docker daemon (default: true)
- `push` - Push to registry (default: false)
- `provenance` - Generate provenance (default: false)
- `sbom` - Generate SBOM (default: false)

**Example:**
```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    image-name: myapp
    tags: latest,v1.0.0
    target: production
    platforms: linux/amd64,linux/arm64
    build-args: |
      NODE_ENV=production
      VERSION=1.0.0
```

### Push Action

Pushes Docker images to container registries.

**Location:** `.github/actions/docker/push`

**Inputs:**
- `image-name` - Docker image name (required)
- `tags` - Comma-separated tags to push (default: latest)
- `source-tag` - Source tag if retagging
- `registry` - Target registry (default: dockerhub)
- `registry-url` - Custom registry URL
- `additional-tags` - Additional tags to apply

**Example:**
```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/push@main
  with:
    image-name: myapp
    tags: latest,v1.0.0
    registry: ghcr
    additional-tags: sha-${{ github.sha }}
```

### Scan Action

Scans Docker images for vulnerabilities.

**Location:** `.github/actions/docker/scan`

**Inputs:**
- `image-name` - Image name with tag to scan (required)
- `scanner` - Scanner to use: trivy, snyk, grype (default: trivy)
- `severity` - Minimum severity (default: MEDIUM)
- `fail-on-severity` - Fail threshold (default: CRITICAL)
- `scan-type` - Type: vuln, config, secret, all (default: vuln)
- `output-format` - Format: table, json, sarif (default: table)
- `output-file` - Output file path
- `ignore-unfixed` - Ignore unfixed vulnerabilities (default: false)
- `upload-sarif` - Upload to GitHub Security (default: false)

**Example:**
```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/scan@main
  with:
    image-name: myapp:latest
    scanner: trivy
    severity: HIGH
    fail-on-severity: CRITICAL
    upload-sarif: true
```

## Workflows

### Build Workflow

Basic build-only workflow.

**Location:** `.github/workflows/build.yml`

**Usage:**
```yaml
jobs:
  build:
    uses: bridan234/PipelineTemplates/.github/workflows/docker-build.yml@main
    with:
      image-name: myapp
      tags: latest
      platforms: linux/amd64,linux/arm64
```

### Push Workflow

Push existing images to a registry.

**Location:** `.github/workflows/push.yml`

**Usage:**
```yaml
jobs:
  push:
    uses: bridan234/PipelineTemplates/.github/workflows/docker-push.yml@main
    with:
      image-name: myapp
      tags: latest,v1.0.0
      registry: ghcr
    secrets:
      registry-username: ${{ github.actor }}
      registry-password: ${{ secrets.GITHUB_TOKEN }}
```

### Scan Workflow

Security scanning workflow.

**Location:** `.github/workflows/scan.yml`

**Usage:**
```yaml
jobs:
  scan:
    uses: bridan234/PipelineTemplates/.github/workflows/docker-scan.yml@main
    with:
      image-name: myapp:latest
      scanner: trivy
      upload-sarif: true
```

### Complete Pipeline

Full build, scan, and push pipeline.

**Location:** `.github/workflows/docker-pipeline.yml`

**Usage:**
```yaml
jobs:
  pipeline:
    uses: bridan234/PipelineTemplates/.github/workflows/docker-pipeline.yml@main
    with:
      image-name: myapp
      tags: latest,${{ github.sha }}
      registry: ghcr
      enable-scan: true
      enable-push: true
      scanner: trivy
      fail-on-severity: HIGH
    secrets:
      registry-username: ${{ github.actor }}
      registry-password: ${{ secrets.GITHUB_TOKEN }}
```

## Common Use Cases

### Multi-Stage Build

Build only the production stage:

```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    image-name: myapp
    target: production
    dockerfile: Dockerfile
```

Example Dockerfile:
```dockerfile
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:18-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY package*.json ./
RUN npm install --production
CMD ["node", "dist/main.js"]
```

### Multi-Platform Build

Build for multiple architectures:

```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/setup@main
  with:
    buildx-install: true
    qemu-install: true

- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    image-name: myapp
    platforms: linux/amd64,linux/arm64,linux/arm/v7
    push: true  # Must push for multi-platform
```

### Push to Multiple Registries

```yaml
jobs:
  build:
    # ... build job

  push-dockerhub:
    needs: build
    uses: bridan234/PipelineTemplates/.github/workflows/docker-push.yml@main
    with:
      image-name: username/myapp
      registry: dockerhub
    secrets:
      registry-username: ${{ secrets.DOCKERHUB_USERNAME }}
      registry-password: ${{ secrets.DOCKERHUB_TOKEN }}

  push-ghcr:
    needs: build
    uses: bridan234/PipelineTemplates/.github/workflows/docker-push.yml@main
    with:
      image-name: ghcr.io/${{ github.repository }}
      registry: ghcr
    secrets:
      registry-username: ${{ github.actor }}
      registry-password: ${{ secrets.GITHUB_TOKEN }}
```

### Security Scanning with SARIF Upload

```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/scan@main
  with:
    image-name: myapp:latest
    scanner: trivy
    output-format: sarif
    output-file: trivy-results.sarif
    upload-sarif: true
```

This uploads results to GitHub Security → Code scanning alerts.

### Build with Secrets

```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    image-name: myapp
    secrets: |
      id=npm_token,env=NPM_TOKEN
      id=api_key,env=API_KEY
```

In your Dockerfile:
```dockerfile
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm install
```

## Registry-Specific Examples

### Docker Hub

```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/setup@main
  with:
    registry: dockerhub
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}

- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    image-name: username/myapp
    push: true
```

### GitHub Container Registry (GHCR)

```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/setup@main
  with:
    registry: ghcr
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}

- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    image-name: ghcr.io/${{ github.repository }}
    push: true
```

### Amazon ECR

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1

- uses: bridan234/PipelineTemplates/Docker/actions/setup@main
  with:
    registry: ecr
    aws-region: us-east-1

- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    image-name: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com/myapp
    push: true
```

### Azure Container Registry (ACR)

```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/setup@main
  with:
    registry: acr
    registry-url: myregistry.azurecr.io
    username: ${{ secrets.ACR_USERNAME }}
    password: ${{ secrets.ACR_PASSWORD }}

- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    image-name: myregistry.azurecr.io/myapp
    push: true
```

## Advanced Features

### Build Cache

Leverage GitHub Actions cache for faster builds:

```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    image-name: myapp
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Provenance & SBOM

Generate attestations for supply chain security:

```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    image-name: myapp
    provenance: true
    sbom: true
    push: true
```

### Dynamic Tagging

Create dynamic tags based on context:

```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    image-name: myapp
    tags: |
      latest
      ${{ github.ref_name }}
      sha-${{ github.sha }}
      ${{ github.run_number }}
```

## Security Best Practices

1. **Use specific base images** - Avoid `latest` tags in Dockerfile
2. **Scan regularly** - Enable scanning on every build
3. **Review SARIF results** - Check GitHub Security tab
4. **Use secrets properly** - Never commit credentials
5. **Multi-stage builds** - Reduce attack surface
6. **Run as non-root** - Add `USER` directive in Dockerfile
7. **Keep images small** - Use alpine or distroless base images

## Troubleshooting

### Build fails with "permission denied"

Ensure your workflow has proper permissions:
```yaml
permissions:
  contents: read
  packages: write  # For GHCR
```

### Multi-platform build is slow

Enable cache and QEMU:
```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/setup@main
  with:
    qemu-install: true
    
- uses: bridan234/PipelineTemplates/Docker/actions/build@main
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

### Scanner not finding vulnerabilities

Check scanner is configured correctly:
```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/scan@main
  with:
    scanner: trivy
    scan-type: all  # vuln, config, secret
    severity: LOW   # Report all severities
```

### Push fails with "unauthorized"

Verify authentication is configured before push:
```yaml
- uses: bridan234/PipelineTemplates/Docker/actions/setup@main
  with:
    registry: ghcr
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

## Contributing

Feel free to submit issues and enhancement requests!

## License

MIT License - see LICENSE file for details
