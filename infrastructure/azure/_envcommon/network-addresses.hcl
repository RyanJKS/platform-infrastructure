locals {
  # Maintain explicit allocations in numeric CIDR order.
  allocations = [
    {
      cidr         = "10.0.0.0/16"
      subscription = "DEV-JKS"
      environment  = "dev"
      region       = "eus2"
      domain       = "atlas"
    },
    {
      cidr         = "10.1.0.0/16"
      subscription = "DEV-JKS"
      environment  = "dev"
      region       = "uks"
      domain       = "atlas"
    },
  ]

  by_subscription = {
    for allocation in local.allocations :
    allocation.subscription => allocation...
  }

  # Derived keys match subscription_name, environment, region_short, and domain_name.
  address_spaces = {
    for subscription, allocations in local.by_subscription :
    subscription => {
      for environment, environment_allocations in {
        for allocation in allocations :
        allocation.environment => allocation...
      } :
      environment => {
        for region, region_allocations in {
          for allocation in environment_allocations :
          allocation.region => allocation...
        } :
        region => {
          for allocation in region_allocations :
          allocation.domain => allocation.cidr...
        }
      }
    }
  }
}
