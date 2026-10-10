# The shared directory lets this generated wrapper call the single-manifest
# module once per seed item, without changing the shared module's interface.
terraform {
  source = "${include.root.locals.repo_urls.platform_blueprints_github_url}//terraform/shared?ref=${urlencode(include.envcommon.locals.kubernetes_manifest)}"
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
  seed         = yamldecode(file("${local.gitops_dir}/${local.cluster_path}/root_projects.yaml"))
  root         = one([for item in local.seed.items : item if item.kind == "Application" && item.metadata.name == "all-apps"])

  # Keep the configurable repository URL aligned with root project permissions.
  projects = {
    for item in local.seed.items : "${item.kind}/${item.metadata.namespace}/${item.metadata.name}" => merge(item, {
      spec = merge(item.spec, {
        sourceRepos = [for repo in item.spec.sourceRepos : repo == local.root.spec.source.repoURL ? include.root.locals.repo_urls.platform_gitops_github_url : repo]
      })
    }) if item.kind == "AppProject"
  }
  applications = {
    for item in local.seed.items : "${item.kind}/${item.metadata.namespace}/${item.metadata.name}" => merge(item, {
      spec = merge(item.spec, {
        source = merge(item.spec.source, { repoURL = include.root.locals.repo_urls.platform_gitops_github_url })
      })
    }) if item.kind == "Application"
  }
  manifests = merge(local.projects, local.applications)
}

# Apply the Helm unit first. CRDs must also exist before planning this unit.
dependencies {
  paths = ["../argocd_helm_manifest"]
}

dependency "aks" {
  config_path = "../cluster"

  mock_outputs = include.root.locals.mocks.aks_cluster

  mock_outputs_allowed_terraform_commands = include.root.locals.mocks.allowed_commands
  mock_outputs_merge_strategy_with_state  = "shallow"
}

generate "kubernetes_provider" {
  path      = "provider-kubernetes.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_providers {
        kubernetes = {
          source  = "hashicorp/kubernetes"
          version = ">= 2.30.0, < 3.0.0"
        }
      }
    }

    provider "kubernetes" {
      host                   = ${jsonencode(dependency.aks.outputs.host)}
      cluster_ca_certificate = base64decode(${jsonencode(dependency.aks.outputs.cluster_ca_certificate)})
      exec {
        api_version = "client.authentication.k8s.io/v1beta1"
        command     = "kubelogin"
        args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
      }
    }
  EOF
}

generate "seed_manifests" {
  path      = "seed-manifests.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    variable "manifests" {
      type = any
    }

    module "projects" {
      source     = "./kubernetes_manifest"
      for_each   = { for key, item in var.manifests : key => item if item.kind == "AppProject" }
      manifest   = each.value
      wait_fields = {}
    }

    module "applications" {
      source     = "./kubernetes_manifest"
      for_each   = { for key, item in var.manifests : key => item if item.kind == "Application" }
      manifest   = each.value
      wait_fields = {}
      depends_on = [module.projects]
    }

    # Preserve the address of an existing root managed by the previous wrapper.
    moved {
      from = kubernetes_manifest.this
      to   = module.applications["Application/argocd/all-apps"].kubernetes_manifest.this
    }
  EOF
}

inputs = {
  manifests = local.manifests
}
