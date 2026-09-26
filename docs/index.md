# Platform Infrastructure

This repository holds Terragrunt deployment configuration for AWS and Azure.
Reusable Terraform modules remain in
[platform-blueprints](https://github.com/RyanJKS/platform-blueprints); each unit
here will select a pinned module and supply deployment inputs.

Catalog-enabled cloud roots and inherited example folder settings are configured today. There are no deployable
units, cloud credentials, providers, or remote backends. The upcoming remote
catalog must be published before discovery can find its entries.

- [Deployment guide](terragrunt.md): directory layout, catalog workflow,
  authentication, state isolation, and checks before the first deployment.
- [Azure pipelines](azure-pipelines.md): manual unit provisioning, deprovisioning,
  Azure OIDC, and approval setup.
- [Architecture](architecture.md): repository boundaries and cloud separation.

Documentation is built with MkDocs and `techdocs-core`. Add pages to `mkdocs.yml`
to include them in navigation. Backstage reads the documentation through the
component's `backstage.io/techdocs-ref: dir:.` annotation.
