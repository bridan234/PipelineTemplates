# .NET CI/CD Pipeline Templates

Comprehensive GitHub Actions templates for .NET applications with Azure deployment support. These templates provide a complete CI/CD pipeline with pre/post hooks, approval gates, and best practices.

## 📁 Structure

```
DotNet/
├── actions/           # Reusable composite actions
│   ├── setup/        # Setup .NET SDK and Azure authentication
│   ├── restore/      # Restore NuGet packages
│   ├── build/        # Build .NET projects
│   ├── test/         # Run tests with code coverage
│   ├── publish/      # Publish applications for deployment
│   └── deploy/       # Deploy to Azure (App Service, Functions, Container Apps)
├── workflows/        # Reusable workflows
│   ├── build.yml     # Build and test workflow
│   ├── deploy.yml    # Deployment workflow
│   └── dotnet-pipeline.yml  # Main CI/CD pipeline
└── README.md         # This file
```

## 🚀 Quick Start

### 1. Copy Templates to Your Repository

```bash
# Option 1: Use as a template repository
gh repo create my-dotnet-app --template your-org/pipeline-templates

# Option 2: Copy the DotNet folder to your .github/workflows directory
cp -r DotNet/actions .github/actions/dotnet
cp -r DotNet/workflows .github/workflows/dotnet
```

### 2. Create Your Workflow

Create `.github/workflows/ci-cd.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
  workflow_dispatch:

jobs:
  setup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          repository: 'your-org/pipeline-templates'
          path: .pipeline-templates
      - uses: actions/upload-artifact@v4
        with:
          name: pipeline-templates-${{ github.run_id }}
          path: .pipeline-templates/DotNet/actions
          retention-days: 1

  build:
    needs: setup
    uses: ./.github/workflows/dotnet/build.yml
    with:
      environment: 'development'
      dotnet-version: '8.0.x'
      run-tests: true
      collect-coverage: true
      coverage-threshold: '80'
    secrets: inherit
```

### 3. Configure Repository Secrets

Add these secrets to your repository (Settings → Secrets and variables → Actions):

- `AZURE_CLIENT_ID` - Azure Service Principal Client ID
- `AZURE_TENANT_ID` - Azure Tenant ID
- `AZURE_SUBSCRIPTION_ID` - Azure Subscription ID

### 4. Configure Repository Variables

Add these variables for your environments:

- `DOTNET_VERSION` - .NET SDK version (e.g., '8.0.x')
- `STAGING_APP_NAME` - Azure App Service name for staging
- `PRODUCTION_APP_NAME` - Azure App Service name for production
- `STAGING_RESOURCE_GROUP` - Azure Resource Group for staging
- `PRODUCTION_RESOURCE_GROUP` - Azure Resource Group for production
- `DEPLOYMENT_TYPE` - Type of deployment (app-service, function-app, container-apps)

## 📚 Actions Reference

### Setup Action

Sets up .NET SDK and Azure authentication.

```yaml
- uses: ./.github/actions/dotnet/setup
  with:
    dotnet-version: '8.0.x'          # Required
    azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}     # Optional
    azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}     # Optional
    azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}  # Optional
    enable-caching: 'true'            # Optional, default: true
```

### Restore Action

Restores NuGet packages with caching.

```yaml
- uses: ./.github/actions/dotnet/restore
  with:
    working-directory: './'           # Optional, default: ./
    configuration: 'Release'          # Optional, default: Release
    verbosity: 'minimal'              # Optional, default: minimal
    use-lock-file: 'true'            # Optional, default: true
```

### Build Action

Builds .NET projects.

```yaml
- uses: ./.github/actions/dotnet/build
  with:
    working-directory: './'           # Optional
    configuration: 'Release'          # Optional
    version-suffix: ''                # Optional
    no-restore: 'true'               # Optional, default: true
    verbosity: 'minimal'              # Optional
    treat-warnings-as-errors: 'false' # Optional, default: false
```

**Outputs:**
- `build-version` - The build version number

### Test Action

Runs tests with code coverage.

```yaml
- uses: ./.github/actions/dotnet/test
  with:
    working-directory: './'           # Optional
    configuration: 'Release'          # Optional
    no-build: 'true'                 # Optional, default: true
    collect-coverage: 'true'         # Optional, default: true
    coverage-threshold: '80'         # Optional, default: 0
    test-filter: ''                  # Optional
    verbosity: 'minimal'              # Optional
    results-directory: './TestResults' # Optional
```

**Outputs:**
- `test-result` - Test execution result (success/failure)
- `coverage-percentage` - Code coverage percentage

### Publish Action

Publishes .NET application for deployment.

