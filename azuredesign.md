I need you to help me create an architectural overview of our current Azure tenant for a senior-management technical briefing.

The goal is to document:

* How the Azure tenant is organized
* The management-group hierarchy
* The subscriptions under each management group
* The major Azure systems and services currently deployed
* How those services are actually being used in our environment
* Which Azure services are currently approved for organizational use, including approved services that may not currently be deployed
* A small number of clear architecture diagrams and summary charts suitable for a PowerPoint briefing

This should be an architectural overview, not a detailed asset inventory.

General approach

Use the Azure CLI and Azure Resource Graph to inspect the currently authenticated Azure tenant.

Treat Azure as the source of truth for what is currently deployed.

Do not retrieve or display secrets, credentials, keys, tokens, certificates, connection strings, or Key Vault secret values.

Create a lightweight local report using Python.

I would prefer the output to be a self-contained HTML report, with diagrams and charts that can also be exported as PNG or SVG for use in PowerPoint.

Use Graphviz or Mermaid for architecture diagrams and Plotly for charts where appropriate.

What I want you to discover

1. Tenant structure

Discover and document:

* Azure tenant
* Tenant root management group
* Management-group hierarchy
* Subscriptions underneath each management group

Produce a clean architecture diagram showing:

Tenant → Management Groups → Subscriptions

Do not include individual Azure resources in this diagram.

This should be readable on a presentation slide.

Also produce a second, more detailed management-group/subscription hierarchy diagram if necessary.

2. Major Azure services currently in use

Use Azure Resource Graph to determine which Azure resource types and major Azure services are actually deployed.

Group individual resource types into understandable Azure service categories.

Examples may include:

* Azure Virtual Machines
* Azure Virtual Networks
* Azure Firewall
* Private Endpoints
* ExpressRoute
* VPN Gateway
* Azure Application Gateway
* Azure Load Balancer
* Azure DNS / Private DNS
* Azure Storage
* Azure Key Vault
* Azure SQL
* Azure Cosmos DB
* Azure App Service
* Azure Functions
* Azure Kubernetes Service
* Azure Container Registry
* Log Analytics
* Azure Monitor
* Application Insights
* Microsoft Sentinel
* Microsoft Defender for Cloud
* Azure Automation
* Recovery Services Vault
* API Management
* Service Bus
* Event Hubs

Only include services in the “currently deployed” section if they are actually present in the tenant.

Do not produce a giant list of every Azure resource type.

Group related resources into meaningful architectural services.

3. Ask me for the currently approved Azure services

After discovering the services that are currently deployed, stop and ask me to provide the authoritative list of Azure services that are currently approved for use in the organization.

Do not attempt to infer approval status from deployment.

A service being deployed does not necessarily mean it is generally approved, and an approved service may not currently be deployed.

Ask me to provide the approved-services list in whatever form is easiest, such as:

* Pasted text
* Markdown list
* CSV-style list
* Existing service catalog
* Copied table

If useful, first show me the Azure services you discovered so I can compare the deployed-service list against the approved-service list.

Treat my approved-services list as the authoritative source for approval status.

Create a comparison between:

1. Approved and currently deployed
2. Approved but not currently deployed
3. Currently deployed but not present on the approved-services list
4. Approval status unclear

Do not automatically characterize category 3 as noncompliant or unauthorized.

Instead, flag it as:

“Deployed service not found in provided approved-services list”

and allow me to clarify whether the approved-services list is incomplete, the service is grandfathered, specifically authorized, or otherwise permitted.

4. Interview me about how each major deployed service is being used

Do not try to infer the business or operational purpose of each service solely from Azure Resource Graph.

After discovering the major Azure services in use, ask me targeted questions about how those services are actually used in our environment.

Your questions should help capture the context needed to write accurate senior-management descriptions.

Ask questions in logical groups rather than one resource at a time.

For each major service or service category, determine things such as:

* What is this service used for in our environment?
* Is it a shared enterprise service, a platform service, or workload-specific?
* Which teams or workloads depend on it?
* Is it centrally managed or managed by individual application teams?
* Is it production, non-production, or both?
* Is it part of a broader architectural pattern such as centralized networking, shared security, centralized logging, or application hosting?
* Is it a strategic platform service or primarily supporting a specific legacy or niche workload?
* Are there important dependencies or integrations that senior management should understand?
* Is there anything noteworthy about why this service was selected or how it fits into the Azure architecture?

Do not ask questions for services where the answer is obvious and not important to the briefing.

Prioritize services that materially affect the architecture.

For example, if you discover:

* Azure Firewall
* ExpressRoute
* Private DNS
* Sentinel
* Log Analytics
* Key Vault
* App Service
* Azure SQL
* Virtual Machines

ask focused questions such as:

* Is Azure Firewall providing centralized ingress/egress inspection for the tenant or only for specific environments?
* Is ExpressRoute the primary connectivity path between Azure and on-premises infrastructure?
* Are Private DNS Zones centrally managed for private endpoint resolution?
* Is Sentinel the organization’s primary cloud SIEM, and which logs are being sent to it?
* Are Log Analytics workspaces centralized or distributed by workload?
* Are Key Vaults generally application-specific or centrally managed?
* What types of applications are hosted on App Service?
* Are Azure SQL resources supporting internal applications, commercial products, or shared services?
* Are Virtual Machines primarily infrastructure services, application servers, legacy workloads, or administrative systems?

Ask me these questions before generating the final service descriptions.

5. Use my answers as the authoritative source for service purpose

After I answer your questions, combine:

1. Azure-discovered technical facts
2. My explanation of how the service is used
3. My approved-services list

to generate the final descriptions.

