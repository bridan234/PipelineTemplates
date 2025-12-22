# Azure Terraform Pipeline Template

Modular, reusable GitHub Actions workflows for Terraform on Azure.

## Structure

```
Azure/
├── actions/              # Reusable composite actions
│   ├── setup/           # Setup Terraform & Azure auth
│   ├── init/            # Terraform init with backend
│   ├── validate/        # Format check & validate
│   ├── plan/            # Terraform plan
│   └── apply/           # Terraform apply
├── workflows/           # Reusable workflows
│   ├── validate.yml     # Validation workflow
│   ├── plan.yml         # Plan workflow
│   ├── apply.yml        # Apply workflow
│   └── terraform-pipeline.yml  # Main orchestrator
└── README.md
```

## Quick Start (Recommended: External Reference)

This template is designed to be **referenced from a central repository** at runtime. This avoids copying files to each project.

### Prerequisites

1. Push this template repository to GitHub (e.g., `your-org/pipeline-templates`)
2. Ensure the repository is accessible to repos that will use it (same org or public)

### Setup in Your Project

Create a single file `.github/workflows/terraform.yml` in your project:

```yaml
name: Terraform Pipeline

on:
  pull_request:
    paths: ['terraform/**', '.github/workflows/terraform.yml']
  push:
    branches: [develop, main]
    paths: ['terraform/**', '.github/workflows/terraform.yml']
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment'
        required: true
        type: choice
        options: [staging, production]
      action:
        description: 'Action'
        required: true
        type: choice
        default: 'plan'
        options: [validate, plan, apply, destroy]

permissions:
  contents: write
  pull-requests: write
  id-token: write
  actions: write

jobs:
  validate:
    name: Validate
    if: github.event_name == 'pull_request' || github.event_name == 'push' || github.event_name == 'workflow_dispatch'
    # Reference reusable workflow from external repo
    uses: your-org/pipeline-templates/.github/workflows/Terraform/Azure/workflows/validate.yml@main
    with:
      environment: ${{ github.event.inputs.environment || 'staging' }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
      template-repo: 'your-org/pipeline-templates'  # ← Template repo to download actions from
      template-ref: 'main'                           # ← Use 'main' or specific tag like 'v1.0.0'
      # Optional: Add custom pre/post steps
      # pre-step: 'echo "Starting validation..."'
      # post-step: 'echo "Validation complete!"'
    secrets: inherit

  plan:
    name: Plan
    needs: validate
    if: github.event_name == 'pull_request' || github.event_name == 'push' || github.event.inputs.action == 'plan' || github.event.inputs.action == 'apply' || github.event.inputs.action == 'destroy'
    # Reference reusable workflow from external repo
    uses: your-org/pipeline-templates/.github/workflows/Terraform/Azure/workflows/plan.yml@main
    with:
      environment: ${{ github.event.inputs.environment || 'staging' }}
      var-file: ${{ github.event.inputs.environment || 'staging' }}.tfvars
      destroy: ${{ github.event.inputs.action == 'destroy' }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
      template-repo: 'your-org/pipeline-templates'
      template-ref: 'main'
      # Optional: Add custom pre/post steps
      # pre-step: 'echo "Starting plan..."'
      # post-step: 'echo "Plan complete!"'
    secrets: inherit

  approve:
    name: Approve
    needs: plan
    if: github.event_name != 'pull_request' && needs.plan.outputs.exitcode == '2' && (github.event.inputs.action == 'apply' || github.event.inputs.action == 'destroy')
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    steps:
      - run: echo "✅ Approved"

  apply:
    name: Apply
    needs: [plan, approve]
    if: github.event_name != 'pull_request' && needs.plan.outputs.exitcode == '2' && (github.event.inputs.action == 'apply' || github.event.inputs.action == 'destroy')
    # Reference reusable workflow from external repo
    uses: your-org/pipeline-templates/.github/workflows/Terraform/Azure/workflows/apply.yml@main
    with:
      environment: ${{ github.event.inputs.environment }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
      template-repo: 'your-org/pipeline-templates'
      template-ref: 'main'
      # Optional: Add custom pre/post steps
      # pre-step: 'echo "Starting apply..."'
      # post-step: 'echo "Apply complete! Running health checks..."'
    secrets: inherit
```

