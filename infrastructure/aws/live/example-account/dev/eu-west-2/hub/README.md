# Hub setup TODO

TODO: Implement the shared hub infrastructure and its connections to spokes.
These folders reserve possible units; they contain documentation only.

## Proposed units

```text
hub/
  README.md
  platform/
    vpc/README.md
    transit-gateway/README.md
    firewall/README.md
    dns/README.md
    monitoring/README.md
```

- [vpc](platform/vpc/README.md): shared hub VPC and subnets.
- [transit-gateway](platform/transit-gateway/README.md): spoke attachments and transit routing.
- [firewall](platform/firewall/README.md): central traffic inspection and routing.
- [dns](platform/dns/README.md): shared DNS resolution and spoke associations.
- [monitoring](platform/monitoring/README.md): shared hub monitoring and diagnostics.

## Before implementation

- Confirm the owning account or subscription and regional scope.
- Select modules and define routing, DNS, firewall, and spoke connection ownership.
- Extend root settings inheritance for hubs: current roots require `spoke.hcl`.
  Do not scaffold hub units with the current spoke configuration unchanged.
- Configure authentication, providers, and isolated remote state for each unit.

No hub HCL, resource dependencies, or deployment configuration exists yet.
