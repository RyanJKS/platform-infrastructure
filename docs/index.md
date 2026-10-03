# Platform Infrastructure

This repository holds Terragrunt deployment configuration for AWS and Azure.
Reusable Terraform modules remain in
[platform-blueprints](https://github.com/RyanJKS/platform-blueprints); each unit
here will select a pinned module and supply deployment inputs.

Catalog-enabled cloud roots and inherited folder settings are configured.
Cloud credentials and remote backends still require setup. The standalone Azure
state bootstrap creates development backend storage when run locally; workload
backend configuration and access remain separate.

- [Deployment guide](terragrunt.md): directory layout, catalog workflow,
  authentication, state isolation, and checks before the first deployment.
- [Azure state bootstrap](azure-bootstrap.md): create initial development state
  storage in DEV-HUB using local Terraform.
- [Azure pipelines](azure-pipelines.md): manual unit provisioning, deprovisioning,
  Azure OIDC, and approval setup.
- [Architecture](architecture.md): repository boundaries and cloud separation.

Documentation is built with MkDocs and `techdocs-core`. Add pages to `mkdocs.yml`
to include them in navigation. Backstage reads the documentation through the
component's `backstage.io/techdocs-ref: dir:.` annotation.
