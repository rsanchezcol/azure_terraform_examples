# Azure Terraform Examples

Welcome to the **azure_terraform_examples** repository. 

This repository contains practical, production-ready Infrastructure as Code (IaC) templates and examples using **Terraform** to provision and manage cloud infrastructure on **Microsoft Azure**.

---

## 📂 Current Modules & Examples

### 1. [`terraform_azure_servicebus`](./terraform_azure_servicebus)
An event-driven architecture that automatically captures blob storage uploads via **Azure Event Grid** and routes event notifications directly to an **Azure Service Bus Queue** for asynchronous processing.

* **Key Components:** Azure Resource Group, Storage Account & Blob Container, Service Bus Namespace & Queue, Event Grid Event Subscription.

---

### 2. [`terraform_azure_app_infrastructure`](./terraform_azure_app_infrastructure)
A secure, multi-tier IaaS architecture designed for hosting web applications and databases with private network isolation and zero direct public VM exposure.

* **Key Components:** Virtual Network & Subnets, Azure Bastion (secure administrative access), Ubuntu Linux Virtual Machines, Azure Standard Load Balancer with HTTP/HTTPS rules, Network Interfaces, and Backend Pools.

---

## 🚀 Future Updates
This repository is continuously updated. More real-world Azure infrastructure patterns, automation blueprints, and security-focused configurations will be added over time (e.g., AKS clusters, Azure AI Foundry setups, APIM, and monitoring architectures).

---

## 🛠️ Prerequisites & Usage

To run any of the examples in this repository:

1. **Terraform**: Ensure you have Terraform CLI installed (`v1.0+`).
2. **Azure CLI**: Authenticate with your Azure account:
   ```bash
   az login```
3. Run Terraform:
Navigate to the desired folder and run standard Terraform commands:
```bash
cd <module_folder>
terraform init
terraform plan
terraform apply```

## 👤 Author
Maintained by Ramón Sánchez Villanueva
Lead DevOps, SRE & Cloud Engineer
