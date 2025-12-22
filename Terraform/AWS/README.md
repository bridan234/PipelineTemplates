# AWS Terraform Pipeline Template

Modular, reusable GitHub Actions workflows for Terraform on AWS.

## Structure

```
AWS/
├── actions/              # Reusable composite actions
│   ├── setup/           # Setup Terraform & AWS auth
│   ├── init/            # Terraform init with S3 backend
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
          path: .pipeline-templates/Terraform/AWS/actions
          retention-days: 1

  validate:
    name: Validate
    needs: setup
    if: github.event_name == 'pull_request' || github.event_name == 'push' || github.event_name == 'workflow_dispatch'
    uses: your-org/pipeline-templates/.github/workflows/Terraform/AWS/workflows/validate.yml@main
    with:
      environment: ${{ github.event.inputs.environment || 'staging' }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      aws-region: ${{ vars.AWS_REGION }}
      backend-bucket: ${{ vars.BACKEND_BUCKET }}
      backend-key: ${{ vars.BACKEND_KEY }}
      backend-region: ${{ vars.BACKEND_REGION }}
      backend-dynamodb-table: ${{ vars.BACKEND_DYNAMODB_TABLE }}
    secrets: inherit

  plan:
    name: Plan
    needs: [setup, validate]
    if: github.event_name == 'pull_request' || github.event_name == 'push' || github.event.inputs.action == 'plan' || github.event.inputs.action == 'apply' || github.event.inputs.action == 'destroy'
    uses: your-org/pipeline-templates/.github/workflows/Terraform/AWS/workflows/plan.yml@main
    with:
      environment: ${{ github.event.inputs.environment || 'staging' }}
      var-file: ${{ github.event.inputs.environment || 'staging' }}.tfvars
      destroy: ${{ github.event.inputs.action == 'destroy' }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      aws-region: ${{ vars.AWS_REGION }}
      backend-bucket: ${{ vars.BACKEND_BUCKET }}
      backend-key: ${{ vars.BACKEND_KEY }}
      backend-region: ${{ vars.BACKEND_REGION }}
      backend-dynamodb-table: ${{ vars.BACKEND_DYNAMODB_TABLE }}
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
    uses: your-org/pipeline-templates/.github/workflows/Terraform/AWS/workflows/apply.yml@main
    with:
      environment: ${{ github.event.inputs.environment }}
      terraform-version: '1.7.0'
      working-directory: './terraform'
      aws-region: ${{ vars.AWS_REGION }}
      backend-bucket: ${{ vars.BACKEND_BUCKET }}
      backend-key: ${{ vars.BACKEND_KEY }}
      backend-region: ${{ vars.BACKEND_REGION }}
      backend-dynamodb-table: ${{ vars.BACKEND_DYNAMODB_TABLE }}
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

### Option 1: OIDC (Recommended)

Uses GitHub's OIDC provider to assume an IAM role without storing long-lived credentials.

**Required secrets:**
```
AWS_ROLE_ARN    # e.g., arn:aws:iam::123456789012:role/github-actions-role
```

**IAM Role Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:your-org/your-repo:*"
        }
      }
    }
  ]
}
```

### Option 2: Static Credentials

Uses AWS access keys (less secure, not recommended for production).

**Required secrets:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
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

**For OIDC authentication:**
```
AWS_ROLE_ARN    # Your IAM role ARN for GitHub Actions
```

**For static credentials (alternative):**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

### Step 3: Add Repository Variables

Go to **Settings → Secrets and variables → Actions → Variables**

```
AWS_REGION              # e.g., us-east-1
BACKEND_BUCKET          # e.g., my-terraform-state-bucket
BACKEND_KEY             # e.g., my-app/terraform.tfstate
BACKEND_REGION          # e.g., us-east-1 (can be different from AWS_REGION)
BACKEND_DYNAMODB_TABLE  # e.g., terraform-state-lock (optional but recommended)
```

### Step 4: Create S3 Backend Infrastructure

```bash
# Create S3 bucket for state
aws s3 mb s3://my-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket my-terraform-state-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms"}}]
  }'

# Create DynamoDB table for state locking (recommended)
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Customizing for Your Secrets

### Edit `plan.yml`

Find the `Terraform Plan` step and add your secrets:

```yaml
- name: Terraform Plan
  id: plan
  uses: ./.github/actions/terraform/aws/plan
  with:
    working-directory: ${{ inputs.working-directory }}
    var-file: ${{ inputs.var-file }}
    destroy: ${{ inputs.destroy }}
  env:
    # Add all your TF_VAR_* secrets here
    TF_VAR_database_password: ${{ secrets.DATABASE_PASSWORD }}
    TF_VAR_api_key: ${{ secrets.API_KEY }}
    TF_VAR_redis_auth_token: ${{ secrets.REDIS_AUTH_TOKEN }}