**Key points:**
- ✅ **Reusable workflows** are referenced via `uses: your-org/pipeline-templates/.github/workflows/...@main`
- ✅ **Composite actions** are automatically downloaded at runtime by the reusable workflows
- ✅ **No files to copy** - everything is referenced from the central template repo
- ✅ **Version control** - Use `@main` for latest, or `@v1.0.0` for specific versions
- ✅ **Similar to Azure Pipelines** - Templates are downloaded and used at runtime

Your project structure is minimal:
```
your-project/
├── .github/
│   └── workflows/
│       └── terraform.yml  # ← Single 100-line file that references templates
└── terraform/
    ├── staging.tfvars
    ├── prod.tfvars
    └── ... your terraform files
```

**No need to copy any template files!** The workflows download them at runtime.

## How It Works

1. **Reference reusable workflows** from your template repo using `uses: org/repo/.github/workflows/path@ref`
2. **Pass `template-repo` input** to tell the workflow where to download composite actions from
3. **Workflows auto-download** composite actions at runtime using artifacts
4. **Pass parameters** like you would in Azure Pipelines templates

This pattern gives you:
- ✅ Centralized maintenance (update once, all repos benefit)
- ✅ Version pinning (`@v1.0.0` for stability, `@main` for latest)
- ✅ No file duplication (single source of truth)
- ✅ Runtime template resolution (similar to Azure Pipelines)

## Versioning

Pin to specific versions for stability:

```yaml
# Use latest
uses: your-org/pipeline-templates/.github/workflows/terraform/azure/plan.yml@main

# Use specific tag
uses: your-org/pipeline-templates/.github/workflows/terraform/azure/plan.yml@v1.0.0

# Use specific commit
uses: your-org/pipeline-templates/.github/workflows/terraform/azure/plan.yml@abc1234
```

### Step 1: Configure GitHub Environments

1. Go to **Settings → Environments** in your repository
2. Create two environments:
   - `staging`
   - `production`
3. For `production`:
   - Enable **Required reviewers**
   - Add team members who should approve deployments
4. For `staging` (optional):
   - Add reviewers if you want approval for staging too

### Step 2: Add Repository Secrets

Go to **Settings → Secrets and variables → Actions → Secrets**

**Required secrets:**
```
AZURE_CLIENT_ID          # Your Azure service principal client ID
AZURE_TENANT_ID          # Your Azure tenant ID
AZURE_SUBSCRIPTION_ID    # Your Azure subscription ID (staging)
```

**Optional: Per-Environment Secrets**

For production, add to the `production` environment:
```
AZURE_SUBSCRIPTION_ID    # Production subscription ID (if different)
PROD_SUBSCRIPTION_ID     # If using cross-subscription DNS
```

### Step 3: Add Repository Variables

Go to **Settings → Secrets and variables → Actions → Variables**

```
BACKEND_RESOURCE_GROUP_NAME    # e.g., terraform-state-rg
BACKEND_STORAGE_ACCOUNT_NAME   # e.g., tfstate12345
BACKEND_CONTAINER_NAME         # e.g., tfstate
BACKEND_KEY                    # e.g., odc.tfstate
```

### Step 4: Add Your Terraform Secrets

Add any secrets your Terraform needs as `TF_VAR_*`:

```
TF_VAR_database_password
TF_VAR_jwt_secret
TF_VAR_api_key
TF_VAR_registry_password
```

Then reference them in the workflows (see "Customizing for Your Secrets" below).

## Customizing for Your Secrets

### Edit `plan.yml`

Find the `Terraform Plan` step and add your secrets:

```yaml
- name: Terraform Plan
  id: plan
  uses: ./.github/actions/terraform/azure/plan
  with:
    working-directory: ${{ inputs.working-directory }}
    var-file: ${{ inputs.var-file }}
    destroy: ${{ inputs.destroy }}
  env:
    # Add all your TF_VAR_* secrets here
    TF_VAR_registry_username: ${{ secrets.REGISTRY_USERNAME }}
    TF_VAR_registry_password: ${{ secrets.REGISTRY_PASSWORD }}
    TF_VAR_postgres_connection_string: ${{ secrets.POSTGRES_CONNECTION_STRING }}
    TF_VAR_jwt_secret: ${{ secrets.JWT_SECRET }}
    TF_VAR_supabase_url: ${{ secrets.SUPABASE_URL }}
    TF_VAR_supabase_anon_key: ${{ secrets.SUPABASE_ANON_KEY }}
    TF_VAR_prod_subscription_id: ${{ secrets.PROD_SUBSCRIPTION_ID }}
```

