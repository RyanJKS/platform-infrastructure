# Terragrunt deployments

## Status and tools

Cloud deployments require configured credentials and remote backends. Do not
plan a newly scaffolded unit until the prerequisites below are complete; without
a backend it could use local state. The optional [Azure state bootstrap](azure-bootstrap.md)
creates development state storage in DEV-HUB when run locally. Cloud roots do
not provision backend storage automatically or migrate state.

Use **Terragrunt v1.1.5**, pinned in `.terragrunt-version` and required by both
cloud roots. Install the matching release for your platform and verify its
published checksum using the [release assets](https://github.com/gruntwork-io/terragrunt/releases/tag/v1.1.5).
Version managers that support `.terragrunt-version` can read the pin; the file
alone does not install Terragrunt. Verify with `terragrunt --version`.

This version supports standalone **Template** discovery in the Catalog TUI;
v0.71.1 does not. Discovery of the local blueprint template was verified using
v1.1.5. Select a Terraform version compatible with the chosen module and its
provider constraints before deployment; no module has been selected yet.
Commit the unit's `.terraform.lock.hcl` to retain reviewed provider selections.

## Directory layout

Each cloud lives under `infrastructure/<cloud>/`, with `root.hcl`, `_envcommon/`,
`modules/`, and `live/` as siblings. `_envcommon/` is reserved for shared
Terragrunt configuration; `modules/` holds repository-local Terraform modules,
including Azure's [base Entra groups](azure-groups.md). General-purpose reusable
modules remain in `platform-blueprints`. Accounts and subscriptions live under `live/`.

Each region groups resources by domain. Each domain is a spoke in the network
topology. Within a domain, `platform/` owns shared networking and services; `applications/` groups application solutions. Platform
units sit directly beneath `platform/`. Application units have an extra solution
level. Representative paths are:

```text
infrastructure/<cloud>/live/<account-or-subscription>/<environment>/<region>/<domain>/platform/<unit>/terragrunt.hcl
infrastructure/<cloud>/live/<account-or-subscription>/<environment>/<region>/<domain>/applications/<solution>/<unit>/terragrunt.hcl
```

The current domain is `atlas`, configured in `atlas/domain.hcl`.
AWS uses `example-account/dev/eu-west-2`;
Azure uses `DEV-JKS/dev/eus2` for workloads and `DEV-HUB/dev/eus2` and `PROD-HUB/prod/eus2` for hub placeholders. Folder names do not select or authenticate cloud
identities. Review the account/subscription settings before deployment. Use
separate cloud accounts or subscriptions for production and development where
practical. Use `global` for resources without regional placement.

Each unit includes its cloud root directly:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}
```

Do not introduce intermediate roots or nested includes. Future clouds can use
the same domain layout with their own identity settings and cloud root.

## Shared platform and application settings

The Azure tree separates development and production hub subscriptions from workload subscriptions.
AWS retains its existing account-local hub placeholders and uses `account.hcl`,
`environment.hcl`, `example-account`, and `eu-west-2`.

```text
infrastructure/azure/
  root.hcl
  _envcommon/
  modules/
  live/
    PROD-JKS/
      README.md
    DEV-HUB/
      subscription.hcl
      dev/
        env.hcl
        eus2/
          region.hcl
          hub/
            README.md
            platform/
              vnet/README.md
              firewall/README.md
              private-dns/README.md
              monitoring/README.md
    PROD-HUB/
      subscription.hcl
      prod/
        env.hcl
        eus2/
          region.hcl
          hub/
            README.md
            platform/
              vnet/README.md
              firewall/README.md
              private-dns/README.md
              monitoring/README.md
    DEV-JKS/
      subscription.hcl
      dev/
        env.hcl
        eus2/
          region.hcl
          atlas/
            domain.hcl
            platform/
              category.hcl
              resource_group/terragrunt.hcl
            applications/
              category.hcl
              orders/
                solution.hcl
                database/unit.hcl
                app/unit.hcl
