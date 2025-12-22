# GCP Terraform Pipeline Template

Modular, reusable GitHub Actions workflows for Terraform on Google Cloud Platform.

## Structure

```
GCP/
├── actions/              # Reusable composite actions
│   ├── setup/           # Setup Terraform & GCP auth
│   ├── init/            # Terraform init with GCS backend
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

env:
  TEMPLATE_REPO: your-org/pipeline-templates
  TEMPLATE_REF: main  # Use 'main' or specific tag like 'v1.0.0'

permissions:
  contents: write
  pull-requests: write
  id-token: write
  actions: write

jobs:
  # Download templates ONCE at pipeline start
  setup:
    name: Setup Templates
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Templates
        uses: actions/checkout@v4
        with:
          repository: ${{ env.TEMPLATE_REPO }}
          ref: ${{ env.TEMPLATE_REF }}
          path: .pipeline-templates

      - name: Upload Templates
        uses: actions/upload-artifact@v4
        with:
          name: pipeline-templates-${{ github.run_id }}
          path: .pipeline-templates/Terraform/GCP/actions
          retention-days: 1

  validate:
    name: Validate
    needs: setup
    if: github.event_name == 'pull_request' || github.event_name == 'push' || github.event_name == 'workflow_dispatch'
    uses: your-org/pipeline-templates/.github/workflows/Terraform/GCP/workflows/validate.yml@main
    with:
      environment: ${{ github.event.inputs.environment || 'staging' }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      gcp-project-id: ${{ vars.GCP_PROJECT_ID }}
      gcp-region: ${{ vars.GCP_REGION }}
      backend-bucket: ${{ vars.BACKEND_BUCKET }}
      backend-prefix: ${{ vars.BACKEND_PREFIX }}
    secrets: inherit

  plan:
    name: Plan
    needs: [setup, validate]
    if: github.event_name == 'pull_request' || github.event_name == 'push' || github.event.inputs.action == 'plan' || github.event.inputs.action == 'apply' || github.event.inputs.action == 'destroy'
    uses: your-org/pipeline-templates/.github/workflows/Terraform/GCP/workflows/plan.yml@main
    with:
      environment: ${{ github.event.inputs.environment || 'staging' }}
      var-file: ${{ github.event.inputs.environment || 'staging' }}.tfvars
      destroy: ${{ github.event.inputs.action == 'destroy' }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      gcp-project-id: ${{ vars.GCP_PROJECT_ID }}
      gcp-region: ${{ vars.GCP_REGION }}
      backend-bucket: ${{ vars.BACKEND_BUCKET }}
      backend-prefix: ${{ vars.BACKEND_PREFIX }}
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
    needs: [setup, plan, approve]
    if: github.event_name != 'pull_request' && needs.plan.outputs.exitcode == '2' && (github.event.inputs.action == 'apply' || github.event.inputs.action == 'destroy')
    uses: your-org/pipeline-templates/.github/workflows/Terraform/GCP/workflows/apply.yml@main
    with:
      environment: ${{ github.event.inputs.environment }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      gcp-project-id: ${{ vars.GCP_PROJECT_ID }}
      gcp-region: ${{ vars.GCP_REGION }}
      backend-bucket: ${{ vars.BACKEND_BUCKET }}
      backend-prefix: ${{ vars.BACKEND_PREFIX }}
    secrets: inherit
```

**Key points:**
- ✅ **Templates downloaded once** in the `setup` job, then reused by all stages via artifact
- ✅ **Reusable workflows** are referenced via `uses: your-org/pipeline-templates/.github/workflows/...@main`
- ✅ **No files to copy** - everything is referenced from the central template repo
- ✅ **Version control** - Use `@main` for latest, or `@v1.0.0` for specific versions

Your project structure is minimal:
```
your-project/
├── .github/
│   └── workflows/
│       └── terraform.yml  # ← Single file that references templates
└── terraform/
    ├── staging.tfvars
    ├── prod.tfvars
    └── ... your terraform files
```

## Authentication Options

### Option 1: Workload Identity Federation (Recommended)

Uses GitHub's OIDC provider to authenticate without storing long-lived credentials.

**Required secrets:**
```
GCP_WORKLOAD_IDENTITY_PROVIDER  # projects/123456/locations/global/workloadIdentityPools/github/providers/github
GCP_SERVICE_ACCOUNT             # terraform@your-project.iam.gserviceaccount.com
```

**Setup Workload Identity:**
```bash
# Set variables
PROJECT_ID="your-project-id"
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
POOL_NAME="github"
PROVIDER_NAME="github"
SERVICE_ACCOUNT="terraform"
GITHUB_ORG="your-org"
GITHUB_REPO="your-repo"

# Create Workload Identity Pool
gcloud iam workload-identity-pools create $POOL_NAME \
  --project=$PROJECT_ID \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
  --project=$PROJECT_ID \
  --location="global" \
  --workload-identity-pool=$POOL_NAME \
  --display-name="GitHub Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Create Service Account
gcloud iam service-accounts create $SERVICE_ACCOUNT \
  --project=$PROJECT_ID \
  --display-name="Terraform Service Account"

# Grant permissions to Service Account (customize as needed)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

# Allow GitHub Actions to impersonate the Service Account
gcloud iam service-accounts add-iam-policy-binding \
  "${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project=$PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_ORG}/${GITHUB_REPO}"

# Output the values for GitHub secrets
echo "GCP_WORKLOAD_IDENTITY_PROVIDER: projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"
echo "GCP_SERVICE_ACCOUNT: ${SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com"
```

