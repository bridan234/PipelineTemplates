# 🚀 CI/CD Pipeline Templates

Production-ready, modular GitHub Actions workflow templates for modern software development. Build, test, and deploy with confidence using industry-standard patterns.

## 📁 Repository Structure

```
PipelineTemplates/
├── Docker/             # Container build, scan, and multi-registry push
│   ├── actions/        # setup, build, push, scan
│   ├── workflows/      # build, push, scan, docker-pipeline
│   └── README.md
├── DotNet/             # .NET application pipelines
│   ├── actions/        # setup, restore, build, test, publish, deploy
│   ├── workflows/      # build, deploy, dotnet-pipeline
│   └── README.md
├── React/              # React UI application pipelines
│   ├── actions/        # setup, build, test, lint, deploy
│   ├── workflows/      # build, deploy, react-pipeline
│   └── README.md
├── Terraform/          # Infrastructure as Code pipelines
│   ├── AWS/            # AWS-specific Terraform
│   │   ├── actions/    # setup, init, validate, plan, apply
│   │   ├── workflows/  # validate, plan, apply, terraform-pipeline
│   │   └── README.md
│   ├── Azure/          # Azure-specific Terraform
│   │   ├── actions/    # setup, init, validate, plan, apply
│   │   ├── workflows/  # validate, plan, apply, terraform-pipeline
│   │   └── README.md
│   └── GCP/            # GCP-specific Terraform
│       ├── actions/    # setup, init, validate, plan, apply
│       ├── workflows/  # validate, plan, apply, terraform-pipeline
│       └── README.md
└── README.md
```

## 🎯 Quick Start

### Docker Applications

```yaml
jobs:
  build-and-push:
    uses: bridan234/PipelineTemplates/Docker/workflows/docker-pipeline.yml@main
    with:
      image-name: 'myapp'
      registry: 'dockerhub'
      platforms: 'linux/amd64,linux/arm64'
      enable-scanning: true
    secrets: inherit
```

### .NET Applications

```yaml
jobs:
  build-and-deploy:
    uses: bridan234/PipelineTemplates/DotNet/workflows/dotnet-pipeline.yml@main
    with:
      dotnet-version: '8.0.x'
      run-tests: true
      collect-coverage: true
    secrets: inherit
```

### React Applications

```yaml
jobs:
  build-and-deploy:
    uses: bridan234/PipelineTemplates/React/workflows/react-pipeline.yml@main
    with:
      node-version: '20.x'
      package-manager: 'npm'
      deployment-type: 's3'
    secrets: inherit
```

### Terraform (AWS/Azure/GCP)

```yaml
jobs:
  terraform:
    uses: bridan234/PipelineTemplates/Terraform/AWS/workflows/terraform-pipeline.yml@main
    with:
      terraform-version: '1.6.0'
      environment: 'production'
    secrets: inherit
```

## 📚 Available Templates

### 🐳 Docker Templates
Build, scan, and push multi-platform container images to multiple registries.

**Features:**
- Multi-stage builds with Buildx
- Multi-platform support (amd64, arm64)
- Multi-registry push (Docker Hub, GHCR, ECR, ACR)
- Security scanning (Trivy, Snyk, Grype)
- Build caching with GitHub Actions cache

**Supported Registries:**
- Docker Hub
- GitHub Container Registry (GHCR)
- Amazon ECR
- Azure Container Registry (ACR)

[📖 Docker Documentation](./Docker/README.md)

### 🔷 .NET Templates
Complete CI/CD pipelines for .NET applications with build, test, and deployment automation.

**Features:**
- Multi-version .NET SDK support
- NuGet package caching
- Code coverage with thresholds
- Azure deployment (App Service, Container Apps, Functions)
- Multi-environment support with approval gates

**Supported Deployments:**
- Azure App Service
- Azure Container Apps
- Azure Functions

[📖 .NET Documentation](./DotNet/README.md)

### ⚛️ React Templates
Build, test, and deploy React applications to multiple hosting platforms.

**Features:**
- Multi-package manager support (npm, yarn, pnpm)
- ESLint, Prettier, TypeScript checking
- Jest testing with coverage
- Lighthouse CI performance testing
- Security scanning (npm audit, Snyk)
- Multi-platform deployment