### Edit `apply.yml`

Add the **exact same** `env:` block to the `Terraform Apply` step:

```yaml
- name: Terraform Apply
  uses: ./.github/actions/terraform/azure/apply
  with:
    working-directory: ${{ inputs.working-directory }}
  env:
    # Must match plan.yml exactly
    TF_VAR_registry_username: ${{ secrets.REGISTRY_USERNAME }}
    TF_VAR_registry_password: ${{ secrets.REGISTRY_PASSWORD }}
    TF_VAR_postgres_connection_string: ${{ secrets.POSTGRES_CONNECTION_STRING }}
    # ... rest of your secrets
```

## Pre and Post Steps

Each workflow supports optional `pre-step` and `post-step` inputs for custom logic. **These accept multi-line scripts** with multiple commands.

### Example: Multiple Commands in Pre/Post Steps

```yaml
jobs:
  plan:
    uses: your-org/pipeline-templates/.github/workflows/Terraform/Azure/workflows/plan.yml@main
    with:
      environment: staging
      var-file: staging.tfvars
      terraform-version: '1.7.0'
      working-directory: './terraform'
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
      template-repo: 'your-org/pipeline-templates'
      pre-step: |
        echo "🔍 Pre-plan checks starting..."
        
        # Check database connectivity
        echo "Checking database..."
        timeout 5 bash -c '</dev/tcp/db.example.com/5432' || exit 1
        
        # Verify API is responding
        echo "Checking API health..."
        curl -f https://api.staging.example.com/health || exit 1
        
        # Send notification
        curl -X POST https://slack.com/api/chat.postMessage \
          -H "Authorization: Bearer ${{ secrets.SLACK_TOKEN }}" \
          -d "text=🚀 Starting Terraform plan for staging"
        
        echo "✅ All pre-checks passed"
      post-step: |
        echo "📊 Post-plan actions starting..."
        
        # Extract cost estimate from plan (if using Infracost)
        # infracost breakdown --path tfplan
        
        # Send plan summary to Slack
        curl -X POST https://slack.com/api/chat.postMessage \
          -H "Authorization: Bearer ${{ secrets.SLACK_TOKEN }}" \
          -d "text=✅ Terraform plan completed for staging"
        
        # Update status in monitoring system
        curl -X POST https://monitoring.example.com/api/events \
          -H "Content-Type: application/json" \
          -d '{"event": "terraform_plan_complete", "env": "staging"}'
        
        echo "✅ Post-plan actions complete"
    secrets: inherit
```

### Example: Notification Before/After Plan

In your main `terraform.yml` file:

```yaml
jobs:
  plan:
    name: Plan
    needs: validate
    uses: your-org/pipeline-templates/.github/workflows/Terraform/Azure/workflows/plan.yml@main
    with:
      environment: staging
      var-file: staging.tfvars
      terraform-version: '1.7.0'
      working-directory: './terraform'
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
      template-repo: 'your-org/pipeline-templates'
      template-ref: 'main'
      pre-step: |
        echo "🔍 Starting infrastructure plan..."
        curl -X POST https://slack.com/api/chat.postMessage \
          -H "Authorization: Bearer ${{ secrets.SLACK_TOKEN }}" \
          -d "text=Starting Terraform plan for staging"
      post-step: |
        echo "✅ Plan completed"
        curl -X POST https://slack.com/api/chat.postMessage \
          -H "Authorization: Bearer ${{ secrets.SLACK_TOKEN }}" \
          -d "text=Terraform plan completed for staging"
    secrets: inherit
```

### Example: Pre-Check Database Connection

```yaml
jobs:
  plan:
    uses: your-org/pipeline-templates/.github/workflows/Terraform/Azure/workflows/plan.yml@main
    with:
      environment: production
      var-file: prod.tfvars
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
      template-repo: 'your-org/pipeline-templates'
      pre-step: |
        echo "Checking database connectivity..."
        timeout 5 bash -c '</dev/tcp/db.example.com/5432' || exit 1
        echo "Database is reachable"
    secrets: inherit
```

### Example: Post-Apply Health Check

