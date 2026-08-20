# Event-Driven Storage Ingestion Architecture with Azure Service Bus and Event Grid

## Overview
This Terraform configuration deploys an automated, event-driven messaging architecture on Microsoft Azure. It provisions a storage layer that detects file uploads and dispatches event notifications via Azure Event Grid directly into an Azure Service Bus queue for decoupled, scalable asynchronous processing.

---

## Architectural Diagram & Data Flow
```
+-----------------------------------------------------------------------------------+
| Azure Resource Group: eventdriven (West Europe)                                      |
|                                                                                   |
|  +--------------------------+                                                     |
|  | Storage Account          |                                                     |
|  | (uploadstorageaccount)   |                                                     |
|  |  +--------------------+  |                                                     |
|  |  | Blob Container     |  |                                                     |
|  |  | (upload-container) |  |                                                     |
|  |  +---------+----------+  |                                                     |
|  +------------|-------------+                                                     |
|               |                                                                   |
|               | (Microsoft.Storage.BlobCreated Event)                             |
|               v                                                                   |
|  +-------------------------------------------------------+                        |
|  | Azure Event Grid Subscription                         |                        |
|  | (upload-event-subscription)                           |                        |
|  | Scope: upload-container.id                            |                        |
|  +----------------------------+--------------------------+                        |
|                               |                                                   |
|                               | (Direct Service Bus Forwarding)                   |
|                               v                                                   |
|  +-------------------------------------------------------+                        |
|  | Service Bus Namespace: upload-queue-ns (Standard SKU) |                        |
|  |  +-------------------------------------------------+  |                        |
|  |  | Service Bus Queue: upload-queue                 |  |                        |
|  |  | (Partitioning: Enabled)                         |  |                        |
|  |  +-------------------------------------------------+  |                        |
|  +-------------------------------------------------------+                        |
+-----------------------------------------------------------------------------------+
```

---

## Provisioned Infrastructure Components

1. **Resource Group (`azurerm_resource_group`)**:
   * Name: `eventdriven`
   * Location: `West Europe`
2. **Storage Layer**:
   * **Storage Account (`azurerm_storage_account`)**: `uploadstorageaccount` configured with `Standard` performance tier and `LRS` (Locally Redundant Storage).
   * **Blob Container (`azurerm_storage_container`)**: `upload-container` with `blob` container access.
3. **Enterprise Messaging Layer**:
   * **Service Bus Namespace (`azurerm_servicebus_namespace`)**: `upload-queue-ns` running on `Standard` SKU.
   * **Service Bus Queue (`azurerm_servicebus_queue`)**: `upload-queue` with partition support enabled (`enable_partitioning = true`) for horizontal throughput and reliability.
4. **Event Routing Layer**:
   * **Event Grid Event Subscription (`azurerm_eventgrid_event_subscription`)**: `upload-event-subscription`.
   * **Target Scope**: Scoped directly to the storage container (`azurerm_storage_container.upload_container.id`).
   * **Filtering**: Configured strictly to capture `Microsoft.Storage.BlobCreated` events.
   * **Endpoint**: Direct delivery to the Service Bus queue endpoint (`service_bus_queue_endpoint_id`).

---

## How the Solution Was Built

* **Explicit Dependency Graph**: Resources are linked dynamically via Terraform attribute interpolation (`.id` and `.name`), preventing race conditions during resource creation.
* **Granular Event Scoping**: Instead of binding Event Grid across the entire storage account, the event subscription targets `upload-container.id` directly to eliminate event noise from other unmonitored containers.
* **Native Integration**: Leverages native Azure Service Bus routing from Event Grid, removing the need for intermediary compute layers (such as Azure Functions) to ingest blob creation alerts.

---

## Deployment Instructions

### Prerequisites
* Terraform CLI `v1.0+`
* Azure CLI configured with an active subscription (`az login`)
* Azure RM Provider `v2.56.0`

### Execution

```bash
# Initialize Terraform and download required provider plugins
terraform init

# Validate configuration syntax
terraform validate

# Review execution plan
terraform plan

# Deploy infrastructure to Azure
terraform apply -auto-approve
```

---
