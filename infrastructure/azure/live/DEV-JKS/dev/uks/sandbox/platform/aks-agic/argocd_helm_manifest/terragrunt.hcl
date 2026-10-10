# Terraform owns this Helm release; Argo CD does not sync its setup files.
terraform {
  source = "${include.root.locals.repo_urls.platform_blueprints_github_url}//terraform/shared/helm_release?ref=${urlencode(include.envcommon.locals.helm_release)}"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders("root.hcl"))}/_envcommon/module-versions.hcl"
  expose = true
}

locals {
  gitops_dir   = abspath(get_env("GITOPS_DIR", "${get_repo_root()}/../platform-gitops"))
  cluster_path = "clusters/azure/DEV-JKS/dev/uks/sandbox/aks-agic"
  release      = yamldecode(file("${local.gitops_dir}/${local.cluster_path}/platform/argocd/helm_release.yaml"))
  catalog      = yamldecode(file("${local.gitops_dir}/${local.release.catalog}"))
}

dependency "aks" {
  config_path = "../cluster"

  mock_outputs = include.root.locals.mocks.aks_cluster

  mock_outputs_allowed_terraform_commands = include.root.locals.mocks.allowed_commands
  mock_outputs_merge_strategy_with_state  = "shallow"
}

generate "helm_provider" {
  path      = "provider-helm.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "helm" {
      kubernetes = {
        host                   = ${jsonencode(dependency.aks.outputs.host)}
        cluster_ca_certificate = base64decode(${jsonencode(dependency.aks.outputs.cluster_ca_certificate)})
        exec                   = {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "kubelogin"
        args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
      }
      }
    }
  EOF
}

inputs = {
  release = merge(local.catalog.release, {
    create_namespace = true
    wait             = true
    timeout          = 600
  })
  values = concat(
    [yamlencode(local.catalog.values)],
    [for values_file in local.release.valueFiles : file("${local.gitops_dir}/${values_file}")],
    [yamlencode(local.release.values)]
  )
}
