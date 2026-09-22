# Azure provisioning and deprovisioning

Two manual GitHub Actions workflows operate on one Azure Terragrunt unit at a
time:

- `azure-provision.yml` creates a normal plan and optionally applies it.
- `azure-deprovision.yml` creates a destroy plan and optionally applies it.

Both call `azure-unit.yml` for target validation, tools, Azure OIDC login, planning,
and applying. These workflows support Azure only. They do not bootstrap backends,
scaffold modules, deploy all units, or provision the hub placeholders. Existing
settings-only examples cannot run until a real unit is configured.

## Repository and Azure setup

Merge the workflows to the repository's default branch before dispatching them.
The workflows reject runs from other branches.

1. Prepare the unit following the [deployment guide](terragrunt.md). Commit its
   `terragrunt.hcl` and `.terraform.lock.hcl`. Select an immutable module source,
   configure Azure providers, and use an existing `azurerm` remote backend. Ensure
   the lock file includes the Linux runner's provider checksums. Initialization
   uses `-lockfile=readonly` and never updates the committed lock file.
2. Set the repository variable `TERRAFORM_VERSION` to an exact reviewed version
   such as `1.13.5`, compatible with the selected modules and providers. Version
   ranges and `latest` are rejected. Terragrunt uses `.terragrunt-version` and its
   downloaded binary is verified against the release checksums.
3. Create two GitHub environments for each subscription/environment pair. For
   `DEV-JKS` and `dev`, the names are `azure-DEV-JKS-dev-plan` and
   `azure-DEV-JKS-dev-apply`. Configure required reviewers on the apply environment,
   prevent self-review where supported, and restrict deployment branches to the
   default branch. The workflow checks that environments exist and that an apply
   environment has required reviewers; it does not create them. Repository access
   to environment metadata is required. Required-reviewer availability depends
   on the GitHub plan and repository visibility.
4. Set `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` as variables
   on each GitHub environment. The subscription UUID must match the intended
   deployment subscription; the `DEV-JKS` directory is only a logical label.
   Use separate plan and apply identities if their permissions differ.
5. Configure an Azure federated identity credential for each environment identity.
   Use issuer `https://token.actions.githubusercontent.com`, audience
   `api://AzureADTokenExchange`, and the corresponding subject, for example
   `repo:OWNER/REPOSITORY:environment:azure-DEV-JKS-dev-plan` or
   `repo:OWNER/REPOSITORY:environment:azure-DEV-JKS-dev-apply`. No client secret is
   used. Azure login and Terraform use GitHub's OIDC token.
6. Grant the identities appropriate access to the deployment and existing state
   storage. Planning needs resource reads, state reads, and state locking access;
   applying needs the selected unit's resource creation, update, and deletion
   permissions as well. Configure Azure resource provider registration separately
   if the planning identity cannot perform it. Provide private module access
   separately if selected sources require authentication; these workflows do not
   configure cross-repository Git credentials.

The Azure backend must use the complete unit path relative to `infrastructure/azure` as its
state key, with `/terraform.tfstate` appended. For example:

```text
live/DEV-JKS/dev/uksouth/spoke-atlas/platform/vnet/terraform.tfstate
live/DEV-JKS/dev/uksouth/spoke-atlas/applications/orders/database/terraform.tfstate
```

After initialization, the workflow checks the backend type, storage account,
container, and exact state key before planning or applying. Local state is
rejected. Existing backend storage must already be provisioned. Configure backend
Azure AD/OIDC authentication; the workflows set `ARM_USE_OIDC` and
`ARM_USE_AZUREAD`. Backend storage can be in a separate subscription when explicitly
configured in the unit. Provider subscription selection still needs review.

## Select a unit

Open **Actions**, choose **Azure provision** or **Azure deprovision**, and select
**Run workflow** on the default branch.

