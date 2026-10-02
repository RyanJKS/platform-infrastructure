locals {
  allowed_commands  = ["validate", "plan"]
  zero_uuid         = "00000000-0000-0000-0000-000000000000"
  resource_group_id = "/subscriptions/${local.zero_uuid}/resourceGroups/mock-resource-group"

  resource_group = {
    id       = local.resource_group_id
    name     = "mock-resource-group"
    location = "uksouth"
  }

  solution_settings = {
    for domain in ["atlas", "intro"] : domain => {
      settings = {
        solution_name   = domain
        solution_slug   = domain
        name_prefix     = "${domain}uksdev"
        env             = "dev"
        region_short    = "uks"
        region_long     = "uksouth"
        subscription_id = local.zero_uuid
        tenant_id       = local.zero_uuid
        client_id       = local.zero_uuid
        object_id       = local.zero_uuid
      }
      tags = {
        Environement = "dev"
        Solution     = title(domain)
        Region       = "uksouth"
      }
    }
  }

  aks_cluster = {
    id                     = "${local.resource_group_id}/providers/Microsoft.ContainerService/managedClusters/mock-aks"
    host                   = "https://example.invalid"
    cluster_ca_certificate = ""
    client_certificate     = ""
    client_key             = ""
    web_app_routing_identity = [{
      object_id = local.zero_uuid
    }]
  }

  dns = {
    id = "${local.resource_group_id}/providers/Microsoft.Network/dnsZones/example.invalid"
  }

  vnet = {
    subnet_ids = {
      appsnet-001 = "${local.resource_group_id}/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/appsnet-001"
    }
  }

  base_aad_groups = {
    object_ids = {
      READER = "11111111-1111-1111-1111-111111111111"
      WRITER = "22222222-2222-2222-2222-222222222222"
      ADMIN  = "33333333-3333-3333-3333-333333333333"
    }
  }
}