```

`PROD-JKS/` reserves the production subscription with a README placeholder only;
its identity, environment settings, and deployment units are not configured.

Azure subscription settings define `locals.division` as an organisational label:
`JKS` for `DEV-JKS`, and `HUB` for `DEV-HUB` and `PROD-HUB`. Set this value in
`subscription.hcl` when adding a subscription. The Azure `root.hcl` exposes it as
`local.division` and passes it through the subscription locals merged into
Terraform inputs. Modules must declare and use a `division` variable to consume
the input; the label does not select a subscription or automatically tag resources.

`DEV-HUB` and `PROD-HUB` reserve separate hubs for development and production.
Each can serve multiple workload subscriptions within its environment; workload
subscriptions retain their spokes. Both hub subscription IDs are deliberately
unset; configure the real IDs before implementation.
Cross-subscription peering and private DNS links still need explicit configuration
and permissions, with ownership defined for both peering directions and DNS links.
No hub resources or connections are deployed by this layout.

Azure uses `env.hcl` and direct locals, which its cloud root reads. Add hub-aware
inheritance before scaffolding hub units: the current root requires `domain.hcl`,
which hub placeholders do not provide.

`orders` is an example application name. Add more application solutions beneath
`atlas/applications/`, or add another domain beside `atlas` with its own
settings, platform units, and applications. Keep actual account/subscription
boundaries above the domain. The Azure hub READMEs under `DEV-HUB/dev/eus2/` and `PROD-HUB/prod/eus2/`,
and the AWS account-local hub README
record that hub setup is required; it documents proposed unit folders under `hub/platform/`, with no deployable HCL.
There is no hub peering configuration yet.

AWS settings files define `locals.inputs`. The root reads ancestor settings
with `read_terragrunt_config` and `find_in_parent_folders`; it reads `unit.hcl`
from `get_original_terragrunt_dir()`, the directory of the consuming unit.
Settings files are data files, not intermediate includes.

AWS inputs merge in this order: account, environment, region, domain,
category, solution (applications only), unit. Later values override earlier
values. Platform units skip solution settings entirely. Application units
require `solution.hcl` in the AWS hierarchy; missing required settings fail configuration loading.
Azure merges direct locals from subscription, environment, region, and domain
settings into its inputs. The Azure root defaults `solution_name` to `null` when `solution.hcl` is absent.
Azure platform units use `domain_name` from `domain.hcl`, exposed as
`include.root.locals.domain_name`, for resource name prefixes and solution labels.
Its `find_in_parent_folders` call supplies a fallback path so a missing ancestor
does not throw before `read_terragrunt_config` can return its default locals.
Set `category` to `platform` or `applications` in the corresponding `category.hcl`.

The `tags` map merges separately in the same order, preserving unrelated inherited
tags. Other maps are replaced, not recursively merged. Explicit `inputs` in a
unit's `terragrunt.hcl` override root inputs with the default include merge; an
explicit unit `tags` input replaces the inherited map. Prefer putting unit tags
in `unit.hcl`.

Shared values include `account_name` or `subscription_name`, `environment`, AWS
`region` or Azure `location`, `domain_name`, `category`, `unit`, and `tags`. Application
units also inherit `solution`. Terraform modules must declare and use the
corresponding variables; these inputs do not configure providers, authenticate
cloud identities, or automatically tag resources. Add module-specific values to
the appropriate settings file instead of repeating shared values in every unit.

Spoke platform units own the shared VNet/VPC and monitoring. Keep subnets with
their VNet/VPC unless separate ownership or lifecycle requires separate units.
Applications can consume platform outputs through Terragrunt dependencies once
real modules exist. Folder placement does not connect resources or establish
execution dependencies. Future hub connectivity needs its own reviewed routing,
DNS, firewall, and peering design, with one owner for each connection.

Only settings files are checked in, not deployable `terragrunt.hcl` files. Keep
`unit.hcl` when scaffolding into these directories and review generated files
before planning. Preserve the direct root include. If a template requires an
empty directory, scaffold into a temporary directory, review the output, and
copy the unit files beside `unit.hcl`.

## First plan for the UKS platform

Dependency blocks already define the execution order. `terragrunt run --all plan`
does not apply upstream units or save their planned outputs to state. On a fresh
stack, downstream units therefore need mock outputs to evaluate their inputs.
An `Unknown variable` diagnostic for `dependency` can follow an earlier failure
to read those outputs; inspect the first upstream error as well.

The DEV-JKS development UKS units share mock outputs from
`infrastructure/azure/_mocks/outputs.hcl`. The Azure `root.hcl` loads this file with
`read_terragrunt_config` and exposes its locals through `include.root.locals.mocks`.
The file contains fixtures for resource groups, solution settings, AKS, DNS,
VNet subnet IDs, and Entra group IDs, plus the allowed commands. Solution settings
are keyed by domain, so `atlas` and `intro` use their own names and tags.
These fixtures describe development UKS only; add appropriate fixtures before
using them in another environment or region.

Keep dependency paths in each unit and reference the shared output schema:

```hcl
dependency "resource_group" {
  config_path = "../resource_group"

  mock_outputs = include.root.locals.mocks.resource_group

  mock_outputs_allowed_terraform_commands = include.root.locals.mocks.allowed_commands
  mock_outputs_merge_strategy_with_state  = "shallow"
}
```

For solution settings, use
`include.root.locals.mocks.solution_settings[include.root.locals.domain_name]`.
Edit the shared fixture when a module adds an output consumed by downstream units.
Keep the output names and types aligned with the producing module. Sharing mocks
does not create missing dependency units or resolve unrelated input errors.

Mocks are allowed only for `validate` and `plan`. The `shallow` merge strategy
preserves real top-level outputs and supplies mocks for missing outputs. Solution
settings, VNet, and Entra group dependencies use `deep_map_only` to also fill
missing nested map keys; lists are not merged. Keep `skip_outputs` unset so
Terragrunt reads real outputs when available. See the Terragrunt references for
[reading shared configuration](https://terragrunt.gruntwork.io/docs/reference/hcl/functions/#read_terragrunt_config)
and [dependency mocks and merge strategies](https://terragrunt.gruntwork.io/docs/reference/hcl/blocks/#dependency).

The `argocd_project_manifest` units use Terraform's `kubernetes_manifest`
resource. Its provider queries the live Kubernetes API during planning to discover
resource schemas, including Argo CD custom resources. Mock AKS outputs cannot
replace that API: the mock host `https://example.invalid` deliberately does not
resolve. Disabling refresh does not remove the schema-discovery requirement.

