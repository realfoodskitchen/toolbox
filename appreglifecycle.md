# Entra ID App Registration Lifecycle – Mature Reference Architecture

A mature App Registration lifecycle in Azure Entra ID is based on control, visibility, least privilege, and accountability.  
Applications must be treated as workload identities with production risk, not developer objects.

This document describes a reference architecture and lifecycle model covering intake, provisioning, permission approval, validation, monitoring, recertification, and decommissioning.

---

# 1. Target Operating Model

A mature design separates responsibilities.

## Roles

Business owner  
Owns the use case and data access.

Technical owner  
Owns implementation and credential rotation.

IAM / Entra platform team  
Controls creation standards and automation.

Security / governance team  
Reviews permissions, external exposure, risk tier.

Privileged approver  
Performs admin consent using PIM.

Core principle:

> Every app registration / service principal is a workload identity with lifecycle ownership.

---

# 2. Control Stack Architecture

A mature design has three layers.

### Request / approval layer
- Intake system of record
- Risk classification
- Permission justification
- Exception tracking

### Control layer
- Entra consent restrictions
- PIM for admin roles
- Conditional Access (workload identities when supported)
- Credential standards
- Naming standards
- Owner enforcement

### Operations layer
- Reporting
- Access reviews
- Permission recertification
- Expiration monitoring
- Decommission workflow

---

# 3. Intake Process

Intake must exist before the app is created.

## Required fields

- Business owner
- Technical owner
- Owner group
- App purpose
- Environment (prod / dev / test)
- Data classification
- Permissions requested
- Auth method
- Internal / external / multi-tenant
- Review date
- Expiration date
- Ticket ID

## Risk tiers

Tier 0  
Internal, low privilege, managed identity preferred

Tier 1  
Delegated permissions, internal

Tier 2  
Application permissions, external, sensitive data

Tier 3  
Directory-wide / mail / files / role / multi-tenant

## Mandatory gates

- Owner defined
- Permissions justified
- Auth method approved
- Review cadence assigned
- Exception documented

---

# 4. Creation / Provisioning

Users should not freely create apps in production.

Creation should happen through:

- Automation
- IAM workflow
- PIM role activation
- Controlled admin group

## Provisioning standards

Every app must get:

- Naming convention
- Owner assignment
- Owner group
- Environment tag
- Ticket reference
- Review date
- Credential expiration
- Metadata

## Credential standard

Preferred order

1. Managed identity
2. Workload federation
3. Certificate
4. Secret (last resort)

## Baseline hardening

- Single tenant by default
- No implicit grant unless needed
- No public client unless needed
- No long-lived secrets
- No missing owner
- No missing review date

---

# 5. Permission Approval / Admin Consent

Permission approval must be separate from creation.

## Flow

1. Request permissions
2. Security review
3. Approval recorded
4. Admin consent via PIM
5. Ticket updated

## High-risk permissions

- Directory.*
- User.Read.All
- Mail.*
- Files.*
- Role.*
- AppRoleAssignment.*
- offline_access + wide scope
- Application permissions
- Multi-tenant exposure

## Controls

- Restrict user consent
- Use admin consent workflow
- Require justification

---

# 6. Validation Before Production

Do not allow apps into production without validation.

Checklist:

- Owners correct
- Permissions match approval
- Audience correct
- Auth method correct
- Secret/cert expiration set
- Logging enabled
- Service principal understood
- External exposure intentional
- Conditional Access considered

---

# 7. Ongoing Reviews

Apps must be reviewed like service accounts.

## Monthly

- Expiring secrets
- No owner
- New permissions
- Inactive apps
- Multi-tenant apps

## Quarterly

- Application permissions
- External apps
- High privilege apps
- Privileged service principals

## Annual

- All apps
- Owner attestation
- Business justification

---

# 8. Permission Recertification

Permissions must be re-approved periodically.

Review:

- API permissions still needed
- Delegated vs application still needed
- External access still needed
- Admin consent still justified
- Data scope still valid

Recommended cadence:

- Application permissions → 6 months
- High risk delegated → 6 months
- Others → 12 months

---

# 9. Usage Validation / Monitoring

Track usage continuously.

Monitor:

- Last sign-in
- Token usage
- Permission use
- Owner status
- External access
- Multi-tenant
- Publisher info

Flag:

- No sign-in 90 days
- No owner
- Expired secret
- Too many permissions
- New high privilege
- Sudden permission growth

Use:

- Entra logs
- Graph reporting
- Defender for Cloud Apps
- Sentinel

---

# 10. Protect the Admin Roles

Use PIM for:

- Application admin roles
- Cloud app admin
- Global admin (consent)
- Conditional Access admin
- Security admin

No permanent privilege.

---

# 11. Decommissioning Process

Never delete immediately.

## Triggers

- App unused
- Project ended
- Owner left
- Failed review
- Replaced app

## Process

Stage 1 — notify  
Stage 2 — disable credential  
Stage 3 — monitor  
Stage 4 — remove permissions  
Stage 5 — delete SPN  
Stage 6 — delete app  
Stage 7 — close ticket

---

# 12. Governance Dashboard

You must be able to answer:

- Total apps
- Apps with no owner
- Apps with application perms
- Apps with high risk perms
- External apps
- Multi-tenant apps
- Expiring secrets
- Inactive apps
- Apps without review date
- Apps without credential expiry

If you cannot answer these → lifecycle not mature.

---

# 13. Technical Enforcement

Implement:

- User consent restrictions
- Admin consent workflow
- PIM for admin roles
- Conditional Access for workload identities (where supported)
- Expiring secret alerts
- Ownerless app alerts
- Inactive app alerts
- High privilege alerts

---

# 14. Maturity Levels

Level 1 — unmanaged  
Anyone creates apps

Level 2 — controlled  
Limited creation

Level 3 — governed  
Intake + approval

Level 4 — mature  
Recertification + reviews + PIM

Level 5 — advanced  
Automation + telemetry + enforcement

---

# 15. Gold Standard Pattern

Intake  
Central request form

Creation  
IAM / automation only

Auth  
Managed identity → federation → cert → secret

Consent  
Admin workflow required

Admin roles  
PIM required

Reviews  
Monthly / quarterly / annual

Monitoring  
Telemetry + alerts

Recertification  
Required for high privilege

Decommission  
Soft disable → remove → delete

---

End of document