```

### Edit `apply.yml`

Add the **exact same** `env:` block to the `Terraform Apply` step:

```yaml
- name: Terraform Apply
  uses: ./.github/actions/terraform/aws/apply
  with:
    working-directory: ${{ inputs.working-directory }}
  env:
    # Must match plan.yml exactly
    TF_VAR_database_password: ${{ secrets.DATABASE_PASSWORD }}
    TF_VAR_api_key: ${{ secrets.API_KEY }}
    TF_VAR_redis_auth_token: ${{ secrets.REDIS_AUTH_TOKEN }}
```

## Pre and Post Steps

Each workflow supports optional `pre-step` and `post-step` inputs for custom logic.

### Example: Health Check After Apply

```yaml
jobs:
  apply:
    uses: your-org/pipeline-templates/.github/workflows/Terraform/AWS/workflows/apply.yml@main
    with:
      environment: staging
      aws-region: us-east-1
      backend-bucket: ${{ vars.BACKEND_BUCKET }}
      backend-key: ${{ vars.BACKEND_KEY }}
      backend-region: ${{ vars.BACKEND_REGION }}
      template-repo: 'your-org/pipeline-templates'
      post-step: |
        echo "🏥 Running post-deployment health checks..."

        # Wait for services to stabilize
        sleep 30

        # Check API health
        curl -f https://api.staging.example.com/health || exit 1

        # Send Slack notification
        curl -X POST https://slack.com/api/chat.postMessage \
          -H "Authorization: Bearer ${{ secrets.SLACK_TOKEN }}" \
          -d "text=✅ Deployment to staging complete!"

        echo "✅ All health checks passed"
    secrets: inherit
```

### Example: Pre-Apply Backup

```yaml
jobs:
  apply:
    uses: your-org/pipeline-templates/.github/workflows/Terraform/AWS/workflows/apply.yml@main
    with:
      environment: production
      aws-region: us-east-1
      backend-bucket: ${{ vars.BACKEND_BUCKET }}
      backend-key: ${{ vars.BACKEND_KEY }}
      backend-region: ${{ vars.BACKEND_REGION }}
      template-repo: 'your-org/pipeline-templates'
      pre-step: |
        echo "🔒 Pre-apply safety checks for PRODUCTION..."

        # Create backup of current state
        aws s3 cp s3://${{ vars.BACKEND_BUCKET }}/${{ vars.BACKEND_KEY }} \
          s3://${{ vars.BACKEND_BUCKET }}/backups/$(date +%Y%m%d-%H%M%S).tfstate

        # Check for active incidents
        incident_count=$(curl -s https://monitoring.example.com/api/incidents/active | jq length)
        if [ $incident_count -gt 0 ]; then
          echo "❌ Active incidents detected. Aborting deployment."
          exit 1
        fi

        echo "✅ All pre-apply checks passed"
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

**What runs:**
1. ✅ Validate
2. ✅ Plan
3. ⏸️ Approve (waits for manual approval if configured)
4. ✅ Apply

### Example 3: Destroy Non-Prod Environment

1. **Actions → Run workflow**
2. Environment: `staging`
3. Action: `destroy`
4. **Run workflow**

**What runs:**
1. ✅ Validate
2. ✅ Destroy Plan (shows what will be destroyed)
3. ⏸️ Approve (manual confirmation required)
4. 🗑️ Destroy

## Versioning

Pin to specific versions for stability:

```yaml
# Use latest
uses: your-org/pipeline-templates/.github/workflows/Terraform/AWS/workflows/plan.yml@main

# Use specific tag
uses: your-org/pipeline-templates/.github/workflows/Terraform/AWS/workflows/plan.yml@v1.0.0

# Use specific commit
uses: your-org/pipeline-templates/.github/workflows/Terraform/AWS/workflows/plan.yml@abc1234
```

## Troubleshooting

### Error: "Access Denied" during init

**Problem:** IAM permissions insufficient for S3/DynamoDB access.

**Solution:** Ensure your IAM role/user has these permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-terraform-state-bucket",
        "arn:aws:s3:::my-terraform-state-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-state-lock"
    }
  ]
}
```

### Error: "No such file or directory: staging.tfvars"

**Problem:** Var file path doesn't match what's configured.

**Solution:**
- Ensure `staging.tfvars` and `prod.tfvars` (or `production.tfvars`) exist in `terraform/` directory
- Update `var-file` input if using different names

### Error: "Could not assume role"

**Problem:** OIDC trust policy not configured correctly.

**Solution:**
- Verify the trust policy includes your repository
- Check that `id-token: write` permission is set in the workflow
- Ensure the OIDC provider is configured in AWS IAM

### Plan shows "No changes"

**Problem:** No Terraform changes detected.

**This is normal** - means infrastructure matches code. Apply job will be skipped.

## Features

- **Modular**: Each component is independently reusable
- **Multi-environment**: Supports staging, production, etc.
- **Dual authentication**: OIDC (recommended) or static credentials
- **State locking**: DynamoDB support for safe concurrent access
- **Action choices**: validate, plan, apply, destroy
- **Safety**: Production restrictions, destroy prevention, manual approvals
- **Automated**: Runs validate + plan on push/PR
