# AWS Terraform Pipeline Example (Dry Run Demo)

This example demonstrates the Terraform pipeline flow **without requiring any cloud credentials**. It uses the `null` and `random` providers with a local backend, so no real infrastructure is provisioned.

## Structure

```
example/
├── .github/
│   └── workflows/
│       └── terraform.yml    # Self-contained demo pipeline
├── terraform/
│   ├── main.tf              # Uses null/random providers (no real resources)
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf           # Output definitions
│   ├── staging.tfvars       # Staging environment values
│   └── production.tfvars    # Production environment values
└── README.md
```

## What This Demo Does

This example simulates infrastructure without creating anything real:

- **random_id**: Generates a random identifier
- **null_resource.example**: Simulates a main resource
- **null_resource.app_server**: Simulates multiple app server instances
- **null_resource.database**: Simulates a database (optional)

The pipeline will:
1. **Validate** - Check Terraform syntax and configuration
2. **Plan** - Show what would be created/changed
3. **Apply** - Execute the plan (just runs local-exec echo commands)

## Running the Pipeline

### No Setup Required

This demo works out of the box - no secrets, variables, or cloud credentials needed.

### Automatic (on PR/push)

Push changes to `Terraform/AWS/example/**` and the pipeline will automatically run validate + plan.

### Manual Run

1. Go to **Actions** tab
2. Select **Terraform Pipeline (Demo)**
3. Click **Run workflow**
4. Choose:
   - Environment: `staging` or `production`
   - Action: `validate`, `plan`, or `apply`
5. Click **Run workflow**

## Local Testing

Test the Terraform locally:

```bash
cd Terraform/AWS/example/terraform

# Initialize
terraform init

# Plan with staging vars
terraform plan -var-file=staging.tfvars

# Apply (safe - only runs echo commands)
terraform apply -var-file=staging.tfvars

# See outputs
terraform output

# Destroy
terraform destroy -var-file=staging.tfvars
```

## For Real AWS Deployments

This demo is for testing the pipeline flow. For actual AWS infrastructure:

1. See the main [AWS README](../README.md) for the full setup guide
2. Use the reusable workflows with proper AWS authentication (OIDC or static credentials)
3. Configure S3 backend for remote state storage
4. Set up GitHub environments with required reviewers for production
