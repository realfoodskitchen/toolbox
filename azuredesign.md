You are acting as a senior Azure cloud architect, Azure governance engineer, Python developer, PowerShell developer, and technical documentation specialist.

I need you to build a complete, maintainable Azure architecture inventory and reporting solution for an enterprise Azure tenant.

Objective

Create a local toolchain that inventories our Azure tenant and automatically produces technical architecture artifacts suitable for:

1. Senior-management technical briefings
2. Azure architecture documentation
3. Engineering reference material
4. Periodic regeneration as the Azure environment changes

The solution should treat Azure as the authoritative source of truth. Do not require me to manually maintain management-group, subscription, resource, networking, policy, or security diagrams.

The solution should collect Azure configuration and inventory data, normalize it locally, and generate:

* Executive Azure tenant architecture diagram
* Detailed management-group/subscription hierarchy diagram
* Azure estate dashboard
* Resource inventory charts
* Governance/security summary
* Networking summary
* Markdown technical report
* Self-contained HTML report
* SVG and PNG assets suitable for importing into PowerPoint

GitHub Copilot is approved for use with sensitive information in this environment, so do not unnecessarily anonymize Azure tenant names, subscription names, management groups, resource names, IDs, or other Azure configuration information.

However, do not output secrets, access tokens, certificates, passwords, connection strings, storage keys, client secrets, private keys, or Key Vault secret values.

⸻

Architecture

Build the project using:

* PowerShell for orchestration and Azure data collection
* Azure CLI where appropriate
* Azure Resource Graph for large-scale Azure resource queries
* Python for data normalization, analysis, visualization, and report generation
* Graphviz for hierarchical architecture diagrams
* Mermaid where useful for Markdown documentation
* Plotly for charts and interactive HTML visualization
* Jinja2 for HTML report templating if appropriate

Prefer standard, well-supported libraries.

The entire solution should run locally after authentication with Azure CLI.

Assume:

az login

has already been performed.

The implementation should use the currently authenticated Azure identity and only collect resources the identity is authorized to read.

Do not use interactive prompts during normal report generation.

⸻

Desired repository structure

Create a clean repository similar to:

azure-architecture-report/
│
├── README.md
├── requirements.txt
├── .gitignore
│
├── config/
│   └── report-config.json
│
├── scripts/
│   ├── Build-AzureBriefing.ps1
│   ├── Collect-AzureInventory.ps1
│   └── generate_report.py
│
├── queries/
│   ├── resources.kql
│   ├── resource-types.kql
│   ├── regions.kql
│   ├── networking.kql
│   ├── compute.kql
│   ├── storage.kql
│   ├── keyvaults.kql
│   └── policy-summary.kql
│
├── templates/
│   └── report.html.j2
│
├── data/
│   ├── raw/
│   └── normalized/
│
└── output/
    ├── diagrams/
    ├── charts/
    ├── reports/
    └── data/

Modify the structure if you have a technically superior design, but keep collection, normalization, presentation, configuration, and output clearly separated.

⸻

Primary orchestration command

I ultimately want to generate everything with one command:

.\scripts\Build-AzureBriefing.ps1

The script should:

1. Validate prerequisites.
2. Verify Azure CLI authentication.
3. Determine the Azure tenant.
4. Collect tenant and subscription inventory.
5. Collect management-group hierarchy.
6. Query Azure Resource Graph.
7. Collect policy/governance information where accessible.
8. Collect networking information.
9. Normalize collected data.
10. Generate architecture diagrams.
11. Generate charts.
12. Generate an interactive HTML report.
13. Generate a Markdown technical report.
14. Export PowerPoint-ready images.
15. Print a concise summary showing where the generated artifacts were written.

Use clear logging such as:

[1/10] Validating prerequisites
[2/10] Reading Azure tenant information
[3/10] Collecting management groups
[4/10] Collecting subscriptions
[5/10] Querying Azure Resource Graph
[6/10] Normalizing inventory
[7/10] Generating architecture diagrams
[8/10] Generating charts
[9/10] Building HTML report
[10/10] Complete

Return a nonzero exit code when a fatal error occurs.

Individual optional data sources should fail gracefully where possible.

For example, lack of permissions to inspect a particular governance dataset should not prevent the rest of the report from being generated.

