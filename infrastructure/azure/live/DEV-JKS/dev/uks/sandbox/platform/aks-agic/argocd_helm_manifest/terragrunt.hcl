# Bootstrap only: Argo CD owns chart resources after the documented handoff.
terraform {
  before_hook "bootstrap_only" {
    commands = ["plan", "apply", "destroy", "import", "refresh"]
    execute = [
      "sh", "-c",
      "if [ \"$1\" != true ]; then echo 'Argo CD Helm bootstrap is disabled. Use ARGOCD_BOOTSTRAP=true only for initial installation or reviewed recovery.' >&2; exit 1; fi",
      "argocd-bootstrap", get_env("ARGOCD_BOOTSTRAP", "false")
    ]
  }
  source = "${include.repo_urls.locals.platform_blueprints_github_url}//terraform/shared/helm_release?ref=${urlencode(include.envcommon.locals.helm_release)}"
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

locals {
  bootstrap_enabled = get_env("ARGOCD_BOOTSTRAP", "false") == "true"
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

# Routine run --all operations exclude this bootstrap unit.
exclude {
  if      = !local.bootstrap_enabled
  actions = ["all"]
}

# Minimal installation only. Runtime configuration belongs to the GitOps child.
inputs = {
  release = {
    name             = "argocd"
    namespace        = "argocd"
    repository       = "https://argoproj.github.io/argo-helm"
    chart            = "argo-cd"
    version          = "10.9.0"
    create_namespace = true
    wait             = true
    timeout          = 600
  }
}