```yaml
- uses: ./.github/actions/dotnet/publish
  with:
    working-directory: './'           # Optional
    configuration: 'Release'          # Optional
    runtime: 'linux-x64'             # Optional (linux-x64, win-x64, osx-x64)
    self-contained: 'false'          # Optional, default: false
    single-file: 'false'             # Optional, default: false
    output-path: './publish'         # Optional
    no-build: 'true'                 # Optional, default: true
    trim-unused-code: 'false'        # Optional, default: false
    ready-to-run: 'false'            # Optional, default: false
```

**Outputs:**
- `publish-path` - Path to published artifacts

### Deploy Action

Deploys to Azure services.

```yaml
- uses: ./.github/actions/dotnet/deploy
  with:
    deployment-type: 'app-service'    # Required (app-service, function-app, container-apps)
    app-name: 'my-app'               # Required
    resource-group: 'my-rg'          # Optional (required for container-apps)
    slot-name: 'production'          # Optional, default: production
    package-path: './deployment-package.zip' # Optional
    startup-command: ''              # Optional
    container-registry: ''           # Optional (for container-apps)
    container-image: ''              # Optional (for container-apps)
```

**Outputs:**
- `deployment-url` - URL of the deployed application

## 🔄 Workflows Reference

### Build Workflow

Reusable workflow for building and testing.

```yaml
uses: ./.github/workflows/dotnet/build.yml
with:
  environment: 'development'
  dotnet-version: '8.0.x'
  working-directory: './'
  configuration: 'Release'
  run-tests: true
  collect-coverage: true
  coverage-threshold: '80'
  # Pre/Post hooks
  pre-restore-step: 'echo "Before restore"'
  post-restore-step: 'echo "After restore"'
  pre-build-step: 'echo "Before build"'
  post-build-step: 'echo "After build"'
  pre-test-step: 'echo "Before tests"'
  post-test-step: 'echo "After tests"'
secrets: inherit
```

**Outputs:**
- `build-version` - Build version number
- `test-result` - Test execution result
- `coverage-percentage` - Code coverage percentage

### Deploy Workflow

Reusable workflow for deployment.

```yaml
uses: ./.github/workflows/dotnet/deploy.yml
with:
  environment: 'production'
  dotnet-version: '8.0.x'
  working-directory: './'
  configuration: 'Release'
  deployment-type: 'app-service'
  app-name: 'my-app'
  resource-group: 'my-rg'
  slot-name: 'production'
  runtime: 'linux-x64'
  self-contained: false
  # Pre/Post hooks
  pre-publish-step: 'echo "Before publish"'
  post-publish-step: 'echo "After publish"'
  pre-deploy-step: 'echo "Before deploy"'
  post-deploy-step: 'echo "After deploy"'
secrets:
  azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
  azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
  azure-subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

**Outputs:**
- `deployment-url` - URL of deployed application

### Main CI/CD Pipeline

Complete pipeline with build, test, security scan, approval gates, and deployment.

```yaml
uses: ./.github/workflows/dotnet/dotnet-pipeline.yml
```

Features:
- ✅ Automated builds on PR and push
- ✅ Comprehensive testing with coverage
- ✅ Security scanning
- ✅ Code quality analysis
- ✅ Approval gates for production
- ✅ Multi-environment deployment
- ✅ Smoke tests after deployment
- ✅ Rollback support
- ✅ Pre/Post hooks for all stages

## 🎯 Use Cases

### Basic CI/CD with Tests

```yaml
name: Basic CI/CD

on: [push, pull_request]

jobs:
  setup:
    # ... setup job

  build:
    needs: setup
    uses: ./.github/workflows/dotnet/build.yml
    with:
      environment: 'development'
      dotnet-version: '8.0.x'
      run-tests: true
      collect-coverage: true
      coverage-threshold: '75'
    secrets: inherit
```

### Deploy to Azure App Service

```yaml
name: Deploy to Azure

on:
  workflow_dispatch:

jobs:
  setup:
    # ... setup job

  deploy:
    needs: setup
    uses: ./.github/workflows/dotnet/deploy.yml
    with:
      environment: 'production'
      dotnet-version: '8.0.x'
      deployment-type: 'app-service'
      app-name: 'my-web-app'
      slot-name: 'production'
    secrets: inherit
```

### Deploy to Azure Functions

```yaml
name: Deploy Functions

on:
  workflow_dispatch:

jobs:
  setup:
    # ... setup job

  deploy:
    needs: setup
    uses: ./.github/workflows/dotnet/deploy.yml
    with:
      environment: 'production'
      dotnet-version: '8.0.x'
      deployment-type: 'function-app'
      app-name: 'my-function-app'
    secrets: inherit
