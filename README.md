# Azure Application Platform

A small Azure application platform I am building with Terraform.

The main goal of this project is to practice Azure infrastructure, networking, managed identity, RBAC and Key Vault instead of just deploying a basic VM.

## Architecture

The current setup has:

- Resource Group
- VNet `10.0.0.0/16`
- Web subnet `10.0.1.0/24`
- App subnet `10.0.2.0/24`
- DB subnet `10.0.3.0/24`
- NSG on the Web subnet
- Linux VM in the Web subnet
- NIC and Public IP
- System-assigned managed identity
- Key Vault
- Test secret in Key Vault
- Intended RBAC assignment for the VM identity

```text
                    Internet
                       |
             +---------+---------+
             |                   |
          TCP 443             TCP 22
             |              My public IP
             |                   |
             +---------+---------+
                       |
                   Web Subnet
                  10.0.1.0/24
                       |
                      NIC
                       |
                      VM1
                       |
             System Assigned Identity
                       |
                    Entra ID
                       |
             Key Vault Secrets User
                       |
                   Key Vault
                       |
                   app-secret
```

The App and DB subnets are currently created but are not being used yet.

## Network

The VNet uses `10.0.0.0/16`.

The subnets are:

```text
Web  -> 10.0.1.0/24
App  -> 10.0.2.0/24
DB   -> 10.0.3.0/24
```

The Web subnet has an NSG.

The current rules are:

- TCP 443 allowed from anywhere
- TCP 22 allowed only from my public IP using `/32`

I decided not to use Azure Bastion for this lab because I wanted to keep the environment smaller. SSH access is restricted to my current public IP instead.

## Terraform

The network is separated into a Terraform module.

```text
terraform/
|
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
|
└── modules/
    └── network/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

The network module contains the VNet, subnets, NSG, NSG rules and subnet/NSG association.

The root module handles the VM, NIC, Public IP and Key Vault related resources.

The module outputs the VNet ID and subnet IDs so the root module can use them.

## Managed Identity

The VM uses a system-assigned managed identity.

```hcl
identity {
  type = "SystemAssigned"
}
```

I chose system-assigned because the identity belongs to this VM and there is currently no requirement to reuse it between different VMs.

The main idea is that the VM can authenticate to Azure services without having credentials stored on the VM.

## Key Vault and RBAC

The Key Vault uses Azure RBAC.

The intended role assignment is:

```text
Principal:
    VM system-assigned managed identity

Role:
    Key Vault Secrets User

Scope:
    Specific Key Vault
```

I chose `Key Vault Secrets User` because the VM only needs to read the secret. It does not need to manage the Key Vault or create/delete secrets.

I also scoped the role to the Key Vault instead of the whole Resource Group because giving the VM access to other resources in the Resource Group would be more than it needs.

## Testing the managed identity

I tested the managed identity directly from the VM.

The VM was able to contact the Azure Instance Metadata Service and obtain a token for Key Vault.

This confirmed that the managed identity was working.

I then used the token to request the test secret from Key Vault.

The request returned:

```text
HTTP/1.1 403 Forbidden
```

The response included:

```text
Action: 'Microsoft.KeyVault/vaults/secrets/getSecret/action'
Assignment: (not found)
innererror:
    ForbiddenByRbac
```

So the VM was able to authenticate, but it was not authorized to read the secret.

This helped me understand the difference between authentication and authorization:

```text
Authentication
VM -> Managed Identity -> Entra ID
                     |
                     +-- works

Authorization
VM Identity -> Key Vault
                     |
                     +-- denied
```

## KodeKloud limitation

The KodeKloud Azure environment has a limitation with the deployment account.

Terraform was able to create the VM, Key Vault and Key Vault secret, but it could not create the Azure RBAC role assignment.

The error was:

```text
Microsoft.Authorization/roleAssignments/write
```

not authorized for the KodeKloud user.

I also tested the same operation directly with Azure CLI and got the same result.

Because of this I did not give the VM a broader role such as Contributor or Owner just to make the deployment work.

The intended architecture is still:

```text
Terraform deployment identity
          |
          | RBAC administration permission
          v
    Create role assignment
          |
          v
VM managed identity
          |
          | Key Vault Secrets User
          v
      Key Vault
```

In a normal environment the Terraform deployment identity would need the appropriate permission to create the role assignment.

For this lab I am treating the missing RBAC permission as a KodeKloud limitation rather than changing the security design.

## Why not Contributor

Giving the VM Contributor access to the Resource Group would solve the immediate access problem, but it would give the VM much more access than required.

The VM only needs to read a secret.

It does not need to:

- Create resources
- Delete resources
- Modify the network
- Modify the VM
- Manage the Key Vault
- Assign RBAC roles

So the intended permission stays:

```text
Key Vault Secrets User
        |
        +-- Specific Key Vault
```

## Current state

The main infrastructure is deployed and working.

The VM can be accessed over SSH using the restricted public IP rule.

The VM has a system-assigned managed identity.

The Key Vault and test secret can be created.

The missing part in the KodeKloud environment is the RBAC assignment between the VM identity and the Key Vault.

The project currently demonstrates:

- Terraform resource deployment
- Terraform modules
- VNet and subnet design
- NSG rules
- Restricted SSH access
- Linux VM deployment
- System-assigned managed identity
- Key Vault
- RBAC
- Authentication vs authorization troubleshooting
- Least privilege

## Things I learned

One of the main things I wanted to understand better was managed identity and RBAC.

The testing showed that having a managed identity does not automatically give a VM access to Azure resources.

The VM was able to authenticate and get a token, but Key Vault still rejected the request because the required RBAC assignment was missing.

I also ran into the difference between the permissions needed by the deployment identity and the permissions needed by the workload identity.

The Terraform identity needs permission to create RBAC assignments, while the VM only needs the minimum permission required by the application.

Another thing I learned was that Terraform state and the actual Azure resources are separate. Removing a resource from the Terraform configuration can cause Terraform to remove it from Azure as well.

## Next steps

The next stage would be to run the same configuration in an environment where the Terraform deployment identity is allowed to create RBAC role assignments.

After that I would test the complete flow:

```text
Application on VM
       |
       v
System Assigned Managed Identity
       |
       v
Entra ID
       |
       v
Key Vault
       |
       v
Read application secret
```
