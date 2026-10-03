# Bootstrap Azure Terraform state storage

`scripts/azure-tfstate-bootstrap/` is a standalone Terraform setup for the
development hub subscription, `DEV-HUB`. Run it locally once before configuring
remote state for the remaining infrastructure or pipelines. It creates exactly
three resources: a resource group, a Standard LRS StorageV2 account with
hierarchical namespace (HNS) enabled for ADLS Gen2, and a private `tfstate` container.

This setup uses Terraform directly, without Terragrunt or inherited settings.
`main.tf` holds editable values in `locals`, `provider.tf` configures AzureRM,
and `backend.tf` keeps the bootstrap's own state locally. The storage must exist
before it can serve as a remote backend.

## Configure and run locally

Install Terraform 1.3 or later, below 2.0, and Azure CLI. The Azure identity needs
permission to create resource groups, storage accounts, and containers in
`DEV-HUB`. If your subscription restricts resource provider registration, have
its administrator register `Microsoft.Storage` first.

1. Edit `scripts/azure-tfstate-bootstrap/main.tf`. Replace the all-zero
   `subscription_id` with the real `DEV-HUB` subscription GUID. Review `location`,
   resource names, and tags. The default location is `eastus2`, matching the
   development hub layout. Choose a globally unique storage account name using
   3–24 lowercase letters and digits; the default name is not reserved.
2. Authenticate and select the same subscription in Azure CLI:

   ```sh
   az login
   az account set --subscription 'YOUR_DEV_HUB_SUBSCRIPTION_ID'
   az account show --query '{name:name, id:id}'
   ```

3. From the repository root, initialize and create a plan:

   ```sh
   cd scripts/azure-tfstate-bootstrap
   terraform init
   terraform fmt -check
   terraform validate
   terraform plan -out=bootstrap.tfplan
   ```

4. Review the subscription, resource names, location, HNS setting, and three
   resource creations in the plan. Apply the reviewed plan:

   ```sh
   terraform apply bootstrap.tfplan
   ```

Keep a secure backup of `terraform.tfstate`; it can contain storage access keys.
State and plan files are ignored by Git. Re-running Terraform with the same
configuration and state manages the existing resources. If state is lost, import
the existing resources before planning rather than attempting to recreate them.
Do not destroy this storage while other deployments use it for state.

## Use the storage for subsequent deployments

Configure the Azure cloud root or selected units to use the created storage.
For example, a unit's generated Terraform backend can contain:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-devhub-tfstate-eus2"
    storage_account_name = "stdevhubtfstateeus2"
    container_name       = "tfstate"
    subscription_id      = "YOUR_DEV_HUB_SUBSCRIPTION_ID"
    key                  = "live/DEV-JKS/dev/uks/atlas/platform/vnet/terraform.tfstate"
    use_azuread_auth     = true
  }
}
```

Use your actual names and subscription ID. Keep one state key per complete unit
path, as described in the [deployment guide](terragrunt.md#authentication-and-remote-state-prerequisites).
Grant local users and pipeline identities the required data access separately,
such as **Storage Blob Data Contributor** on the state storage account or
container. The bootstrap does not create role assignments, pipeline credentials,
or workload backend configuration.

Leave the bootstrap's own backend local unless you deliberately plan a separate
state migration. The [Azure pipeline guide](azure-pipelines.md) describes OIDC and
the remote backend checks required for subsequent unit deployments.