⸻

Data collection requirements

1. Tenant

Collect basic Azure tenant information available from Azure CLI, including where possible:

* Tenant ID
* Tenant display information
* Current authenticated account
* Azure cloud/environment
* Number of visible subscriptions

Do not collect authentication tokens.

⸻

2. Management Groups

Automatically discover the complete management-group hierarchy visible to the authenticated user.

Capture at minimum:

managementGroupId
displayName
parentManagementGroupId
depth
children
subscriptions

Preserve the hierarchy.

Do not assume management groups have a fixed depth.

Support arbitrary nesting.

Identify the tenant root management group when accessible.

⸻

3. Subscriptions

Collect all accessible subscriptions.

Capture at minimum:

subscriptionId
subscriptionName
tenantId
state
managementGroupId
managementGroupName

If subscription tags or metadata can provide useful environment classification, capture them.

Attempt to classify subscriptions into categories such as:

Production
NonProduction
Development
Test
Sandbox
Platform
Connectivity
Identity
Management
Security
Shared Services
Unknown

Do not rely exclusively on names.

Use configurable matching rules in:

config/report-config.json

If classification is uncertain, use Unknown.

Never invent classifications.

⸻

4. Azure Resource Graph

Use Azure Resource Graph as the primary resource inventory mechanism.

Collect enough information to support analysis including:

id
name
type
location
resourceGroup
subscriptionId
kind
sku
tags

Do not attempt to retrieve secrets or resource contents.

Create useful Resource Graph queries that summarize:

* total resources
* resources per subscription
* resources per management group
* resources by type
* resources by region
* resource groups per subscription
* resources by environment classification

Also collect detailed data needed for additional reporting.

⸻

5. Networking

Inventory major Azure networking components.

At minimum detect:

* Virtual Networks
* Subnets
* VNet peerings
* Azure Firewall
* Firewall Policies
* Network Security Groups
* Route Tables
* Public IP Addresses
* Private Endpoints
* Private DNS Zones
* VPN Gateways
* ExpressRoute Gateways
* ExpressRoute Circuits
* Application Gateways
* Load Balancers
* NAT Gateways
* Bastion
* DNS Private Resolvers
* Virtual WAN
* Virtual Hubs

Collect relationships where they can be reliably inferred from Resource Graph or Azure APIs.

Do not create false topology relationships.

Where a connection cannot be conclusively determined, report the resources without inventing connectivity.

⸻

6. Compute and platform services

Inventory useful high-level counts for:

* Virtual Machines
* Virtual Machine Scale Sets
* App Services
* Function Apps
* AKS clusters
* Container Apps
* Container Registries
* SQL resources
* Cosmos DB
* Storage Accounts
* Key Vaults
* Log Analytics Workspaces
* Automation Accounts
* Recovery Services Vaults
* API Management
* Event Hubs
* Service Bus
* Application Insights

This is not intended to exhaustively document every configuration property.

Focus on information useful for understanding the estate.

⸻

7. Governance

Where authorized, collect information about:

* Azure Policy assignments
* Policy initiatives
* Policy exemptions
* Management-group policy scope
* Subscription policy scope

Generate useful summary statistics such as:

Number of policy assignments
Number assigned at management-group scope
Number assigned at subscription scope
Assignments by major management group

If policy compliance data is available without excessive runtime, include it.

Clearly distinguish:

Policy assignment inventory

from:

Policy compliance results

Do not claim an environment is compliant merely because policies are assigned.

⸻

8. RBAC

Where authorized, provide high-level RBAC information.

Do NOT generate a giant listing of every user permission in the primary report.

Instead provide useful architectural statistics such as:

* Role assignments by scope
* Role assignments at tenant/root management-group level if accessible
* Management-group assignments
* Subscription-level assignments
* Count of Owner assignments
* Count of User Access Administrator assignments
* Count of Contributor assignments
* Custom role count

Keep detailed RBAC export as an optional data file.

Do not expose unnecessary personal information in the executive report.

⸻

9. Security services

Detect major Azure security capabilities where possible, including:

* Microsoft Defender for Cloud
* Defender plans by subscription
* Microsoft Sentinel workspaces
* Key Vault usage
* Managed identities
* Private endpoints
* Public IP exposure

