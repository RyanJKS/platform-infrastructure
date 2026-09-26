locals {
  # Keys match subscription, region, and spoke directory names under live/.
  address_spaces = {
    DEV-JKS = {
      dev = {
        eus2 = {
          spoke-atlas = ["10.0.0.0/16"]
        }
      }
    }
  }
}
