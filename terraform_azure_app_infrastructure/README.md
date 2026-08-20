# Secure Multi-Tier IaaS Application Infrastructure with Azure Bastion and Load Balancer

## Overview
This Terraform module provisions a multi-tier, enterprise-ready infrastructure on Microsoft Azure using provider `v4.78.0`. It sets up an isolated virtual network hosting an application tier, database tier, Azure Bastion administrative access, and an external Standard Load Balancer distributing HTTP/HTTPS traffic.

---

## Architectural Layout
```
+----------------------------------------------------------------------------------------------------+
| Azure Resource Group: appinfra (uksouth)                                                           |
|                                                                                                    |
|  Virtual Network: vnet (10.0.0.0/16)                                                               |
|                                                                                                    |
|  +-------------------------------------+      +-------------------------------------------------+  |
|  | Subnet: AzureBastionSubnet          |      | Subnet: app_subnet (10.0.1.0/24)                |  |
|  | (10.0.0.0/24)                       |      |                                                 |  |
|  |                                     |      |  +-------------------------------------------+  |  |
|  |  +-------------------------------+  |      |  | Network Interface: app_vm_interface       |  |  |
|  |  | Azure Bastion Host: bastion   |  |      |  | (Dynamic Allocation)                      |  |  |
|  |  | Public IP: public_ip_bastion  |  |      |  +---------------------+---------------------+  |  |
|  |  +-------------------------------+  |      |                        |                        |  |
|  +-------------------------------------+      |  +---------------------v---------------------+  |  |
|                                               |  | Linux VM: app-vm (Ubuntu 20.04 LTS)       |  |  |
|  +-------------------------------------+      |  +-------------------------------------------+  |  |
|  | Subnet: db_subnet (10.0.2.0/24)     |      +------------------------^------------------------+  |
|  |                                     |                               |                           |
|  |  +-------------------------------+  |                               | Backend Pool              |
|  |  | Network Interface:            |  |                               | Association               |
|  |  | db_vm_interface (Dynamic)     |  |                               |                           |
|  |  +---------------+---------------+  |      +------------------------+------------------------+  |
|  |                  |                  |      | Azure Standard Load Balancer: app_lb            |  |
|  |  +---------------v---------------+  |      | Public IP: public_ip_lb                         |  |
|  |  | Linux VM: db-vm               |  |      | Rules: TCP 80 (HTTP), TCP 443 (HTTPS)           |  |
|  |  | (Ubuntu 20.04 LTS)            |  |      | Backend Pool: app_lb_backend_pool               |  |
|  |  +-------------------------------+  |      +-------------------------------------------------+  |
|  +-------------------------------------+                                                           |
+----------------------------------------------------------------------------------------------------+
```

---

## Provisioned Infrastructure Components

1. **Networking Foundation**:
   * **Virtual Network (`azurerm_virtual_network`)**: `vnet` (`10.0.0.0/16`).
   * **Subnets (`azurerm_subnet`)**:
     * `AzureBastionSubnet` (`10.0.0.0/24`) — Adheres strictly to Azure naming conventions for Bastion.
     * `app_subnet` (`10.0.1.0/24`) — Dedicated tier for application compute.
     * `db_subnet` (`10.0.2.0/24`) — Dedicated tier for database compute.
2. **Compute & Network Interfaces**:
   * **Network Interfaces (`azurerm_network_interface`)**: `app_vm_interface` and `db_vm_interface` configured with dynamic private IP allocations in their respective subnets.
   * **Virtual Machines (`azurerm_linux_virtual_machine`)**: `app-vm` and `db-vm` deployed with Ubuntu Server 20.04 LTS (`sku = "20_04-lts"`), standard `Standard_B1s` compute, password authentication, and read/write OS disk caching.
3. **Management & Ingress Connectivity**:
   * **Public IPs (`azurerm_public_ip`)**: `public_ip_bastion` and `public_ip_lb` provisioned with `Static` allocation and `Standard` SKU.
   * **Bastion Host (`azurerm_bastion_host`)**: `bastion` with IP configuration `bastion_config` providing secure, browser-based RDP/SSH access without public IP exposure on VMs.
   * **Load Balancer (`azurerm_lb`)**: `app_lb` on `Standard` SKU with frontend configuration `app_lb_config`.
   * **Backend Pool & Association**: `app_lb_backend_pool` linked to `app_vm_interface` via `azurerm_network_interface_backend_address_pool_association`.
   * **Load Balancing Rules (`azurerm_lb_rule`)**: 
     * `app_tcp_80`: Routes frontend TCP port 80 to backend port 80.
     * `app_tcp_443`: Routes frontend TCP port 443 to backend port 443.

---

## How the Solution Was Built

* **Naming Conventions**: Resource names within Terraform blocks strictly mirror Azure resource names (e.g., using `app-vm` and `db-vm` with hyphens for VM resources and `AzureBastionSubnet` for subnet requirements).
* **Zero Direct Public VM Exposure**: VMs carry only private IP addresses inside distinct subnets. External inbound traffic enters through the Load Balancer, while administrative access is channeled via Azure Bastion.
* **Provider Compatibility**: Fully compatible with `azurerm` provider `v4.78.0`, leveraging `backend_address_pool_ids` list syntax on load balancer rules and decoupled subnet declarations outside the virtual network block.

---

## Deployment Instructions

### Prerequisites
* Terraform CLI `v1.15.6+`
* Azure CLI configured with an active subscription (`az login`)
* Azure RM Provider `v4.78.0`

### Execution

```bash
# Initialize Terraform provider plugins
terraform init

# Check configuration syntax and validity
terraform validate

# Generate execution plan
terraform plan

# Deploy infrastructure to Azure
terraform apply -auto-approve
```
