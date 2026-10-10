# AKS Setup

| Area                       | Self-installed AGIC                        | `ingress_application_gateway {}`              |
| -------------------------- | ------------------------------------------ | --------------------------------------------- |
| Controller installation    | Helm, managed through Argo CD              | Installed by AKS                              |
| Controller upgrades        | You choose the chart/version               | Microsoft manages updates                     |
| AGIC UAMI                  | You create it                              | AKS creates the add-on UAMI                   |
| AGIC authentication        | You configure Workload Identity federation | AKS configures add-on authentication          |
| Gateway infrastructure     | You provision it in Terraform              | Can reference your existing Terraform gateway |
| ExternalDNS / cert-manager | You install and configure them             | Still your responsibility                     |

The managed add-on also offers fewer configuration options; for example, the Helm deployment supports sharing the gateway through prohibited targets, while the add-on does not.

For the UAMI used by AGIC, Azure’s installation guide specifies:

| Role            | Scope                                         | Purpose                                                                  |
| --------------- | --------------------------------------------- | ------------------------------------------------------------------------ |
| **Contributor** | Your Application Gateway resource             | Allows AGIC to update listeners, routing rules, backend pools and probes |
| **Reader**      | Resource group containing Application Gateway | Allows AGIC to read surrounding resource information                     |

This is valid:

```
agic_identity_operator = {
  principal_id         = dependency.agic_uami.outputs.principal_id
  scope                = dependency.agic_uami.outputs.id
  type                 = "ServicePrincipal"
  role_definition_name = "Managed Identity Operator"
}
```

It means: **“Allow AGIC, acting as this identity, to assign this UAMI to an Azure resource.”**

## Roles

| UAMI receiving permission | Azure role                    | Scope                                         | Why                                                                |
| ------------------------- | ----------------------------- | --------------------------------------------- | ------------------------------------------------------------------ |
| **Control plane**         | **Network Contributor**       | Each AKS node subnet you provision            | Allows AKS to manage networking on your existing subnets           |
| **Control plane**         | **Managed Identity Operator** | Your pre-created **kubelet UAMI resource ID** | Allows AKS to assign that identity to its nodes                    |
| **Kubelet**               | **AcrPull**, if using ACR     | Your **ACR resource ID**                      | Allows nodes to pull container images                              |
| **ExternalDNS**           | **DNS Zone Contributor**      | Your public **Azure DNS zone resource ID**    | Creates and updates application DNS records                        |
| **ExternalDNS**           | **Reader**                    | Resource group containing that DNS zone       | Allows discovery of DNS zones                                      |
| **Cert-manager**          | **DNS Zone Contributor**      | Your public **Azure DNS zone resource ID**    | Creates `_acme-challenge` TXT records for certificate validation   |
| **AGIC**                  | **Contributor**               | Your **Application Gateway resource ID**      | Updates gateway listeners, routing rules, backend pools and probes |
| **AGIC**                  | **Reader**                    | Resource group containing Application Gateway | Reads surrounding resource information                             |

## Cluster creation permissions

`cluster_identity_rbacs` assigns the control-plane identity `Network Contributor`
on the AKS node subnet and `Managed Identity Operator` on the kubelet identity.
These roles must exist before creating AKS. The cluster depends on this unit;
the downstream `rbacs` unit manages roles that require the cluster or workload
identities. If applying individual units, apply `cluster_identity_rbacs` first.
Azure RBAC propagation can delay recognition of a newly created assignment.
See the [deployment guide](../../../../../../../../../docs/terragrunt.md)
for the apply order and state ownership changes for existing deployments.

## Federation

**“Federation handles authentication” means it lets the pod prove to Microsoft Entra ID that it is allowed to act as a particular UAMI.** Azure RBAC then determines what that identity can do.

For example:

1. AKS issues a signed token identifying the pod’s ServiceAccount.
2. ExternalDNS presents that token to Microsoft Entra ID.
3. Entra checks the UAMI’s federated credential: does the token come from the trusted cluster and matching ServiceAccount?
4. Entra returns an Azure access token representing the **ExternalDNS UAMI**.
5. ExternalDNS uses that token to call Azure DNS. Azure checks the UAMI’s RBAC permissions. Microsoft Learn

