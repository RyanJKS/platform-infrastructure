# Intro

- AKS cluster uses web_app_routing add-on to install nginx-ingress-controller and configure external dns control by
  applying "DNS Zone Contributor" on web_app_routing uami on DNS zone scope.
- aks*cluster_extension can only be used \_IF* identity is system assigned. Extension installs argocd which removes the
  bootstrap installation to be done on a cluster by using a ci-cd pipeline...
- aks_manifest - adds the root argocd/ folder project inside argocd once the extension above has been installed since
  it also installs the CRDS