Do not make security judgments without sufficient evidence.

For example, do not label a subscription “secure” simply because Defender for Cloud is enabled.

Use factual descriptions.

⸻

Normalized data model

Create normalized JSON files under:

data/normalized/

Prefer a structure that includes files such as:

tenant.json
management_groups.json
subscriptions.json
resources.json
networking.json
governance.json
security.json
summary.json

Create a high-level summary.json containing report-ready metrics.

Example:

{
  "tenant": {
    "tenantId": "...",
    "displayName": "..."
  },
  "counts": {
    "managementGroups": 0,
    "subscriptions": 0,
    "resourceGroups": 0,
    "resources": 0,
    "regions": 0
  },
  "networking": {
    "vnets": 0,
    "subnets": 0,
    "peerings": 0,
    "privateEndpoints": 0,
    "publicIps": 0,
    "azureFirewalls": 0,
    "expressRouteCircuits": 0
  },
  "governance": {
    "policyAssignments": 0,
    "policyExemptions": 0
  },
  "security": {}
}

Use actual discovered values.

⸻

Architecture diagrams

Generate multiple diagrams rather than one enormous diagram.

Diagram 1 — Executive Azure governance architecture

Produce:

output/diagrams/azure-executive-architecture.svg
output/diagrams/azure-executive-architecture.png

This diagram should be optimized for PowerPoint and senior-management consumption.

It should show approximately:

Microsoft Entra / Azure Tenant
             |
     Tenant Root Group
             |
      Management Groups
             |
   Major environment groups
             |
   Subscription summaries

Do NOT display hundreds of subscription/resource nodes if that makes the diagram unreadable.

Where necessary, collapse subscriptions into counts.

Example:

Production
12 subscriptions
2,431 resources

Use visually differentiated node types for:

* Tenant
* Management group
* Subscription group/count

Keep the appearance professional and restrained.

Use Graphviz automatic layout.

Prefer SVG as the canonical artifact because it scales cleanly in PowerPoint.

⸻

Diagram 2 — Complete management-group hierarchy

Generate:

output/diagrams/management-group-hierarchy.svg
output/diagrams/management-group-hierarchy.png

Show every discovered management group and subscription.

Use:

* rectangles for management groups
* rounded rectangles for subscriptions
* clear directional hierarchy
* subscription name
* optionally abbreviated subscription ID

Allow the diagram to become large because this is an engineering/reference artifact.

Do not truncate the hierarchy.

⸻

Diagram 3 — Subscription/environment view

Create a diagram grouping subscriptions by:

Production
NonProduction
Development
Platform
Sandbox
Unknown

if enough reliable classification data exists.

This diagram should make it easy to understand how the estate is distributed.

⸻

Diagram 4 — High-level Azure network architecture

Generate a topology diagram only from relationships that can be reliably discovered.

Focus on major topology:

ExpressRoute / VPN
        |
Hub / Virtual WAN
        |
Firewall
        |
VNets / Spokes
        |
Private Endpoints / Workloads

The actual diagram must reflect discovered Azure resources.

Do NOT manufacture a hub-and-spoke topology merely because it is common.

Infer relationships using actual configuration such as:

* peerings
* gateways
* virtual hubs
* route relationships
* firewall placement
* subnet associations

If automatic topology discovery is incomplete, generate a conservative network inventory diagram instead and state the limitation.

⸻

Mermaid documentation

Also create:

output/reports/architecture.md

Include Mermaid diagrams where appropriate.

The Markdown document should render correctly in GitHub.

Do not make Mermaid the only graphical output because PowerPoint-ready SVG/PNG is required.

⸻

Plotly dashboard

Generate a professional self-contained HTML report:

output/reports/azure-estate-report.html

The report should work locally in a browser.

Prefer embedding Plotly JavaScript so the report does not require public Internet access.

The report should contain sections including:

Executive Summary

Display prominent metrics such as:

Management Groups
Subscriptions
Resource Groups
Resources
Azure Regions
VNets
Private Endpoints
Policy Assignments

Use large statistic cards.

⸻

Azure Organization

Include:

* tenant information
* management-group summary
* subscriptions by management group
* subscriptions by environment

Charts may include:

* subscription count by management group
* resource count by management group
* resources by subscription

