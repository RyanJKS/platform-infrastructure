# Hub setup TODO

TODO: Implement the shared hub infrastructure and its connections to spokes.
These folders reserve possible units; they contain documentation only.

## Ownership

This hub belongs to the dedicated `DEV-HUB` subscription under `dev/eus2/`.
It is intended to serve `dev` spokes across workload subscriptions such as
`DEV-JKS`. Development and production use separate hub subscriptions.
The subscription ID is unset in `DEV-HUB/subscription.hcl`; set the real ID
before implementation. These folders do not configure authentication or peering.

## Proposed units

```text
hub/
  README.md
  platform/
    vnet/README.md
    firewall/README.md
    private-dns/README.md
    monitoring/README.md
```

- [vnet](platform/vnet/README.md): shared hub virtual network and subnets.
- [firewall](platform/firewall/README.md): central traffic inspection and routing.
- [private-dns](platform/private-dns/README.md): shared private DNS zones, resolution, and spoke links.
- [monitoring](platform/monitoring/README.md): shared hub monitoring and diagnostics.

## Before implementation

- Confirm the real `DEV-HUB` subscription ID and the East US 2 regional scope.
- Select modules and define routing, DNS, firewall, and spoke connection ownership.
- Align the Azure `env.hcl` settings with root inheritance before implementation.
- Extend root settings inheritance for hubs: current roots require `spoke.hcl`.
  Do not scaffold hub units with the current spoke configuration unchanged.
- Configure authentication, providers, and isolated remote state for each unit.

No hub HCL, resource dependencies, or deployment configuration exists yet.