**Supported Platforms:**
- AWS S3 + CloudFront
- Azure Blob Storage + CDN
- Netlify
- Vercel
- Cloudflare Pages
- GitHub Pages

[📖 React Documentation](./React/README.md)

### 🏗️ Terraform Templates
Infrastructure as Code pipelines with validation, planning, and deployment automation.

**Features:**
- Multi-cloud support (AWS, Azure, GCP)
- Terraform state management
- Plan validation and review
- Approval gates for production
- State locking (DynamoDB, Azure Storage, GCS)
- Cost estimation integration ready

**Supported Clouds:**
- AWS (S3 backend, DynamoDB locking)
- Azure (Storage Account backend)
- GCP (GCS backend)

[📖 Terraform AWS Documentation](./Terraform/AWS/README.md)  
[📖 Terraform Azure Documentation](./Terraform/Azure/README.md)  
[📖 Terraform GCP Documentation](./Terraform/GCP/README.md)

## 🎨 Template Architecture

### Design Principles

1. **Modular Design**: Each template consists of:
   - **Composite Actions**: Reusable steps (e.g., setup, build, test)
   - **Reusable Workflows**: Complete jobs with inputs/outputs
   - **Pipeline Workflows**: Full CI/CD orchestration

2. **Industry Standard Pattern**: Direct action references
   ```yaml
   uses: bridan234/PipelineTemplates/{Technology}/actions/{action}@main
   ```

3. **No Artifact Overhead**: Templates use direct references instead of checkout/artifact patterns for 5-10 second faster execution per job

4. **Flexibility**: Choose your level of abstraction:
   - Use complete pipelines for quick setup
   - Use reusable workflows for customization
   - Use composite actions for maximum control

### Usage Patterns

#### Pattern 1: Complete Pipeline (Easiest)
```yaml
jobs:
  pipeline:
    uses: bridan234/PipelineTemplates/React/workflows/react-pipeline.yml@main
    with:
      node-version: '20.x'
    secrets: inherit
```

#### Pattern 2: Reusable Workflows (Flexible)
```yaml
jobs:
  build:
    uses: bridan234/PipelineTemplates/React/workflows/build.yml@main
    with:
      run-tests: true
  
  deploy:
    needs: build
    uses: bridan234/PipelineTemplates/React/workflows/deploy.yml@main
    with:
      environment: production
```

#### Pattern 3: Composite Actions (Maximum Control)
```yaml
jobs:
  custom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: bridan234/PipelineTemplates/React/actions/setup@main
        with:
          node-version: '20.x'
      
      - uses: bridan234/PipelineTemplates/React/actions/build@main
        with:
          build-script: 'build:prod'
      
      - name: Custom Step
        run: echo "Add your custom logic here"
```

## 🔐 Security & Best Practices

### Authentication Methods

**AWS:**
- ✅ OIDC (recommended)
- ✅ Access Keys

**Azure:**
- ✅ OIDC with Service Principal (recommended)
- ✅ Service Principal with secrets

**GCP:**
- ✅ Workload Identity Federation (recommended)
- ✅ Service Account JSON key

### Secret Management

Store secrets in:
- **Repository Secrets**: `Settings → Secrets and variables → Actions → Secrets`
- **Environment Secrets**: For environment-specific credentials
- **Organization Secrets**: For shared credentials across repos

Example secrets:
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
DOCKER_USERNAME
DOCKER_PASSWORD
```

### Variables

Store non-sensitive configuration in:
- **Repository Variables**: `Settings → Secrets and variables → Actions → Variables`

Example variables:
```
NODE_VERSION=20.x
DOTNET_VERSION=8.0.x
TERRAFORM_VERSION=1.6.0
AWS_REGION=us-east-1
```

## 🎯 Common Use Cases

### Multi-Environment Deployment

```yaml
jobs:
  deploy-staging:
    if: github.ref == 'refs/heads/develop'
    uses: bridan234/PipelineTemplates/DotNet/workflows/deploy.yml@main
    with:
      environment: staging
      app-name: ${{ vars.STAGING_APP_NAME }}
    secrets: inherit

  deploy-production:
    if: github.ref == 'refs/heads/main'
    uses: bridan234/PipelineTemplates/DotNet/workflows/deploy.yml@main
    with:
      environment: production
      app-name: ${{ vars.PRODUCTION_APP_NAME }}
    secrets: inherit
