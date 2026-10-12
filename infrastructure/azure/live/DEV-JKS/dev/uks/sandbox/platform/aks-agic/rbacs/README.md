# Issues

## Ingress AGIC

failed to reconcile kubenet CNI: Unable to associate Application Gateway subnet '/subscriptions/91c6f5e9-f6ab-400c-b5e7-265fd48053d3/resourceGroups/SANDBOX-SHARED-UKS-DEV-RG/providers/Microsoft.Network/virtualNetworks/sandboxuksdevvnet/subnets/agwsnet-001' with route table '/subscriptions/91c6f5e9-f6ab-400c-b5e7-265fd48053d3/resourceGroups/MC_SANDBOX-SHARED-UKS-DEV-RG_agicuksdevaks_uksouth/providers/Microsoft.Network/routeTables/aks-agentpool-15831455-routetable' due to error (this is relevant for AKS clusters using 'Kubenet' network plugin): network.RouteTablesClient#Get: Failure responding to request: StatusCode=403 -- Original Error: autorest/azure: Service returned an error. Status=403 Code="AuthorizationFailed" Message="The client '8f74341f-8989-43f8-8f70-fbe04704f5f4' with object id '0000b215-732b-49c0-836a-e55a39b54764' does not have authorization to perform action 'Microsoft.Network/routeTables/read' over scope '/subscriptions/91c6f5e9-f6ab-400c-b5e7-265fd48053d3/resourceGroups/MC_SANDBOX-SHARED-UKS-DEV-RG_agicuksdevaks_uksouth/providers/Microsoft.Network/routeTables/aks-agentpool-15831455-routetable' or the scope is invalid. If access was recently granted, please refresh your credentials.

agic uami requires "read" permissions over the managed resource group from aks cluster since it wants to read the "route table"
