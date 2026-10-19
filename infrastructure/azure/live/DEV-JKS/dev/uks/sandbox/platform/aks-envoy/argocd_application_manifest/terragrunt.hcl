# Terraform-owned root entry point. Runtime resources are reconciled by Argo CD.
terraform {
  before_hook "argocd_crd_ready" {
    commands = ["plan", "apply"]
    execute = [
      "sh", "-c",
      <<-EOF
        kubectl --kubeconfig=argocd-kubeconfig.yaml wait --for=condition=Established --timeout=120s crd/applications.argoproj.io || {
          echo 'Argo CD Application CRD is unavailable. Run ARGOCD_BOOTSTRAP=true terragrunt run -- apply in argocd_helm_manifest, then retry. Check AKS access if Argo CD is already installed.' >&2
          exit 1
        }
      EOF
    ]
  }

  source = "${include.repo_urls.locals.platform_blueprints_github_url}//terraform/shared/kubernetes_manifest?ref=${urlencode(include.envcommon.locals.kubernetes_manifest)}"
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
  cluster_path = "clusters/azure/${include.root.locals.subscription_name}/${include.root.locals.environment}/${include.root.locals.region_short}/${include.root.locals.domain_name}/aks-agic"
}

dependencies {
  paths = ["../argocd_helm_manifest"]
}

dependency "aks" {
  config_path                             = "../cluster"
  mock_outputs                            = include.root.locals.mocks.aks_cluster
  mock_outputs_allowed_terraform_commands = include.root.locals.mocks.allowed_commands
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# Use the same AKS endpoint and authentication as the Terraform provider.
generate "argocd_kubeconfig" {
  path      = "argocd-kubeconfig.yaml"
  if_exists = "overwrite_terragrunt"
  contents = yamlencode({
    apiVersion = "v1"
    kind       = "Config"
    clusters = [{
      name = "aks"
      cluster = {
        server                     = dependency.aks.outputs.host
        certificate-authority-data = dependency.aks.outputs.cluster_ca_certificate
      }
    }]
    users = [{
      name = "azurecli"
      user = {
        exec = {
          apiVersion      = "client.authentication.k8s.io/v1beta1"
          command         = "kubelogin"
          args            = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
          interactiveMode = "Never"
        }
      }
    }]
    contexts = [{
      name = "aks"
      context = {
        cluster = "aks"
        user    = "azurecli"
      }
    }]
    current-context = "aks"
  })
}

generate "kubernetes_provider" {
  path      = "provider-kubernetes.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
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

inputs = {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "all-apps"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/RyanJKS/platform-gitops.git"
        targetRevision = "dev/sandbox"
        path           = local.cluster_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = false
          selfHeal = true
        }
        syncOptions = ["ServerSideApply=true"]
      }
    }
  }
}