```yaml
jobs:
  apply:
    uses: your-org/pipeline-templates/.github/workflows/Terraform/Azure/workflows/apply.yml@main
    with:
      environment: staging
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
      template-repo: 'your-org/pipeline-templates'
      post-step: |
        echo "🏥 Running post-deployment health checks..."
        
        # Wait for services to stabilize
        echo "Waiting 30 seconds for services to start..."
        sleep 30
        
        # Check API health
        echo "Checking API health endpoint..."
        curl -f https://api.staging.example.com/health || exit 1
        
        # Check database migrations
        echo "Verifying database migrations..."
        curl -f https://api.staging.example.com/api/migrations/status || exit 1
        
        # Run smoke tests
        echo "Running smoke tests..."
        curl -f https://api.staging.example.com/api/test/smoke || exit 1
        
        # Send success notification
        curl -X POST https://slack.com/api/chat.postMessage \
          -H "Authorization: Bearer ${{ secrets.SLACK_TOKEN }}" \
          -d "text=✅ Deployment to staging complete and healthy!"
        
        echo "✅ All health checks passed"
    secrets: inherit
```

### Example: Pre-Apply Backup and Validation

```yaml
jobs:
  apply:
    uses: your-org/pipeline-templates/.github/workflows/Terraform/Azure/workflows/apply.yml@main
    with:
      environment: production
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
      template-repo: 'your-org/pipeline-templates'
      pre-step: |
        echo "🔒 Pre-apply safety checks for PRODUCTION..."
        
        # Create backup of current state
        echo "Creating state backup..."
        az storage blob download \
          --account-name ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }} \
          --container-name ${{ vars.BACKEND_CONTAINER_NAME }} \
          --name ${{ vars.BACKEND_KEY }} \
          --file "backup-$(date +%Y%m%d-%H%M%S).tfstate"
        
        # Verify we're in business hours (optional safety check)
        current_hour=$(date +%H)
        if [ $current_hour -lt 9 ] || [ $current_hour -gt 17 ]; then
          echo "⚠️ Warning: Deploying outside business hours"
        fi
        
        # Check for active incidents
        incident_count=$(curl -s https://monitoring.example.com/api/incidents/active | jq length)
        if [ $incident_count -gt 0 ]; then
          echo "❌ Active incidents detected. Aborting deployment."
          exit 1
        fi
        
        echo "✅ All pre-apply checks passed"
      post-step: |
        echo "📢 Post-apply notifications..."
        
        # Send deployment notification to multiple channels
        curl -X POST https://slack.com/api/chat.postMessage \
          -H "Authorization: Bearer ${{ secrets.SLACK_TOKEN }}" \
          -d "text=🚀 Production deployment complete!"
        
        # Update change log
        curl -X POST https://changelog.example.com/api/entries \
          -H "Content-Type: application/json" \
          -d "{\"message\": \"Infrastructure update\", \"env\": \"production\"}"
        
        # Trigger monitoring alert reset
        curl -X POST https://monitoring.example.com/api/deploy-complete \
          -d "environment=production"
    secrets: inherit
```

### Example: Cache Cleanup After Validation

```yaml
jobs:
  validate:
    uses: your-org/pipeline-templates/.github/workflows/Terraform/Azure/workflows/validate.yml@main
    with:
      environment: staging
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
      template-repo: 'your-org/pipeline-templates'
      post-step: |
        echo "Cleaning up temporary files..."
        rm -rf /tmp/terraform-*
    secrets: inherit
```

### Available Context in Pre/Post Steps

Pre and post steps have access to:
- ✅ All repository secrets (via `${{ secrets.SECRET_NAME }}`)
- ✅ Environment variables
- ✅ Workspace files (after checkout)
- ✅ All standard bash commands and utilities
- ✅ Terraform files and state (in post-steps)
- ✅ Multi-line scripts with multiple commands
- ✅ Conditional logic (if/then/else)
- ✅ Loops and functions

### Tips for Multi-Step Scripts

1. **Use multi-line format** with `|` for readability:
   ```yaml
   pre-step: |
     command1
     command2
     command3
   ```

2. **Exit on error** to stop the workflow if a check fails:
   ```yaml
   pre-step: |
     curl -f https://api.example.com/health || exit 1
   ```

3. **Use functions** for complex logic:
   ```yaml
   pre-step: |
     check_health() {
       local url=$1
       echo "Checking $url..."
       curl -f "$url" || return 1
     }
     
     check_health "https://api.example.com/health"
     check_health "https://db.example.com/health"
   ```

