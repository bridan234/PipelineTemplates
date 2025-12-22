# CI/CD Pipeline Templates

Modular, reusable GitHub Actions workflow templates for various project types.

## Structure

```
PipelineTemplates/
├── Terraform/
│   ├── Azure/          # Azure-specific Terraform pipelines
│   │   ├── actions/    # Composite actions (setup, init, validate, plan, apply)
│   │   └── workflows/  # Reusable workflows
│   ├── AWS/            # AWS-specific (coming soon)
│   └── GCP/            # GCP-specific (coming soon)
└── README.md
```

## Usage

Each template is broken down into:
- **Composite Actions**: Small, reusable steps (e.g., setup, validate)
- **Reusable Workflows**: Complete jobs that can be called from other repos
- **Main Pipeline**: Full orchestrated workflow example

Choose your approach:
1. Copy complete pipeline for quick start
2. Reference reusable workflows for central management
3. Use composite actions for maximum flexibility

## Getting Started

Navigate to the specific cloud provider folder for detailed instructions:
- [Terraform Azure](./Terraform/Azure/README.md)