From `infrastructure/azure/live/DEV-JKS/dev/uks`, after configuring the deployment
prerequisites, exclude these units from the first infrastructure plan:

```sh
terragrunt run --all --filter '!**/argocd_project_manifest' plan
```

The filter excludes both domain manifest units and keeps AKS and its Argo CD
extension in the plan. A successful infrastructure plan does not create the cluster
or install the Argo CD custom resource definitions (CRDs). After applying the
required upstream infrastructure, verify that AKS outputs contain the real API
endpoint and credentials, that the API is reachable from the planning machine,
and that Argo CD CRDs are installed. Then include the manifest units in a fresh
plan:

```sh
terragrunt run --all plan
```

Apply requires real dependency outputs. A plan containing mock IDs is a preview;
after applying upstream units, create a fresh downstream plan with real outputs
before applying it. Do not apply a saved plan containing mock values.

An NSG skipped because its VNet failed is a downstream consequence. Fix the VNet
error first, including any missing address allocation described below.

## Azure VNet address allocations

Maintain Azure VNet address spaces in
`infrastructure/azure/_envcommon/network-addresses.hcl`. Edit only its flat
`locals.allocations` list, kept in numeric CIDR order. Each entry records `cidr`,
`subscription`, `environment`, `region`, and `domain`. Keep CIDRs explicit so adding
or reordering entries never renumbers existing networks.

The file derives `locals.address_spaces` from that list. This lookup map uses
`subscription_name`, `environment`, `region_short`, and `domain_name` from the
ancestor settings as keys, for example `DEV-JKS` / `dev` / `eus2` / `atlas`.
The domain key matches the domain directory name, such as `atlas` or `intro`.
Atlas uses `10.0.0.0/16` in EUS2 and `10.1.0.0/16` in UKS. The Atlas UKS subnets
are `10.1.1.0/24` and `10.1.2.0/24` for AKS, and `10.1.6.0/24` for application
integration.