4. **Add logging** to track execution:
   ```yaml
   pre-step: |
     echo "Step 1: Checking database..."
     # check database
     echo "Step 2: Verifying API..."
     # check API
     echo "✅ All checks complete"
   ```

## Usage Examples

### Example 1: Automatic Validation on Push

Push to `develop` or `main`:
```bash
git push origin develop
```

**What runs:**
- ✅ Validate (format check + terraform validate)
- ✅ Plan (shows what would change)
- ❌ Apply (does NOT auto-apply)

### Example 2: Manual Deployment to Staging

1. Go to **Actions** tab
2. Select **Terraform Pipeline**
3. Click **Run workflow**
4. Choose:
   - Environment: `staging`
   - Action: `apply`
5. Click **Run workflow**

**What runs:**
1. ✅ Validate
2. ✅ Plan
3. ⏸️ Approve (waits for manual approval if configured)
4. ✅ Apply

### Example 3: Plan Only (No Changes)

Good for checking what would happen:

1. **Actions → Run workflow**
2. Environment: `production`
3. Action: `plan`
4. **Run workflow**

**What runs:**
- ✅ Validate
- ✅ Plan
- ⏹️ Stops (does not proceed to apply)

### Example 4: Destroy Non-Prod Environment

1. **Actions → Run workflow**
2. Environment: `staging`
3. Action: `destroy`
4. **Run workflow**

**What runs:**
1. ✅ Validate
2. ✅ Destroy Plan (shows what will be destroyed)
3. ⏸️ Approve (manual confirmation required)
4. 🗑️ Destroy

**Note:** Destroy is **blocked** for `production` environment.

### Example 5: Pull Request Review

Create a PR with Terraform changes:
```bash
git checkout -b feature/update-infrastructure
# ... make terraform changes
git push origin feature/update-infrastructure
# Create PR on GitHub
```

**What runs:**
- ✅ Validate
- ✅ Plan
- 💬 Posts plan as PR comment

## Complete Working Example

Here's a full `terraform.yml` with all customizations:

```yaml
name: Terraform Pipeline

on:
  pull_request:
    paths: ['terraform/**', '.github/workflows/terraform.yml']
  push:
    branches: [develop, main]
    paths: ['terraform/**', '.github/workflows/terraform.yml']
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment'
        required: true
        type: choice
        options: [staging, production]
      action:
        description: 'Action'
        required: true
        type: choice
        default: 'plan'
        options: [validate, plan, apply, destroy]

permissions:
  contents: write
  pull-requests: write
  id-token: write
  actions: write

jobs:
  validate:
    name: Validate
    if: github.event_name == 'pull_request' || github.event_name == 'push' || github.event_name == 'workflow_dispatch'
    uses: ./.github/workflows/terraform/azure/validate.yml
    with:
      environment: ${{ github.event.inputs.environment || 'staging' }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
    secrets: inherit

  plan:
    name: Plan
    needs: validate
    if: github.event_name == 'pull_request' || github.event_name == 'push' || github.event.inputs.action == 'plan' || github.event.inputs.action == 'apply' || github.event.inputs.action == 'destroy'
    uses: ./.github/workflows/terraform/azure/plan.yml
    with:
      environment: ${{ github.event.inputs.environment || 'staging' }}
      var-file: ${{ github.event.inputs.environment || 'staging' }}.tfvars
      destroy: ${{ github.event.inputs.action == 'destroy' }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
    secrets: inherit

  approve:
    name: Approve
    needs: plan
    if: github.event_name != 'pull_request' && needs.plan.outputs.exitcode == '2' && (github.event.inputs.action == 'apply' || github.event.inputs.action == 'destroy')
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    steps:
      - run: echo "✅ Approved"

  apply:
    name: Apply
    needs: [plan, approve]
    if: github.event_name != 'pull_request' && needs.plan.outputs.exitcode == '2' && (github.event.inputs.action == 'apply' || github.event.inputs.action == 'destroy')
    uses: ./.github/workflows/terraform/azure/apply.yml
    with:
      environment: ${{ github.event.inputs.environment }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      backend-resource-group: ${{ vars.BACKEND_RESOURCE_GROUP_NAME }}
      backend-storage-account: ${{ vars.BACKEND_STORAGE_ACCOUNT_NAME }}
      backend-container: ${{ vars.BACKEND_CONTAINER_NAME }}
      backend-key: ${{ vars.BACKEND_KEY }}
    secrets: inherit
```

