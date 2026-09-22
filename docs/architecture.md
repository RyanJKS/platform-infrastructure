# Architecture

## Repository boundaries

`infrastructure/aws/root.hcl` and `infrastructure/azure/root.hcl` independently configure catalog
access, the supported Terragrunt version, and inherited folder settings.

General-purpose reusable Terraform modules and catalog templates belong in
[platform-blueprints](https://github.com/RyanJKS/platform-blueprints).
This consuming repository holds pinned module references, deployment inputs,
cloud-specific provider and backend configuration, and operational documentation.
It also contains repository-local Azure modules. The
[base Entra groups module](azure-groups.md) creates the platform's named security
groups and their nested memberships; permission assignments remain separate.
The initial catalog entry is a generic Terragrunt unit template, not a cloud
module. Catalog discovery requires publication of that entry.

## Deployment boundaries

Units live beneath `infrastructure/<cloud>/live/<account-or-subscription>/<environment>/<region>/<spoke>`.
Each spoke has `platform/<unit>` for shared infrastructure and
`applications/<solution>/<unit>` for application resources. The current spoke is
`spoke-atlas`. Azure reserves separate hub subscriptions at
`infrastructure/azure/live/DEV-HUB/dev/eus2/hub/` and
`infrastructure/azure/live/PROD-HUB/prod/eus2/hub/`; workload subscriptions
contain their spokes. Each hub can serve multiple subscriptions within its own
environment, with cross-subscription peering and DNS ownership to be defined
during implementation. Both subscription IDs are unset, and hub units remain
documentation placeholders.
AWS retains its existing account-local hub placeholders.
Use `global` where resources have no regional placement. Each unit directly
includes its cloud root; there are no nested includes.

Folder separation does not isolate deployments. Each unit needs its own remote
state key containing the complete path relative to its cloud root, including the
account/subscription and solution. Backend access policies and cloud identity
must enforce the intended boundaries. Separate production and development cloud
accounts or subscriptions wherever practical, retaining environment folders
within those boundaries.

AWS and Azure require separate authentication and backend configuration. Moving
or renaming any part of a unit path changes its derived state key; treat this as
a state migration requiring a reviewed procedure, not a directory-only change.
No state migration or backend bootstrapping is performed by this setup.

## Additional clouds

When GCP is needed, add `infrastructure/gcp/root.hcl` and use
`live/<project>/<environment>/<region>/<spoke>/platform/<unit>/terragrunt.hcl`
or the corresponding `applications/<solution>/<unit>` branch below it.
Configure GCP identity and an existing GCS backend in that root, retaining the
project boundary in each state key. Each GCP unit must include the GCP root
directly. Other providers can follow the same pattern without shared layers.

See the [deployment guide](terragrunt.md) for configuration requirements and
unit-scoped operations. `.github/workflows/ci.yaml` performs offline HCL checks
and documentation validation; it does not deploy infrastructure.

## Settings inheritance

Cloud roots read identity, environment, region, spoke, category, and unit settings.
Application units also require solution settings; platform units skip that level.
Inputs merge from broadest to narrowest scope, with a separate merge for tags.
Units still include only their cloud root. These settings do not configure cloud
authentication, providers, remote state, or resource dependencies. See the
[deployment guide](terragrunt.md#shared-platform-and-application-settings) for
precedence and module requirements.

## Azure workflow execution

Manual `azure-provision.yml` and `azure-deprovision.yml` workflows share the
`azure-unit.yml` implementation. Inputs select one existing unit. Planning uses
an Azure OIDC identity; applying the saved plan requires a separate GitHub
environment with required reviewers. Both operations share per-unit concurrency
and require an existing Azure remote backend with a path-derived state key.
See [Azure pipelines](azure-pipelines.md) for setup, permissions, and recovery.