⸻

Resource Estate

Include charts such as:

* Top 20 Azure resource types
* Resources by subscription
* Resources by region
* Resource groups by subscription
* Resources by environment

Use Plotly charts with useful hover information.

⸻

Networking

Include statistics/charts for:

* VNets
* subnets
* peerings
* private endpoints
* public IPs
* firewalls
* NSGs
* route tables
* ExpressRoute
* VPN
* Application Gateways
* load balancers

Where practical, provide tables listing key resources.

⸻

Compute and Platform

Provide high-level counts for major compute/platform services.

Avoid making the dashboard excessively long.

Prioritize architectural relevance.

⸻

Governance

Provide:

* policy assignment counts
* policy scope breakdown
* management-group versus subscription policy assignments
* policy exemptions
* compliance data where available

Use precise language.

⸻

Security

Provide factual security posture information that can be derived from Azure data.

Examples:

Subscriptions with Defender plans enabled
Sentinel workspaces
Key Vault count
Managed identities
Private endpoint count
Public IP count

Avoid unsupported conclusions.

⸻

Data Tables

At the end of the HTML report, provide searchable or sortable tables where practical for:

* subscriptions
* management groups
* resource counts
* major networking resources

Do not embed every Azure resource in the main HTML if it makes the report excessively large.

Detailed exports can be placed separately under:

output/data/

⸻

PowerPoint-ready chart images

In addition to interactive Plotly charts, export PNG images suitable for inserting into PowerPoint.

Generate charts such as:

resources-by-subscription.png
resources-by-region.png
resources-by-type.png
subscriptions-by-management-group.png
resources-by-management-group.png
resources-by-environment.png
network-resource-summary.png

Use high resolution.

Use readable fonts and dimensions appropriate for 16:9 presentation slides.

Avoid tiny labels.

For charts with many categories, limit displayed categories sensibly and group the remainder as Other if mathematically appropriate.

Never silently omit data.

⸻

Executive-report design principles

Assume the senior-management presentation audience is technically knowledgeable but does not need raw Azure inventory.

Use this hierarchy:

Tenant
→ Governance structure
→ Subscription organization
→ Major platform architecture
→ Networking
→ Security/governance
→ Workload/resource footprint

Do not clutter executive diagrams with resource-level details.

The goal should be:

Within 30 seconds, a senior leader should understand how the Azure environment is organized.

Detailed implementation information belongs in engineering/reference diagrams and tables.

⸻

Configuration

Create:

config/report-config.json

Use it for settings such as:

{
  "organizationName": "",
  "reportTitle": "Azure Enterprise Architecture",
  "executiveDiagramMaxDepth": 4,
  "showSubscriptionIds": false,
  "subscriptionIdDisplayLength": 8,
  "topResourceTypes": 20,
  "topSubscriptions": 20,
  "environmentRules": []
}

Add useful options if necessary.

Do not hard-code organization-specific names into Python.

⸻

Environment classification

Implement configurable subscription classification.

For example:

"environmentRules": [
  {
    "name": "Production",
    "patterns": ["prod", "production"]
  },
  {
    "name": "Development",
    "patterns": ["dev", "development"]
  },
  {
    "name": "Test",
    "patterns": ["test", "qa", "uat"]
  },
  {
    "name": "Sandbox",
    "patterns": ["sandbox", "lab"]
  }
]

Prefer explicit tags if available.

Suggested classification precedence:

1. Explicit Azure subscription/resource tags
2. Configured exact mappings
3. Configured regex/name patterns
4. Unknown

Do not guess beyond configured rules.

⸻

Output data exports

Generate CSV files useful for analysts:

output/data/subscriptions.csv
output/data/management-groups.csv
output/data/resource-summary.csv
output/data/network-summary.csv
output/data/policy-summary.csv

Optionally create:

resources.csv

if resource volume is manageable.

⸻

Error handling

Handle common conditions cleanly:

* Azure CLI not installed
* Python not installed
* Graphviz not installed
* Azure CLI session expired
* Azure Resource Graph extension missing
* insufficient permissions
* no management-group access
* malformed API response
* empty Resource Graph result
* individual subscription inaccessible
* unsupported Azure resource type

Provide actionable error messages.