## Troubleshooting

### Error: "Resource not found" during init

**Problem:** Backend storage doesn't exist.

**Solution:**
```bash
# Create backend storage
az group create --name terraform-state-rg --location eastus
az storage account create --name tfstate12345 --resource-group terraform-state-rg --location eastus --sku Standard_LRS
az storage container create --name tfstate --account-name tfstate12345
```

### Error: "No such file or directory: staging.tfvars"

**Problem:** Var file path doesn't match what's configured.

**Solution:**
- Ensure `staging.tfvars` and `prod.tfvars` (or `production.tfvars`) exist in `terraform/` directory
- Update `var-file` input if using different names

### Error: "Missing required variable"

**Problem:** TF_VAR_* secret not configured in workflow.

**Solution:**
- Add the secret to GitHub (Settings → Secrets)
- Add `TF_VAR_your_var: ${{ secrets.YOUR_SECRET }}` to both `plan.yml` and `apply.yml`

### Destroy Blocked for Production

**Expected behavior:** Destroy action automatically fails for production environment.

**To destroy production:** Remove the check in `terraform.yml` (not recommended):
```yaml
- name: Verify Destroy Action
  if: github.event.inputs.action == 'destroy' && steps.set-env.outputs.environment == 'production'
  run: |
    echo "❌ Destroy action is not allowed for production environment."
    exit 1
```

### Plan shows "No changes"

**Problem:** No Terraform changes detected.

**This is normal** - means infrastructure matches code. Apply job will be skipped.

## Advanced: Using as External Reference

This is now the **primary usage pattern** (covered in Quick Start above). Key benefits:

✅ **Centralized maintenance** - Update once, all projects benefit  
✅ **Version control** - Pin to tags for stability  
✅ **No file duplication** - Single source of truth  
✅ **Similar to Azure Pipelines templates** - Download at runtime and reference

### Alternative: Copy Files Locally

If you prefer to have full control and avoid external dependencies:

```bash
# In your repo root
mkdir -p .github/actions/terraform/azure
cp -r /path/to/PipelineTemplates/Terraform/Azure/actions/* .github/actions/terraform/azure/

mkdir -p .github/workflows/terraform/azure
cp -r /path/to/PipelineTemplates/Terraform/Azure/workflows/* .github/workflows/terraform/azure/
```

Then reference locally:
```yaml
uses: ./.github/workflows/terraform/azure/plan.yml
```

## Setup Requirements

1. **Secrets** (per environment):
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

2. **Variables**:
   - `BACKEND_RESOURCE_GROUP_NAME`
   - `BACKEND_STORAGE_ACCOUNT_NAME`
   - `BACKEND_CONTAINER_NAME`
   - `BACKEND_KEY`

3. **GitHub Environments**:
   - Create `staging` and `production`
   - Add required reviewers for manual approval gates

## Passing Additional Secrets/Variables

The templates use `secrets: inherit` to automatically pass all secrets from the calling workflow to reusable workflows.

### Add Terraform Variables (TF_VAR_*)

In the reusable workflows (`plan.yml`, `apply.yml`), add your secrets as environment variables:

```yaml
env:
  TF_VAR_database_password: ${{ secrets.DATABASE_PASSWORD }}
  TF_VAR_api_key: ${{ secrets.API_KEY }}
```

### Example with Custom Secrets

```yaml
jobs:
  plan:
    uses: ./.github/workflows/terraform/azure/plan.yml
    with:
      environment: staging
      var-file: staging.tfvars
    secrets: inherit  # Passes ALL secrets from parent
```

Then in `plan.yml`, reference them:
```yaml
- name: Terraform Plan
  env:
    TF_VAR_my_secret: ${{ secrets.MY_SECRET }}
    TF_VAR_another_var: ${{ secrets.ANOTHER_VAR }}
```

## Features

- **Modular**: Each component is independently reusable
- **Multi-environment**: Supports staging, production, etc.
- **Action choices**: validate, plan, apply, destroy
- **Safety**: Production restrictions, destroy prevention, manual approvals
- **Automated**: Runs validate + plan on push/PR
