# Platform Infrastructure

Deployment configuration for multi-cloud infrastructure managed with Terragrunt
and Terraform. Reusable Terraform modules belong in
[platform-blueprints](https://github.com/RyanJKS/platform-blueprints).

## Layout

Each cloud has sibling `root.hcl`, `_envcommon/`, `modules/`, and `live/` entries
under `infrastructure/<cloud>/`. The shared configuration and local module folders
are reserved placeholders; reusable modules remain in `platform-blueprints`.

```text
infrastructure/<cloud>/live/<account-or-subscription>/<environment>/<region>/
  region.hcl
  spoke-atlas/
    spoke.hcl
    platform/
      category.hcl
      <unit>/unit.hcl
    applications/
      category.hcl
      <solution>/
        solution.hcl
        <unit>/unit.hcl
```

AWS and Azure cloud roots load shared inputs from the folder settings. Spoke
platform units own networking and monitoring; application solutions contain
their own units. Azure reserves separate hub placeholders under
`infrastructure/azure/live/DEV-HUB/dev/eus2/hub/` and
`infrastructure/azure/live/PROD-HUB/prod/eus2/hub/`, separate from workload
subscriptions `DEV-JKS` and `PROD-JKS`. Hub setup remains a TODO, with no deployable
hub configuration. AWS retains its existing account-local hub placeholders.
See the [deployment guide](docs/terragrunt.md) for inheritance, precedence, and
the full example tree. Review identity settings before deployment.

## Getting started

Install **Terragrunt v1.1.5** (recorded in `.terragrunt-version`) and follow the
[deployment guide](docs/terragrunt.md) to select a real module, configure cloud
identity and an existing remote backend, and scaffold a unit. Both cloud roots
already reference the upcoming `platform-blueprints` catalog; remote discovery
requires that catalog to be published first.

From a unit directory beneath the appropriate cloud root, with its settings
files prepared and no `terragrunt.hcl` yet:

```sh
terragrunt catalog --root-file-name root.hcl
```

The initial entry is a generic unit template, not an AWS or Azure module. Pin the
selected module independently from the catalog. Do not plan until authentication,
provider configuration, inputs, and isolated remote state have been reviewed.

## Azure pipelines

Use the manual `azure-provision.yml` and `azure-deprovision.yml` workflows to
plan or apply one selected Azure unit. Configure Azure OIDC, remote state, and
GitHub environment approvals first; see the [pipeline guide](docs/azure-pipelines.md).
The current placeholder units are not deployable.

## Checks

With Python 3.12 and Terragrunt v1.1.5 installed, from the repository root:

```sh
python -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
pre-commit install
pre-commit run --all-files
terragrunt hcl format --check
terragrunt hcl validate
mkdocs build --strict
```

On Windows PowerShell, activate with `.venv\Scripts\Activate.ps1` instead.
These checks do not validate cloud access or a deployment plan. See
[architecture](docs/architecture.md), [contributing](CONTRIBUTING.md), and
[security reporting](SECURITY.md). Record changes in [CHANGELOG.md](CHANGELOG.md).
