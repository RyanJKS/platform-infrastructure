# Catalog discovery and inherited inputs; deployment is deliberately unconfigured.
# Select a real module and configure cloud authentication and an existing remote
# backend before planning. See docs/terragrunt.md for the state isolation contract.
terragrunt_version_constraint = "= 1.1.5"

catalog {
  urls = [
    "github.com/RyanJKS/platform-blueprints//terraform/aws",
  ]
}

# Pin the catalog URL to a verified published commit once terraform/aws/ is published.
# Every unit directly includes this file; do not add intermediate root includes.
# Future backend key: "${path_relative_to_include("root")}/terraform.tfstate"
# This retains the account/environment/region/spoke/category/[solution]/unit boundary.
# No backend, credentials, providers, or deployable units are configured yet.

# Every unit includes this root directly. Settings files are data, not includes.
locals {
  account_config     = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  environment_config = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  region_config      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  spoke_config       = read_terragrunt_config(find_in_parent_folders("spoke.hcl"))
  category_config    = read_terragrunt_config(find_in_parent_folders("category.hcl"))
  # Platform units have no application solution level.
  solution_config = local.category_config.locals.inputs.category == "platform" ? null : read_terragrunt_config(find_in_parent_folders("solution.hcl"))
  unit_config     = read_terragrunt_config("${get_original_terragrunt_dir()}/unit.hcl")

  inherited_inputs = merge(
    local.account_config.locals.inputs,
    local.environment_config.locals.inputs,
    local.region_config.locals.inputs,
    local.spoke_config.locals.inputs,
    local.category_config.locals.inputs,
    try(local.solution_config.locals.inputs, {}),
    local.unit_config.locals.inputs,
  )

  inherited_tags = merge(
    try(local.account_config.locals.inputs.tags, {}),
    try(local.environment_config.locals.inputs.tags, {}),
    try(local.region_config.locals.inputs.tags, {}),
    try(local.spoke_config.locals.inputs.tags, {}),
    try(local.category_config.locals.inputs.tags, {}),
    try(local.solution_config.locals.inputs.tags, {}),
    try(local.unit_config.locals.inputs.tags, {}),
  )
}

inputs = merge(local.inherited_inputs, { tags = local.inherited_tags })