| Input | Platform example | Application example |
| --- | --- | --- |
| `subscription` | `DEV-JKS` | `DEV-JKS` |
| `environment` | `dev` | `dev` |
| `region` | `uksouth` | `uksouth` |
| `scope` | `spoke-atlas` | `spoke-atlas` |
| `category` | `platform` | `applications` |
| `application` | Leave empty | `orders` |
| `unit` | `vnet` | `database` |
| `action` | `plan` or `apply` | `plan` or `apply` |

Every folder input must be a single name containing letters, numbers, underscores,
or hyphens, starting with a letter or number. Paths, shell expressions, and
symlinked targets are rejected. Applications require a solution name; platform
units must leave it empty. The workflow resolves these inputs to the existing
unit directory. A hub README or a directory containing only `unit.hcl` is not a
valid target.

`action=plan` is the default and changes no infrastructure. `action=apply` creates
a fresh saved plan, then waits for the apply environment's approval before applying
that exact plan. Inspect the plan job logs and target/commit summary before
approving. There is no separate "apply previous run" input. Both jobs check out
the same workflow commit and use the same resolved Terraform version.

## Destroy a unit

Use **Azure deprovision** with `action=plan` to review a destroy preview. To request
execution, run it with `action=apply` and set `confirmation` to the exact
repository-relative directory, for example:

```text
infrastructure/azure/live/DEV-JKS/dev/uksouth/spoke-atlas/applications/orders/database
```

The workflow rejects missing or mismatched confirmation before accessing Azure.
It then runs `plan -destroy`, waits for the same protected apply environment, and
applies the saved destroy plan. Approval authorizes deletion of the resources
shown in that plan. Dependencies and deletion order are not orchestrated: remove
consumers before shared networking or services, and review remaining dependencies
before approving destruction.

## Concurrency, artifacts, and recovery

Provisioning and deprovisioning share a concurrency group per selected unit,
including time spent awaiting approval. An active run is not automatically
cancelled by a newer run. GitHub concurrency is not a durable FIFO queue: newer
pending runs can replace older pending runs. Different units can run concurrently;
backend locking also protects the selected state. Coordinate cross-unit changes
and dependencies separately.

Saved plans are uploaded as artifacts retained for one day. Plan files can contain
sensitive values; restrict repository and artifact access accordingly. Approve
within that window or start a new run. Artifacts include the run ID and attempt,
so rerunning only the apply job cannot silently reuse a previous attempt's plan;
rerun the whole workflow to generate a fresh plan.

On failed or interrupted apply, inspect Azure resources and remote state, then
start a new plan. Do not assume a failed job rolled back infrastructure. A stale
plan, changed backend, or state lock failure must be resolved before another apply.
Never bypass backend validation or substitute another unit's plan artifact.

## Development AKS sizing

The `DEV-JKS/dev/eus2/spoke-atlas/platform/aks_cluster` unit uses the AKS Free
tier and one `Standard_D4as_v5` system node (4 vCPUs and 16 GiB RAM), with
autoscaling disabled. These settings are explicit overrides in its
`terragrunt.hcl` inputs. A single node reduces development costs but does not
provide node redundancy; maintenance or a node failure can interrupt workloads.
The Free tier covers cluster management, not worker compute, storage, or networking.

Before provisioning, check the subscription's **Standard DASv5 Family vCPUs**
quota in **East US 2**. Allow 4 available vCPUs for the node, or 8 to accommodate
one additional surge node during upgrades. Request a total quota limit of
current family usage plus 8 for that headroom, and check that **Total Regional
vCPUs** also has sufficient capacity. Quota approval does not itself incur charges.

## Validation

Run the offline workflow helper tests and documentation build:

```sh
python3 -m unittest discover -s tests -v
mkdocs build --strict
```

Use Actionlint to validate `.github/workflows/azure-*.yml` when available. Offline
checks do not verify GitHub environment protections, Azure federation, permissions,
module access, or an actual cloud plan/apply. Those require configured real units
and a workflow run.