Intro uses `10.2.0.0/16` in development UKS under `DEV-JKS`. Its AKS subnets are
`10.2.1.0/24` and `10.2.2.0/24`; application integration uses `10.2.6.0/24`.

The VNet unit exposes the file through a direct `include "network_addresses"`
block and reads `include.network_addresses.locals.address_spaces` using the
root's exposed locals; a missing key fails configuration loading. Entries with
the same subscription, environment, region, and domain are grouped into one list
of address spaces. Different environments remain separate even when their region
and domain names match.

Before adding a VNet, add its allocation to the list and review CIDRs for overlap
with networks it will connect to, including hubs and on-premises networks. Use
the same lookup in new VNet units rather than duplicating address spaces. Subnet
prefixes remain in each VNet unit and must fit within its allocation. Hub address
spaces are not reserved yet. Renaming a settings key requires updating the
corresponding allocation field. The list does not automatically select the next
free CIDR: check gaps against connected networks before assigning them.
Changing an allocated CIDR is an infrastructure change; review the Terraform plan
and connected networks before applying it. Centralisation does not automatically
validate overlaps or change existing address ranges.

## Catalog publication and versioning

### Azure module refs

`infrastructure/azure/_envcommon/module-versions.hcl` contains a single `locals`
block with Git refs named `aks_cluster`, `nsg`, `rbac`, `resource_group`,
`solution_settings`, and `vnet`. Each consuming unit includes this file directly,
alongside its root include:

```hcl
include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/module-versions.hcl"
  expose = true
}
```

Use `include.envcommon.locals.vnet` (or the appropriate module name) in the unit's
source URL, wrapped in `urlencode(...)`. Store raw Git refs in the shared file.
Module paths remain in each unit. The root does not load these shared refs, and
there is no automatic environment override or merge layer. Shared files contain
locals only and do not include other files. A unit needing multiple shared files
uses a distinct include label for each file.

Current refs preserve the existing `feature/azure-terraform-modules` branch;
centralisation does not make these refs immutable. Local modules continue using
their checkout paths. To upgrade a module, replace its shared ref with a verified
immutable release tag or full commit SHA, review the module interface, and test
plans for affected units. A shared ref change affects every unit consuming that
local. For a staged rollout, add a separate candidate local and explicitly select
it in the units being tested before promoting the shared ref. This file does not
pin Terraform, provider versions, or catalog discovery refs.

### Catalog discovery

The Azure root uses this checkout's local modules as its catalog:

```hcl
catalog {
  urls = [get_repo_root()]
}
```

Terragrunt v1.1.5 requires a local catalog path to identify a Git repository,
not a module directory. A bare `modules` is also not an HCL string. Pointing at
`get_repo_root()` works from nested unit directories; `.terragrunt-catalog-ignore`
limits discovery to `infrastructure/azure/modules/`. Both `base_aad_groups` and
`lookup` provide README frontmatter for their catalog titles and descriptions.
The ignore file affects catalog discovery, not Terraform execution or Git tracking.

From a target unit directory beneath `infrastructure/azure`, open the catalog:

```sh
terragrunt catalog --root-file-name root.hcl
```

To check discovery without the interactive interface, run from
`infrastructure/azure/modules/base_aad_groups`:

```sh
terragrunt catalog --root-file-name root.hcl --format jsonl --experiment catalog-format
```

This should list the two local modules. These entries use the working checkout,
so local edits are visible without publishing or committing them. Review generated
`terraform.source` paths before committing a scaffolded unit; absolute checkout
paths are machine-specific. The remote Azure catalog is currently commented out.
To include it again, uncomment its URL alongside `get_repo_root()`.

The AWS root still selects its remote catalog:

```hcl
catalog {
  urls = [
    "github.com/RyanJKS/platform-blueprints//terraform/aws",
  ]
}
```

The optional Azure remote catalog uses
`github.com/RyanJKS/platform-blueprints//terraform/azure`.