Azure should be authoritative for what exists and where it is deployed.

My answers should be authoritative for why it exists, what it supports, how the organization uses it, and whether the service is approved.

Do not invent organizational intent or approval status.

If my answer conflicts with what Azure appears to show, flag the discrepancy and ask me to clarify before including it in the final report.

6. Generate management-facing service descriptions

For each major deployed service, create a concise description suitable for senior management.

Each description should generally cover:

* What the service is
* How we use it
* Where it fits in the architecture
* What it supports or enables
* Its approval status, where useful

Avoid generic Microsoft product descriptions unless necessary.

Prefer descriptions specific to our environment.

Keep most service descriptions to approximately 2–4 sentences.

The tone should be technical but understandable to senior management.

7. Determine architectural patterns

Look for recognizable patterns in the environment, such as:

* Hub-and-spoke networking
* Centralized connectivity subscription
* Shared-services subscription
* Centralized logging
* Centralized security monitoring
* Platform subscriptions
* Production vs non-production subscription separation
* Private endpoint usage
* Central DNS
* ExpressRoute connectivity
* Landing-zone style management-group organization

Use Azure data to identify possible patterns, then ask me to confirm the important ones before presenting them as fact.

8. Networking overview

Create a high-level networking summary showing major components such as:

* VNets
* VNet peerings
* Azure Firewall
* ExpressRoute
* VPN gateways
* Virtual WAN / Virtual Hubs
* Application Gateways
* Private Endpoints
* Private DNS Zones
* Public IPs

Where relationships can be reliably determined, create a simplified network architecture diagram.

Do not attempt to show every subnet or every individual endpoint.

The diagram should explain the architecture rather than serve as a complete network inventory.

Before finalizing the network narrative, ask me to confirm the major connectivity model and the purpose of the key networking services.

9. Security and governance overview

At a high level, identify major Azure governance and security capabilities currently in use, such as:

* Management Groups
* Azure Policy
* RBAC
* Microsoft Defender for Cloud
* Microsoft Sentinel
* Key Vault
* Managed Identities
* Private Endpoints

Ask me targeted questions about how the major security and governance services are used before writing their final descriptions.

Do not produce detailed user-level RBAC listings.

10. Summary statistics

Include a concise set of useful metrics, such as:

* Number of management groups
* Number of subscriptions
* Number of resource groups
* Approximate total resource count
* Number of Azure regions in use
* Number of VNets
* Number of Private Endpoints
* Number of Azure Firewalls
* Number of ExpressRoute circuits
* Number of Log Analytics workspaces
* Number of Sentinel workspaces
* Number of Key Vaults
* Number of VMs
* Number of major PaaS services
* Number of approved Azure services
* Number of approved services currently deployed
* Number of approved services not currently deployed

Use Plotly charts for useful visualizations such as:

* Resources by subscription
* Resources by major Azure service
* Resources by Azure region
* Subscriptions by management group

Do not overload the report with charts.

11. Final HTML report

Produce a clean self-contained HTML report with approximately these sections:

Azure Architecture Overview

Executive Summary

A short narrative explaining the overall architecture of the Azure tenant.

Tenant and Subscription Organization

Management-group/subscription architecture diagram and explanation.

Azure Services Currently in Use

For each major deployed service, include:

* Service name
* Deployment footprint
* Where it is deployed
* How we use it
* What it supports
* Its architectural role
* Approval status where relevant

Base the usage descriptions primarily on my answers to your interview questions.

Approved Azure Services

Create a clear list or table of all Azure services I identify as currently approved for organizational use.

Include columns such as:

* Azure service
* Approved
* Currently deployed
* Deployment footprint, if deployed
* Notes, if I provide them

Clearly distinguish:

* Approved and deployed
* Approved but not currently deployed

If deployed services are not found in the approved-services list, put them in a separate review section rather than labeling them unauthorized.

Network Architecture

Simplified network architecture diagram and brief explanation.

Security and Governance

High-level overview of governance and security controls visible in Azure, supplemented by my explanation of how they are used operationally.

Azure Estate at a Glance

A few useful charts and statistics.

Architectural Observations

List significant architectural patterns or observations derived from both the Azure data and my answers.

Do not present recommendations unless I specifically ask for them.

This report should primarily describe what exists today, how it is organized, how we use it, and which Azure services are currently approved for use.

Presentation assets

Also export the main diagrams as SVG or high-resolution PNG files so I can place them directly into PowerPoint.

At minimum generate:

* tenant-management-group-subscription.svg
* azure-network-overview.svg
* azure-services-overview.svg

Keep the diagrams visually simple enough for senior-management presentations.

Implementation

Use:

* Azure CLI
* Azure Resource Graph
* Python
* Graphviz or Mermaid
* Plotly

Keep the implementation lightweight.

I do not need a full enterprise CMDB or extensive data warehouse.

The goal is to automatically inspect the tenant, obtain organizational context from me where Azure cannot provide it, and generate a current architectural briefing.

Required workflow

Follow this sequence:

1. Inspect the Azure tenant structure.
2. Query the major Azure resource types currently deployed.
3. Group them into meaningful Azure services.
4. Identify likely architectural patterns.
5. Present me with a concise discovery summary.
6. Ask me to provide the authoritative list of currently approved Azure services.
7. Compare the approved-services list with the services discovered in Azure.
8. Ask me targeted questions about how the major deployed services and architectural components are actually used.
9. Incorporate my answers.
10. Ask follow-up questions only where necessary to resolve important ambiguity.
11. Generate the HTML report and architecture diagrams.
12. Export PowerPoint-ready visuals.

Do not generate the final management-facing report until I have provided the approved-services list and answered the relevant service-usage questions.