```

### Pre/Post Hooks Example

```yaml
jobs:
  build:
    uses: ./.github/workflows/dotnet/build.yml
    with:
      environment: 'staging'
      dotnet-version: '8.0.x'
      # Run database migrations before tests
      pre-test-step: |
        dotnet ef database update --project src/MyApp.Data
        dotnet run --project tests/Setup -- seed-test-data
      # Generate documentation after build
      post-build-step: |
        dotnet tool install -g xmldocmd
        xmldocmd src/MyApp/bin/Release/net8.0/MyApp.dll docs/
      # Clean up test data after tests
      post-test-step: |
        dotnet run --project tests/Setup -- clean-test-data
    secrets: inherit
```

### Multi-Environment Deployment

```yaml
name: Multi-Environment Deploy

on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [staging, production]

jobs:
  setup:
    # ... setup job

  deploy:
    needs: setup
    uses: ./.github/workflows/dotnet/deploy.yml
    with:
      environment: ${{ github.event.inputs.environment }}
      dotnet-version: '8.0.x'
      deployment-type: 'app-service'
      app-name: ${{ github.event.inputs.environment == 'production' && 'prod-app' || 'staging-app' }}
      # Run smoke tests after deployment
      post-deploy-step: |
        echo "Running smoke tests..."
        curl -f https://${{ github.event.inputs.environment }}-app.azurewebsites.net/health
        dotnet test tests/SmokeTests --filter Category=Smoke
    secrets: inherit
```

## 🔐 Azure Authentication Setup

### 1. Create Azure Service Principal

```bash
az ad sp create-for-rbac \
  --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth
```

### 2. Configure Federated Identity (Recommended)

```bash
az ad app federated-credential create \
  --id {app-id} \
  --parameters '{
    "name": "github-actions",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:your-org/your-repo:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 3. Add Secrets to GitHub

- Navigate to Settings → Secrets and variables → Actions
- Add the following secrets:
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`

## 📊 Code Coverage Reports

The test action automatically generates code coverage reports:

- HTML reports in `TestResults/coveragereport/`
- JSON summary in `TestResults/coveragereport/Summary.json`
- Coverage badges

Access reports as artifacts after workflow completion.

## 🏗️ Best Practices

### 1. Use Lock Files for Dependencies

Create `packages.lock.json`:

```bash
dotnet restore --use-lock-file
```

### 2. Enable Code Coverage

In your test projects:

```xml
<PropertyGroup>
  <CollectCoverage>true</CollectCoverage>
  <CoverletOutputFormat>opencover</CoverletOutputFormat>
</PropertyGroup>
```

### 3. Configure Health Checks

For deployment verification:

```csharp
// Program.cs
app.MapHealthChecks("/health");
```

### 4. Use Deployment Slots

For zero-downtime deployments:

```yaml
slot-name: 'staging'  # Deploy to staging slot first
# Then swap slots in post-deploy step
post-deploy-step: |
  az webapp deployment slot swap \
    --resource-group my-rg \
    --name my-app \
    --slot staging
```

### 5. Version Your Builds

In your `.csproj`:

```xml
<PropertyGroup>
  <Version>1.0.0</Version>
  <VersionPrefix>1.0.0</VersionPrefix>
  <VersionSuffix>$(VersionSuffix)</VersionSuffix>
</PropertyGroup>
```

Then use:

```yaml
version-suffix: 'beta-${{ github.run_number }}'
```

## 🐛 Troubleshooting

### Issue: Tests Fail to Collect Coverage

**Solution:** Ensure you have the coverage package:

```bash
dotnet add package coverlet.collector
```

### Issue: Deployment Package Not Found

**Solution:** Ensure the publish action runs before deploy:

```yaml
- uses: ./.github/actions/dotnet/publish
  # Deployment package is automatically created
- uses: ./.github/actions/dotnet/deploy
  # Will use the package from previous step
```

### Issue: Azure Authentication Fails

**Solution:** Verify your service principal has correct permissions:

```bash
az role assignment list --assignee {client-id}
```

## 📖 Additional Resources

- [.NET CLI Reference](https://docs.microsoft.com/en-us/dotnet/core/tools/)
- [Azure App Service Deployment](https://docs.microsoft.com/en-us/azure/app-service/deploy-github-actions)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Code Coverage Best Practices](https://docs.microsoft.com/en-us/dotnet/core/testing/unit-testing-code-coverage)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

MIT License - feel free to use these templates in your projects.

---

**Need Help?** Open an issue in the repository or check the examples in the `examples/` directory.