Remote catalog discovery requires the corresponding cloud directory to be published.
Before pinning a catalog, inspect its README and template contents at the
published revision. Verify that a full commit exists remotely and contains
`terraform/aws/` or `terraform/azure/`, then append
`?ref=<verified-full-commit-sha>` to the corresponding URL. For example,
`git ls-remote` can identify published branch or tag references, but inspect the
referenced tree as well. Do not paste a placeholder SHA or assume a tag exists.
Prefer a full commit SHA for immutability.

For an update, review upstream changes, verify the new published revision,
update both catalog URLs, and check discovery and scaffolding in a temporary
empty directory. Updating a catalog pin does not update existing units.

Module versions are independent: review and pin each unit's `terraform.source`
to a verified module release or full Git commit. For Git sources the shape is
`git::https://github.com/RyanJKS/platform-blueprints.git//<actual-module-path>?ref=<verified-module-commit>`.
These placeholders are explanatory, not usable module references. Another
explicitly selected module source is acceptable. Keep general-purpose reusable
module code in `platform-blueprints`; repository-specific modules such as the
base Entra groups module live under `infrastructure/<cloud>/modules/`.

## Authentication and remote state prerequisites

No backend or authentication conventions existed in this repository. Decide
and review these separately for each cloud before adding deployable units:

| Cloud | Authentication and provider configuration | Existing backend information required |
| --- | --- | --- |
| AWS | Approved SSO/profile or assumed role for local use; approved workload identity for CI. Confirm the target account and provider region. | S3 bucket, bucket region, encryption and locking policy, and backend access identity. |
| Azure | Approved Azure CLI identity for local use or workload identity for CI. Confirm tenant, target subscription, and AzureRM provider configuration. | Storage account, container, resource group where required by the backend's access method, state subscription/tenant, and approved Entra ID access. |

Provider and backend identities can differ; validate both. Do not commit
credentials or storage access keys. Use short-lived credentials and cloud-native
identity where practical. Backend owners must provision storage and access
controls before workload deployment. Use the standalone [Azure state bootstrap](azure-bootstrap.md)
to create development state storage in DEV-HUB; assign user and pipeline access
separately. AWS backend provisioning remains external.
Terraform/provider version selection must precede choosing
backend-specific locking options (such as S3 lockfiles).

Every unit must use a separate remote state key derived from its path relative
to its cloud root:

```hcl
"${path_relative_to_include("root")}/terraform.tfstate"
```

This yields:

```text
Platform:     live/<identity>/<environment>/<region>/<domain>/platform/<unit>/terraform.tfstate
Applications: live/<identity>/<environment>/<region>/<domain>/applications/<solution>/<unit>/terraform.tfstate
```

Never strip the account/subscription, environment, solution, or unit segments.
Use separate cloud backends and appropriate identity/access policies; different
folders or keys alone do not restrict access. If backends are split by account
or subscription, retain those segments in the keys anyway.

Once real backend details are known, add cloud-specific configuration to that
cloud root. One option is a Terragrunt `generate "backend"` block that writes a
Terraform `backend "s3"` or `backend "azurerm"` block, interpolating the key above
and approved backend settings. This uses existing storage through Terraform's
backend initialization without Terragrunt remote-state provisioning. Do not
add a `remote_state` configuration that can automatically create or update
backend resources. Require missing configuration values to fail rather than
falling back to local state or a shared key. Keep provider generation/configuration
cloud-specific too; do not add a cross-cloud include layer.

No backend snippets are active in the roots yet. Before planning, review the
rendered backend configuration, check the account/subscription and unique key,
and verify backend access. If existing state is involved, stop and design a
separate migration. Renaming any path segment changes the key and can make
Terraform see an empty state; never accept a resulting recreation plan blindly.

### Domain folder rename

Domain folders use `<domain>/domain.hcl`; the domain itself represents the spoke.
The Atlas folders were renamed from `spoke-atlas/` to `atlas/`, and both cloud
roots now read `domain.hcl`. AWS exposes `domain_name = "atlas"` and the `Domain`
tag through its inherited inputs. Azure retains `domain_name = "atlas"`.