### Option 2: Service Account Key (Less Secure)

Uses a JSON key file (not recommended for production).

**Required secrets:**
```
GCP_CREDENTIALS_JSON  # The entire JSON key file contents
```

## Setup Requirements

### Step 1: Configure GitHub Environments

1. Go to **Settings → Environments** in your repository
2. Create two environments:
   - `staging`
   - `production`
3. For `production`:
   - Enable **Required reviewers**
   - Add team members who should approve deployments

### Step 2: Add Repository Secrets

Go to **Settings → Secrets and variables → Actions → Secrets**

**For Workload Identity (recommended):**
```
GCP_WORKLOAD_IDENTITY_PROVIDER  # From setup script above
GCP_SERVICE_ACCOUNT             # terraform@your-project.iam.gserviceaccount.com
```

**For Service Account Key (alternative):**
```
GCP_CREDENTIALS_JSON  # JSON key file contents
```

### Step 3: Add Repository Variables

Go to **Settings → Secrets and variables → Actions → Variables**

```
GCP_PROJECT_ID    # e.g., my-project-123456
GCP_REGION        # e.g., us-central1
BACKEND_BUCKET    # e.g., my-terraform-state-bucket
BACKEND_PREFIX    # e.g., terraform/state
```

### Step 4: Create GCS Backend Infrastructure

```bash
# Set variables
PROJECT_ID="your-project-id"
BUCKET_NAME="your-terraform-state-bucket"
REGION="us-central1"

# Create GCS bucket for state
gcloud storage buckets create gs://$BUCKET_NAME \
  --project=$PROJECT_ID \
  --location=$REGION \
  --uniform-bucket-level-access

# Enable versioning
gcloud storage buckets update gs://$BUCKET_NAME --versioning
```

## Customizing for Your Secrets

### Edit `plan.yml`

Find the `Terraform Plan` step and add your secrets:

```yaml
- name: Terraform Plan
  id: plan
  uses: ./.github/actions/terraform/gcp/plan
  with:
    working-directory: ${{ inputs.working-directory }}
    var-file: ${{ inputs.var-file }}
    destroy: ${{ inputs.destroy }}
  env:
    # Add all your TF_VAR_* secrets here
    TF_VAR_database_password: ${{ secrets.DATABASE_PASSWORD }}
    TF_VAR_api_key: ${{ secrets.API_KEY }}
```

### Edit `apply.yml`

Add the **exact same** `env:` block to the `Terraform Apply` step.

## Pre and Post Steps

Each workflow supports optional `pre-step` and `post-step` inputs for custom logic.

### Example: Health Check After Apply

```yaml
jobs:
  apply:
    uses: your-org/pipeline-templates/.github/workflows/Terraform/GCP/workflows/apply.yml@main
    with:
      environment: staging
      gcp-project-id: ${{ vars.GCP_PROJECT_ID }}
      gcp-region: ${{ vars.GCP_REGION }}
      backend-bucket: ${{ vars.BACKEND_BUCKET }}
      backend-prefix: ${{ vars.BACKEND_PREFIX }}
      post-step: |
        echo "🏥 Running post-deployment health checks..."

        # Check Cloud Run service
        gcloud run services describe my-service --region=${{ vars.GCP_REGION }} --format="value(status.url)"

        echo "✅ Deployment verified"
    secrets: inherit
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

### Example 3: Destroy Non-Prod Environment

1. **Actions → Run workflow**
2. Environment: `staging`
3. Action: `destroy`
4. **Run workflow**

## Versioning

Pin to specific versions for stability:

```yaml
# Use latest
uses: your-org/pipeline-templates/.github/workflows/Terraform/GCP/workflows/plan.yml@main

# Use specific tag
uses: your-org/pipeline-templates/.github/workflows/Terraform/GCP/workflows/plan.yml@v1.0.0

# Use specific commit
uses: your-org/pipeline-templates/.github/workflows/Terraform/GCP/workflows/plan.yml@abc1234
```

## Troubleshooting

### Error: "Permission denied" during init

**Problem:** Service account lacks permissions for GCS bucket.

**Solution:** Grant Storage Object Admin role:
```bash
gcloud storage buckets add-iam-policy-binding gs://your-bucket \
  --member="serviceAccount:terraform@your-project.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

### Error: "Workload Identity Federation failed"

**Problem:** OIDC configuration incorrect.

**Solution:**
- Verify the Workload Identity Pool and Provider exist
- Check that `id-token: write` permission is set in the workflow
- Ensure the repository attribute mapping matches your repo

### Error: "No such file or directory: staging.tfvars"

**Problem:** Var file path doesn't match what's configured.

**Solution:**
- Ensure `staging.tfvars` and `production.tfvars` exist in `terraform/` directory
- Update `var-file` input if using different names

### Plan shows "No changes"

**Problem:** No Terraform changes detected.

**This is normal** - means infrastructure matches code. Apply job will be skipped.

## Features

- **Modular**: Each component is independently reusable
- **Multi-environment**: Supports staging, production, etc.
- **Dual authentication**: Workload Identity (recommended) or Service Account Key
- **GCS backend**: With versioning for state history
- **Action choices**: validate, plan, apply, destroy
- **Safety**: Production restrictions, destroy prevention, manual approvals
- **Automated**: Runs validate + plan on push/PR