For optional datasets, warn rather than terminating the whole process.

Example:

WARNING: Policy compliance could not be queried due to insufficient permissions.
The remainder of the architecture report will continue.

⸻

Security requirements

Never collect or display:

* Key Vault secret values
* Storage account keys
* SAS tokens
* database passwords
* connection strings
* client secrets
* certificates/private keys
* OAuth tokens
* Azure CLI access tokens

Resource IDs, tenant IDs, subscription IDs, object IDs, management-group IDs, resource names, IP addresses, and architecture metadata may be included because the report is intended for authorized internal use.

⸻

Code quality

Use:

* functions
* clear modules
* type hints in Python
* structured logging
* comments where logic is non-obvious
* meaningful variable names
* exception handling
* reusable functions

Avoid one giant Python file if the implementation becomes substantial.

If appropriate, restructure Python into something like:

azure_report/
    __init__.py
    models.py
    normalize.py
    diagrams.py
    charts.py
    html_report.py
    markdown_report.py

Use your judgment.

⸻

README

Create a complete README containing:

Purpose

Explain that this repository automatically generates architecture and inventory documentation from Azure.

Prerequisites

Document:

* Azure CLI
* Python
* Graphviz
* required Python packages
* Azure Resource Graph CLI support

Authentication

Explain:

az login

Do not recommend storing credentials in source code.

Installation

Example:

python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt

Run

.\scripts\Build-AzureBriefing.ps1

Outputs

Explain every major artifact.

Permissions

Document the Azure read permissions needed for basic inventory and any optional additional permissions for governance/security information.

Use least privilege.

Troubleshooting

Include common errors.

⸻

Development approach

Do not attempt to write the entire system blindly in one enormous response.

Work through the repository systematically.

First:

1. Analyze the requirements.
2. Propose the final architecture.
3. Show me the proposed repository/file structure.
4. Identify Azure CLI commands, Resource Graph queries, APIs, and Python libraries you intend to use.
5. Identify anything that cannot reliably be discovered automatically.
6. Identify potential permission requirements.
7. Identify technical assumptions.

Then begin implementing the project.

As you create each file:

* provide complete working code
* ensure imports match requirements.txt
* ensure paths are consistent
* ensure PowerShell calls match Python interfaces
* ensure generated filenames match the README
* check for syntax/interface inconsistencies

Do not leave pseudocode unless explicitly marked as an optional future enhancement.

⸻

Validation

Build validation into the project.

After collection, report basic sanity checks such as:

Tenant discovered: yes
Management groups: 14
Subscriptions: 37
Resources: 8,421
Resources without subscription mapping: 0
Subscriptions without management-group mapping: 2

Warn about inconsistencies.

Do not silently discard unmapped objects.

Create an optional:

output/reports/data-quality-report.txt

showing:

* unmapped subscriptions
* unknown environments
* missing management-group relationships
* failed queries
* inaccessible subscriptions
* other collection anomalies

⸻

Reproducibility

The generated report should include:

Report generated:
Tenant:
Authenticated account:
Azure cloud:
Inventory timestamp:
Tool version/git commit if available:

This makes the architecture artifact traceable to a particular point in time.

⸻

Future extensibility

Design the architecture so future modules can be added for:

* Azure cost analysis
* Defender for Cloud recommendations
* Azure Policy compliance
* resource tagging compliance
* Azure Monitor coverage
* backup coverage
* disaster recovery
* network flow analysis
* subscription vending
* landing-zone compliance
* Azure Arc
* Entra ID architecture

Do not implement all of those now unless required for the core solution.

Design for them.

⸻

Most important requirement

The result must not merely be a collection of scripts.

Build this as a coherent:

Azure Architecture Reporting System

Azure should remain the source of truth.

The workflow should be:

Azure
   ↓
Automated collection
   ↓
Normalized architecture model
   ↓
Multiple renderers
   ├── Executive diagram
   ├── Engineering diagram
   ├── HTML dashboard
   ├── Markdown documentation
   ├── PNG/SVG presentation assets
   └── CSV/JSON engineering data

The same underlying normalized dataset should drive all artifacts wherever practical.

This is important because I do not want different diagrams or reports to drift out of sync.

Start by designing the solution architecture and repository structure. Then implement it file-by-file.