For existing deployments, this rename changes path-derived state keys from
`.../spoke-atlas/.../terraform.tfstate` to `.../atlas/.../terraform.tfstate`.
Before planning or applying, coordinate a reviewed state migration for every
affected unit, back up existing state, and verify that the new key contains the
expected resources. This repository change does not move remote state. Update
workflow `scope` inputs and destroy confirmations to use `atlas`.

The UKS Argo CD source path also uses the domain without a `spoke-` prefix:
`clusters/azure/<subscription>/<environment>/<region>/<domain>/aks-shared/argocd`.
Move the matching manifests in the GitOps repository before applying that unit.

## Scaffold and plan one unit

1. Select a real module and verify its immutable reference, required inputs,
   Terraform/provider versions, and cloud compatibility. The initial
   **Terragrunt module unit** entry is a generic template, not an AWS or Azure
   module. It does not choose a real cloud module for you.
2. Configure the chosen cloud's authentication, provider settings, and existing
   remote backend as described above. Resolve account/subscription mappings and
   state access before any plan.
3. Copy or adapt the example settings hierarchy using reviewed deployment
   names. AWS uses `account.hcl`, `environment.hcl`, `region.hcl`, `domain.hcl`,
   `category.hcl`, and `unit.hcl` with `locals.inputs` at their respective levels.
   Azure uses `subscription.hcl`, `env.hcl`, `region.hcl`, and `domain.hcl`
   with direct locals. Application solutions use `solution.hcl`. Follow the
   existing settings for the chosen cloud. Enter the unit directory and keep
   `terragrunt.hcl` absent until scaffolding completes.
4. From the unit directory (without a `terragrunt.hcl` yet), run:

   ```sh
   terragrunt catalog --root-file-name root.hcl
   ```

5. Select the intended entry in the TUI and press `s` to scaffold. For the generic
   template, supply the real pinned module source and its inputs. Keep root
   inclusion enabled and review the resulting direct `include "root"` block.
   If nothing is found, verify catalog publication, its pin, repository access,
   and Terragrunt version. An unpublished catalog is not a deployment failure.
6. Review generated files, module inputs, provider identity, region, backend and
   key, dependency references, and any template hooks. Scaffolding can generate
   configuration but does not establish safe deployment settings. Keep secrets
   outside tracked HCL; ensure ignored plans and local configuration stay local.
7. Format and validate the selected unit, then plan **from that unit directory**
   only after the prerequisites are complete:

   ```sh
   terragrunt hcl format --check
   terragrunt hcl validate
   terragrunt run -- plan
   ```

   Planning can initialize the existing backend and download the pinned module
   and providers. Review the output without applying. Do not run repository-wide
   deployment commands by default. Inspect dependencies because dependency
   outputs may require additional state access even for a single-unit plan.

## Azure automation

The [Azure pipeline guide](azure-pipelines.md) describes the manual provisioning
and deprovisioning workflows, target inputs, OIDC setup, and required approvals.
Configure a real unit and remote backend before using them.

## Clear Terragrunt caches

With `just`, Bash, and `find` installed, run from the repository root:

```sh
just clean
```

This deletes all directories named `.terragrunt-cache` beneath `infrastructure/`.
Terragrunt recreates its caches on the next run.

## Validation

The root `.gitignore` holds repository-wide ignore rules, including the entire
`.serena/` directory for local Serena configuration and caches.

From the repository root, using the development dependencies in
`requirements-dev.txt` and Terragrunt v1.1.5:

```sh
pre-commit run --all-files
terragrunt hcl format --check
terragrunt hcl validate
mkdocs build --strict
```

Formatting covers the cloud roots and all folder settings. Until real units exist, recursive HCL
validation has no deployable unit graphs to validate; it does not prove that
backend or provider configuration is ready. Root parsing and direct inclusion
can also be checked using temporary child configurations outside the repository.

The strict MkDocs build includes `techdocs-core`; navigation and relative links
must resolve, and `catalog-info.yaml` must continue pointing to `dir:.`.
These checks do not prove Backstage publishing or cloud permissions.

Cloud authentication, backend access/locking, module/provider compatibility,
and a selected-unit plan remain deployment checks requiring real configuration.
No cloud plan or apply is part of the initial setup validation.
