# React UI Pipeline Templates

Reusable GitHub Actions workflows and composite actions for building, testing, and deploying React applications.

## 📁 Structure

```
React/
├── actions/
│   ├── setup/          # Setup Node.js and dependencies
│   ├── build/          # Build React application
│   ├── test/           # Run tests with coverage
│   ├── lint/           # ESLint and Prettier checks
│   └── deploy/         # Deploy to various platforms
└── workflows/
    ├── build.yml       # Build and test workflow
    ├── deploy.yml      # Deployment workflow
    └── react-pipeline.yml  # Complete CI/CD pipeline
```

## 🚀 Quick Start

### Using the Complete Pipeline

```yaml
name: CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [development, staging, production]
      action:
        type: choice
        options: [build, deploy, build-and-deploy]

jobs:
  pipeline:
    uses: bridan234/PipelineTemplates/React/workflows/react-pipeline.yml@main
    with:
      node-version: '20.x'
      package-manager: 'npm'
      run-tests: true
      run-lint: true
    secrets: inherit
```

### Build & Test Only

```yaml
jobs:
  build:
    uses: bridan234/PipelineTemplates/React/workflows/build.yml@main
    with:
      node-version: '20.x'
      package-manager: 'npm'
      working-directory: './'
      run-tests: true
      collect-coverage: true
      coverage-threshold: '80'
```

### Deploy to AWS S3 + CloudFront

```yaml
jobs:
  deploy:
    uses: bridan234/PipelineTemplates/React/workflows/deploy.yml@main
    with:
      environment: production
      deployment-type: 's3'
      s3-bucket: 'my-app-production'
      cloudfront-distribution-id: 'E1234567890ABC'
      env-file: '.env.production'
      public-url: 'https://myapp.com'
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

## 🔧 Actions

### Setup Action

Sets up Node.js environment and installs dependencies with caching.

```yaml
- uses: bridan234/PipelineTemplates/React/actions/setup@main
  with:
    node-version: '20.x'
    package-manager: 'npm'  # npm, yarn, or pnpm
    working-directory: './'
```

**Inputs:**
- `node-version` - Node.js version (default: latest LTS)
- `package-manager` - npm, yarn, or pnpm (default: npm)
- `working-directory` - Working directory (default: ./)
- `cache-dependency-path` - Path to lock file (default: **/package-lock.json)

### Build Action

Builds React application with environment variables and optimization.

```yaml
- uses: bridan234/PipelineTemplates/React/actions/build@main
  with:
    package-manager: 'npm'
    build-script: 'build'
    output-directory: 'build'
    env-file: '.env.production'
    public-url: 'https://myapp.com'
    generate-sourcemap: 'false'
```

**Inputs:**
- `package-manager` - npm, yarn, or pnpm (default: npm)
- `build-script` - Build script name (default: build)
- `output-directory` - Build output directory (default: build)
- `env-file` - Environment file to use
- `public-url` - PUBLIC_URL for the application
- `generate-sourcemap` - Generate source maps (default: false)
- `node-env` - NODE_ENV value (default: production)

### Test Action

Runs tests with coverage reporting and threshold checking.

```yaml
- uses: bridan234/PipelineTemplates/React/actions/test@main
  with:
    package-manager: 'npm'
    coverage: 'true'
    coverage-threshold: '80'
```

**Inputs:**
- `package-manager` - npm, yarn, or pnpm
- `test-script` - Test script name (default: test)
- `coverage` - Collect code coverage (default: true)
- `coverage-threshold` - Minimum coverage percentage (default: 80)
- `max-workers` - Maximum number of workers (default: 50%)

### Lint Action

Runs ESLint, Prettier, and TypeScript type checking.

```yaml
- uses: bridan234/PipelineTemplates/React/actions/lint@main
  with:
    package-manager: 'npm'
    lint-script: 'lint'
    format-check: 'true'
```

**Inputs:**
- `package-manager` - npm, yarn, or pnpm
- `lint-script` - Lint script name (default: lint)
- `format-check` - Check formatting with Prettier (default: true)
- `fix` - Auto-fix issues (default: false)

### Deploy Action

Deploys React application to various platforms.

```yaml
- uses: bridan234/PipelineTemplates/React/actions/deploy@main
  with:
    deployment-type: 's3'
    build-directory: 'build'
    s3-bucket: 'my-app-bucket'
    cloudfront-distribution-id: 'E1234567890ABC'
