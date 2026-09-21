terragrunt_version_constraint = "= 1.1.5"

locals {
  subscription_config = read_terragrunt_config(find_in_parent_folders("subscription.hcl"))
  environment_config  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_config       = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  spoke_config        = read_terragrunt_config(find_in_parent_folders("spoke.hcl"))
  category_config     = read_terragrunt_config(find_in_parent_folders("category.hcl"))
  # solution_config = read_terragrunt_config(find_in_parent_folders("solution.hcl"))

  # Re-usable
  subscription_id = local.subscription_config.locals.subscription_id
  environment = local.environment_config.locals.environment
  region_short = local.region_config.locals.region_short
  region_long = local.region_config.locals.region_long
  spoke_prefix = local.spoke_config.locals.spoke_prefix
  # solution_name = local.solution_config.locals.solution

  # Pre-provisioned

}

catalog {
  urls = [
    "github.com/RyanJKS/platform-blueprints//terraform/azure",
  ]
}

errors {
  retry "transient_errors" {
    retryable_errors = [
      "(?s).*REQUEST_LIMIT_EXCEEDED.*",
      "(?s).*Client.Timeout exceeded while awaiting headers.*",
    ]
    max_attempts       = 3
    sleep_interval_sec = 5
  }
}

generate "providers_definition" {
  path = "providers_definition.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF

  provider "azurerm" {
    features {
      key_vault {
        purge_soft_delete_on_destroy = false
        purge_soft_deleted_secrets_on_destroy = false
      }
    }
    subscription_id = "${local.subscription_id}"

    resource_provider_registrations = "none"
  }

  provider "azuread" {}
EOF
}


inputs = merge(
  local.subscription_config.locals,
  local.environment_config.locals,
  local.region_config.locals,
  local.spoke_config.locals
)
