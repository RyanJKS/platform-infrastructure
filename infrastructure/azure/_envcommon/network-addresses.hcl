locals {
  # Keys match subscription_name, environment, region_short, and domain_name.
  address_spaces = {
    DEV-JKS = {
      dev = {
        eus2 = {
          atlas = ["10.0.0.0/16"]
        }
      }
    }
  }
}