```

**Supported Platforms:**
- AWS S3 + CloudFront
- Azure Blob Storage + CDN
- Netlify
- Vercel
- Cloudflare Pages
- GitHub Pages

## 📦 Deployment Examples

### AWS S3 with CloudFront

```yaml
jobs:
  deploy:
    uses: bridan234/PipelineTemplates/React/workflows/deploy.yml@main
    with:
      environment: production
      deployment-type: 's3'
      s3-bucket: 'my-react-app-prod'
      cloudfront-distribution-id: 'E1234567890ABC'
      public-url: 'https://app.example.com'
    secrets:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Required Secrets:**
- `aws-access-key-id` - AWS Access Key ID
- `aws-secret-access-key` - AWS Secret Access Key

Or use OIDC:
- `aws-role-arn` - AWS IAM Role ARN

### Azure Blob Storage with CDN

```yaml
jobs:
  deploy:
    uses: bridan234/PipelineTemplates/React/workflows/deploy.yml@main
    with:
      environment: production
      deployment-type: 'azure-blob'
      azure-storage-account: 'myappstorage'
      azure-cdn-profile: 'myapp-cdn'
      azure-cdn-endpoint: 'myapp-endpoint'
    secrets:
      azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
      azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
      azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

**Required Secrets:**
- `azure-client-id` - Azure Client ID
- `azure-tenant-id` - Azure Tenant ID
- `azure-subscription-id` - Azure Subscription ID

### Netlify

```yaml
jobs:
  deploy:
    uses: bridan234/PipelineTemplates/React/workflows/deploy.yml@main
    with:
      environment: production
      deployment-type: 'netlify'
      netlify-site-id: 'my-site-id'
    secrets:
      netlify-auth-token: ${{ secrets.NETLIFY_AUTH_TOKEN }}
```

**Required Secrets:**
- `netlify-auth-token` - Netlify authentication token

### Vercel

```yaml
jobs:
  deploy:
    uses: bridan234/PipelineTemplates/React/workflows/deploy.yml@main
    with:
      environment: production
      deployment-type: 'vercel'
      vercel-org-id: 'my-org-id'
      vercel-project-id: 'my-project-id'
    secrets:
      vercel-token: ${{ secrets.VERCEL_TOKEN }}
```

**Required Secrets:**
- `vercel-token` - Vercel authentication token

### Cloudflare Pages

```yaml
jobs:
  deploy:
    uses: bridan234/PipelineTemplates/React/workflows/deploy.yml@main
    with:
      environment: production
      deployment-type: 'cloudflare-pages'
      cloudflare-account-id: 'my-account-id'
      cloudflare-project-name: 'my-project'
    secrets:
      cloudflare-api-token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

**Required Secrets:**
- `cloudflare-api-token` - Cloudflare API token

### GitHub Pages

```yaml
jobs:
  deploy:
    uses: bridan234/PipelineTemplates/React/workflows/deploy.yml@main
    with:
      environment: production
      deployment-type: 'github-pages'
      cname: 'myapp.com'  # Optional custom domain
    secrets: inherit
```

## 🔐 Required Repository Variables

Set these in your repository settings under Settings → Secrets and variables → Actions:

### Variables (Non-sensitive)
```
NODE_VERSION=20.x
PACKAGE_MANAGER=npm
WORKING_DIRECTORY=./

# Staging
STAGING_DEPLOYMENT_TYPE=s3
STAGING_S3_BUCKET=my-app-staging
STAGING_CLOUDFRONT_ID=E1234567890
STAGING_PUBLIC_URL=https://staging.myapp.com

# Production
PRODUCTION_DEPLOYMENT_TYPE=s3
PRODUCTION_S3_BUCKET=my-app-production
PRODUCTION_CLOUDFRONT_ID=E0987654321
PRODUCTION_PUBLIC_URL=https://myapp.com
```

### Secrets (Sensitive)
```
# AWS
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ROLE_ARN  # For OIDC

# Azure
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID

# Netlify
NETLIFY_AUTH_TOKEN

# Vercel
VERCEL_TOKEN

# Cloudflare
CLOUDFLARE_API_TOKEN

# Snyk (optional)
SNYK_TOKEN
```

## 🎯 Complete Example

### Multi-Environment Pipeline