**You do not need federation for every UAMI.**

| Your UAMI                            | AKS OIDC federation needed?           | Reason                                                  |
| ------------------------------------ | ------------------------------------- | ------------------------------------------------------- |
| Control plane                        | **No**                                | Used by the AKS platform                                |
| Kubelet                              | **No**                                | Used by the AKS nodes                                   |
| ExternalDNS                          | **Yes**                               | Used by a pod through its ServiceAccount                |
| Cert-manager                         | **Yes**, for Azure DNS DNS-01         | Used by the cert-manager controller pod                 |
| Self-installed AGIC                  | **Yes**, when using Workload Identity | Used by the AGIC pod                                    |
| AKS add-on AGIC                      | **You do not configure it yourself**  | AKS manages its authentication                          |
| UAMI attached to Application Gateway | **No**, for the gateway’s own use     | Application Gateway uses the attached identity directly |

Use the `azurerm_federated_identity_credential` block to create a trust rule on the UAMI:
`Allow tokens issued by this AKS cluster, for this exact Kubernetes ServiceAccount, to authenticate as this UAMI.`

For ExternalDNS UAMI module, example:

```hcl
federated_identity_credentials = {
  externaldns = {
    issuer   = dependency.aks.outputs.oidc_issuer_url
    subject  = "system:serviceaccount:external-dns:external-dns"
    audience = ["api://AzureADTokenExchange"]
  }
}
```

| Field                       | Meaning                                                                    |
| --------------------------- | -------------------------------------------------------------------------- |
| `user_assigned_identity_id` | Which UAMI the workload may authenticate as                                |
| `issuer`                    | Which AKS cluster’s signed tokens Entra trusts                             |
| `subject`                   | Exact permitted ServiceAccount: `system:serviceaccount:<namespace>:<name>` |
| `audience`                  | Expected token audience for the Azure token exchange                       |

**The namespace and ServiceAccount must match your actual deployment exactly.** For multiple controllers in the same cluster, the issuer URL stays the same, while each subject identifies its respective ServiceAccount.

**ExternalDNS, there are three separate pieces to configure.**

| Piece                    | Applied to                 | Required configuration                                                                        |
| ------------------------ | -------------------------- | --------------------------------------------------------------------------------------------- |
| Azure RBAC               | **ExternalDNS UAMI**       | `DNS Zone Contributor` on the DNS zone; `Reader` on the DNS resource group                    |
| Federation               | **ExternalDNS UAMI**       | AKS issuer URL + exact ExternalDNS ServiceAccount subject                                     |
| Kubernetes configuration | **ServiceAccount and pod** | UAMI client-ID annotation, workload-identity pod label, and the pod using that ServiceAccount |

## How to use

The Kubernetes configuration includes:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
  namespace: external-dns
  annotations:
    azure.workload.identity/client-id: "<EXTERNALDNS_UAMI_CLIENT_ID>"
```

And in ExternalDNS’s Deployment:

```yaml
spec:
  template:
    metadata:
      labels:
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: external-dns
```


## Terraform-owned Argo CD

`argocd_helm_manifest` reads the GitOps cluster's Helm release definition and its
ordered catalog/Azure/cluster values. `argocd_project_manifest` reads the cluster's
concrete `root_projects.yaml`, managing the seed projects before the root
Application. Terraform owns the installation and seed; Argo CD owns child apps.

Set repository URLs in [repo-urls.hcl](../../../../../../../_envcommon/repo-urls.hcl), or override the GitOps URL with
`GITOPS_REPO_URL`. `GITOPS_DIR` defaults to the sibling `platform-gitops` checkout.
Each Argo CD unit declares its cluster path locally.
Both generated providers declare Azure CLI authentication through `kubelogin` directly because local AKS
accounts are disabled. Install the Helm unit before planning the seed unit.

See [Argo CD bootstrap](../../../../../../../../../docs/terragrunt.md#aks-agic-argo-cd-bootstrap)
for checkout variables, credentials, input paths, apply stages, and existing state
ownership.
