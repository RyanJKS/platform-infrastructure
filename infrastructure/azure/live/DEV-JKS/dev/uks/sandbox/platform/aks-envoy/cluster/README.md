# Envoy AKS cluster

Virtual Nodes v2 is a future reference for this cluster. No active
`cluster_virtual_node` Terragrunt unit or v2 registry role assignment is included.
The v1 ACI addon remains disabled with `aci_connector_linux = null`.

## Requirements before enabling Virtual Nodes v2

Read the current [Microsoft Virtual Nodes v2 guide](https://learn.microsoft.com/en-us/azure/aks/virtual-nodes-v2),
including its [limitations](https://learn.microsoft.com/en-us/azure/aks/virtual-nodes-v2#limitations)
and [prerequisites](https://learn.microsoft.com/en-us/azure/aks/virtual-nodes-v2#prerequisites).
The current preview does not support this cluster's Azure CNI Overlay network
or its caller-supplied VNet subnet. Do not enable the extension on the current
configuration. Recheck Microsoft's support matrix before using this reference.

To prepare this cluster:

1. Change `network_profile` to Azure CNI in node-subnet mode. Remove Overlay by
   setting `network_plugin_mode = null`. Use Calico or no network policy;
   Cilium and Azure NPM are unsupported by the current v2 preview.
2. Replace the BYO VNet topology with a supported AKS-managed network. Remove
   the existing `default_node_pool.vnet_subnet_id` reference to `aksnet-001` by
   setting it to `null`. Review additional pool subnet overrides, VNet-dependent
   workloads, and the old subnet permissions in
   [cluster_identity_rbacs](../cluster_identity_rbacs/terragrunt.hcl).
   Removing Overlay alone does not remove the BYO VNet limitation.
3. Provide at least one node pool with 4 vCPUs and 16 GiB memory. For example,
   change the default pool from `Standard_D2_v5` to `Standard_D4_v5`.
   Each virtual node reserves about 3 vCPUs and 12 GiB on an AKS node.
4. Keep OIDC and workload identity enabled, and keep the v1 ACI addon disabled.
   V2 does not use the existing `acisnet-001` delegation or the v1 connector's
   subnet role assignment.

Update these fields inside the existing `inputs` map in
[terragrunt.hcl](terragrunt.hcl), keeping the other cluster inputs:

```hcl
default_node_pool = {
  vm_size              = "Standard_D4_v5"
  auto_scaling_enabled = true
  min_count            = 1
  max_count            = 5
  max_pods             = 30
  vnet_subnet_id       = null
}

network_profile = {
  network_plugin      = "azure"
  network_plugin_mode = null
  network_policy      = null
}

oidc_issuer_enabled       = true
workload_identity_enabled = true
aci_connector_linux       = null
```

These are proposed inputs, not an in-place migration procedure. Review the
Terraform plan for cluster replacement and plan the workload and network
migration before applying them. If v1 hosts workloads, drain or remove those
workloads before disabling its addon.

Register `Microsoft.ContainerInstance` in the target subscription. Follow the
Microsoft guide for any required Kubernetes configuration provider registration.

## Future extension unit

After preparing and applying a supported cluster, create
`../cluster_virtual_node/terragrunt.hcl` as a sibling of this `cluster/` directory.
The following is the extension code saved for future use. Do not paste it over
this cluster's `terragrunt.hcl`.

It uses the shared `aks_extension_version` ref, currently `feat/sandbox`.
Publish the blueprint changes exposing `aks_assigned_identity` on that branch
before consuming the identity for RBAC, or select a verified release that
includes that output.

```hcl
terraform {
  source = "${include.repo_urls.locals.platform_blueprints_github_url}//terraform/azure/aks/extension?ref=${urlencode(include.envcommon.locals.aks_extension_version)}"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "repo_urls" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/repo-urls.hcl"
  expose = true
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/module-versions.hcl"
  expose = true
}

dependency "solution_settings" {
  config_path = "../../solution_settings"

  mock_outputs = include.root.locals.mocks.solution_settings[include.root.locals.domain_name]

  mock_outputs_allowed_terraform_commands = include.root.locals.mocks.allowed_commands
  mock_outputs_merge_strategy_with_state  = "deep_map_only"
}

dependency "aks_cluster" {
  config_path = "../cluster"

  mock_outputs = include.root.locals.mocks.aks_cluster

  mock_outputs_allowed_terraform_commands = include.root.locals.mocks.allowed_commands
  mock_outputs_merge_strategy_with_state  = "shallow"
}

inputs = {
  settings   = dependency.solution_settings.outputs.settings
  cluster_id = dependency.aks_cluster.outputs.id

  # Requires a supported network topology and sufficient node capacity; see docs/terragrunt.md.
  extension = {
    name              = "virtualnodes-v2"
    extension_type    = "Microsoft.virtualnodes"
    release_namespace = "vn-system"

    configuration_settings = {
      replicaCount = "1"
    }
  }
}
```

## Future registry role assignment

For private ACR images, grant `AcrPull` to the extension's generated managed
identity. The kubelet identity's existing `AcrPull` assignment does not cover
Virtual Nodes v2. The `aks/extension` module exposes this identity as
`aks_assigned_identity`, or `null` when Azure assigns none; v2 requires a
non-null identity for this assignment.

After restoring the extension unit, add this dependency to
[rbacs/terragrunt.hcl](../rbacs/terragrunt.hcl):

```hcl
dependency "cluster_virtual_node" {
  config_path = "../cluster_virtual_node"

  mock_outputs = {
    aks_assigned_identity = {
      principal_id = include.root.locals.mocks.zero_uuid
    }
  }

  mock_outputs_allowed_terraform_commands = include.root.locals.mocks.allowed_commands
  mock_outputs_merge_strategy_with_state  = "shallow"
}
```

Add this entry inside that unit's existing `inputs.assignments` map, keeping the
other assignments:

```hcl
virtual_node_acr = {
  scope                            = dependency.container_registry.outputs.id
  principal_id                     = dependency.cluster_virtual_node.outputs.aks_assigned_identity.principal_id
  type                             = "ServicePrincipal"
  role_definition_name             = "AcrPull"
  skip_service_principal_aad_check = true
}
```

Apply the extension before planning and applying RBAC so its real identity is
available in state. The mock identity is only for validation and planning.
Allow time for the role assignment to propagate before pulling private images.
Do not restore the v1 `aci_uami_network` assignment or use `connector_identity`.

## Verify future deployment

Confirm the Azure extension reports `provisioningState: Succeeded`, then check:

```sh
kubectl get pods --namespace vn-system
```

Workloads targeting v2 use the `virtualization: virtualnode2` node selector and
a `NoSchedule` toleration with key `virtual-kubelet.io/provider` and operator
`Exists`. Follow the Microsoft guide for the complete workload example and
troubleshooting. Delete workloads running on virtual nodes before removing the
extension to avoid leaving billable ACI container groups behind.