```yaml
name: React CI/CD Pipeline

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment'
        required: true
        type: choice
        options:
          - staging
          - production
      action:
        type: choice
        options:
          - build
          - deploy
          - build-and-deploy

permissions:
  contents: write
  pull-requests: write
  id-token: write
  pages: write

jobs:
  build:
    if: github.event_name == 'pull_request' || github.event_name == 'push'
    uses: bridan234/PipelineTemplates/React/workflows/build.yml@main
    with:
      node-version: '20.x'
      package-manager: 'npm'
      run-tests: true
      run-lint: true
      collect-coverage: true
      coverage-threshold: '80'

  deploy-staging:
    if: github.event_name == 'push' && github.ref == 'refs/heads/develop'
    needs: [build]
    uses: bridan234/PipelineTemplates/React/workflows/deploy.yml@main
    with:
      environment: staging
      deployment-type: 's3'
      s3-bucket: ${{ vars.STAGING_S3_BUCKET }}
      cloudfront-distribution-id: ${{ vars.STAGING_CLOUDFRONT_ID }}
      env-file: '.env.staging'
      public-url: ${{ vars.STAGING_PUBLIC_URL }}
    secrets: inherit

  deploy-production:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    needs: [build]
    uses: bridan234/PipelineTemplates/React/workflows/deploy.yml@main
    with:
      environment: production
      deployment-type: 's3'
      s3-bucket: ${{ vars.PRODUCTION_S3_BUCKET }}
      cloudfront-distribution-id: ${{ vars.PRODUCTION_CLOUDFRONT_ID }}
      env-file: '.env.production'
      public-url: ${{ vars.PRODUCTION_PUBLIC_URL }}
    secrets: inherit
```

## 📊 Features

- ✅ **Multiple Package Managers** - npm, yarn, pnpm
- ✅ **Multi-Platform Deployment** - AWS, Azure, Netlify, Vercel, Cloudflare, GitHub Pages
- ✅ **Smart Caching** - Node modules and build artifacts
- ✅ **Code Quality** - ESLint, Prettier, TypeScript type checking
- ✅ **Testing** - Jest with coverage reports and thresholds
- ✅ **Security** - npm audit and Snyk scanning
- ✅ **Performance** - Lighthouse CI integration
- ✅ **Optimization** - Source maps, cache headers, CDN invalidation
- ✅ **Environment Management** - Multiple environments with approval gates
- ✅ **Deployment Verification** - Smoke tests and health checks

## 🔄 Workflow Outputs

### Build Workflow
- `build-version` - Application version from package.json
- `test-result` - Test result (passed/failed)
- `coverage-percentage` - Code coverage percentage

### Deploy Workflow
- `deployment-url` - URL of deployed application

## 🎨 Customization

### Custom Build Script

```yaml
- uses: bridan234/PipelineTemplates/React/actions/build@main
  with:
    build-script: 'build:prod'
    output-directory: 'dist'
```

### Custom Environment Variables

Create environment files:
- `.env.development`
- `.env.staging`
- `.env.production`

Reference in workflow:
```yaml
with:
  env-file: '.env.production'
```

### Custom Test Configuration

```yaml
- uses: bridan234/PipelineTemplates/React/actions/test@main
  with:
    test-script: 'test:ci'
    coverage-threshold: '90'
    max-workers: '2'
```

## 🚨 Troubleshooting

### Build Fails with Memory Error

Increase Node.js memory:
```yaml
env:
  NODE_OPTIONS: '--max-old-space-size=4096'
```

### Tests Fail in CI but Pass Locally

Ensure CI environment variable is set:
```yaml
env:
  CI: true
```

### Deployment Fails with Permission Error

Verify IAM permissions for AWS or Azure service principal permissions.

### Cache Not Working

Check `cache-dependency-path` matches your lock file:
- npm: `**/package-lock.json`
- yarn: `**/yarn.lock`
- pnpm: `**/pnpm-lock.yaml`

## 📖 Additional Resources

- [Create React App Documentation](https://create-react-app.dev/)
- [Vite Documentation](https://vitejs.dev/)
- [Next.js Documentation](https://nextjs.org/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Contributing

When contributing to these templates:

1. Test changes thoroughly with real React applications
2. Update documentation for any new features
3. Follow existing patterns and conventions
4. Ensure backward compatibility
5. Update examples in README

## 📝 License

MIT License - Use these templates freely in your projects!