```

### Monorepo with Multiple Projects

```yaml
jobs:
  api:
    uses: bridan234/PipelineTemplates/DotNet/workflows/build.yml@main
    with:
      working-directory: './src/api'
  
  web:
    uses: bridan234/PipelineTemplates/React/workflows/build.yml@main
    with:
      working-directory: './src/web'
  
  infrastructure:
    uses: bridan234/PipelineTemplates/Terraform/AWS/workflows/plan.yml@main
    with:
      working-directory: './infrastructure'
```

### Container + Infrastructure Deployment

```yaml
jobs:
  build-image:
    uses: bridan234/PipelineTemplates/Docker/workflows/build.yml@main
    with:
      image-name: 'myapp'
  
  deploy-infrastructure:
    needs: build-image
    uses: bridan234/PipelineTemplates/Terraform/AWS/workflows/apply.yml@main
    with:
      environment: 'production'
```

## 🚀 Getting Started

1. **Choose Your Template**: Select the template matching your technology stack

2. **Review Documentation**: Read the specific README for your chosen template

3. **Configure Secrets**: Set up required secrets and variables in your repository

4. **Create Workflow**: Add a workflow file to `.github/workflows/` in your project

5. **Test & Deploy**: Push changes and watch your pipeline run!

### Example: Setting Up a React App

```bash
# 1. Create workflow file
mkdir -p .github/workflows
cat > .github/workflows/ci-cd.yml << 'EOF'
name: CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
  workflow_dispatch:

jobs:
  pipeline:
    uses: bridan234/PipelineTemplates/React/workflows/react-pipeline.yml@main
    with:
      node-version: '20.x'
      package-manager: 'npm'
    secrets: inherit
EOF

# 2. Configure repository secrets (via GitHub UI)
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# 3. Configure repository variables (via GitHub UI)
# STAGING_S3_BUCKET=my-app-staging
# PRODUCTION_S3_BUCKET=my-app-production

# 4. Push and watch it work!
git add .github/workflows/ci-cd.yml
git commit -m "Add CI/CD pipeline"
git push
```

## 📖 Documentation

Each template includes comprehensive documentation:

- **README.md**: Overview, features, and examples
- **Action documentation**: Input/output specifications
- **Workflow examples**: Complete use cases
- **Troubleshooting**: Common issues and solutions

## 🤝 Contributing

Contributions are welcome! When contributing:

1. Follow existing patterns and conventions
2. Test changes with real projects
3. Update documentation
4. Ensure backward compatibility
5. Use direct action references (no artifact patterns)

## 📄 License

MIT License - Use these templates freely in your projects!

## 🆘 Support

For issues, questions, or suggestions:
- Open an issue in this repository
- Check template-specific README files
- Review GitHub Actions documentation

## 🔄 Version Management

### Recommended Usage

Use branch references for stability:
```yaml
uses: bridan234/PipelineTemplates/React/workflows/build.yml@main
```

Or pin to specific commits for maximum stability:
```yaml
uses: bridan234/PipelineTemplates/React/workflows/build.yml@a1b2c3d
```

### Breaking Changes

Major changes will be communicated via:
- GitHub Releases
- Updated documentation
- Migration guides

## ⭐ Features Overview

| Feature | Docker | .NET | React | Terraform |
|---------|--------|------|-------|-----------|
| **Multi-Platform** | ✅ | ✅ | ✅ | ✅ |
| **Security Scanning** | ✅ | ✅ | ✅ | ✅ |
| **Code Coverage** | ➖ | ✅ | ✅ | ➖ |
| **Caching** | ✅ | ✅ | ✅ | ✅ |
| **Multi-Environment** | ✅ | ✅ | ✅ | ✅ |
| **Approval Gates** | ➖ | ✅ | ✅ | ✅ |
| **Smoke Tests** | ➖ | ✅ | ✅ | ➖ |

## 🎓 Learn More

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Composite Actions](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)
- [Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [.NET DevOps](https://learn.microsoft.com/en-us/dotnet/architecture/devops-for-aspnet-developers/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
