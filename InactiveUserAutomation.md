# Context & Objective

You are assisting with the design and implementation of an **automated inactive privileged account detection workflow** for a customer that uses **Microsoft Entra ID heavily** and maintains **separate privileged accounts** per user.

The customer’s requirements:
- Privileged accounts are **separate identities** (not just role assignments).
- Each privileged account has the owning user’s **regular email address stored in `otherMails`**.
- The customer wants **automated detection**, **notification**, and **ticketing**, but **no automated removal of access**.
- Exact inactivity thresholds:
  - **20 days → notify user**
  - **25 days → notify user**
  - **29 days → notify user**
  - **30+ days → send ticket to access management team**
- Emails must trigger **only on the exact day** (no ranges, no repeats).
- Enforcement actions (role removal + disable) are **manual**, performed by the access team from the ticket.
- Initial development must run **in production in detection-only mode**, with **no emails sent**.

---

# Key Design Decisions (Already Made)

## Platform choice
- **Azure Logic Apps (Consumption)** is the chosen platform.
- Rationale:
  - Native recurrence scheduling
  - First-class **Managed Identity**
  - Direct Microsoft Graph REST calls (no SDK drift)
  - Lower long-term maintenance than Azure Automation Runbooks
  - Better security posture than Power Automate for directory governance

## Authentication & Security
- Use **system-assigned managed identity**.
- Graph **application permissions (read-only)**:
  - `User.Read.All`
  - `AuditLog.Read.All`
- No permissions to remove roles or disable users.
- No secrets, no certificates, no Key Vault dependency.

---

# Scope of Accounts

Preferred approach:
- A **dedicated Entra ID security group** containing all managed privileged accounts.

Alternate (less preferred):
- Naming convention (e.g., `adm-*` UPNs).

Disabled accounts are excluded from evaluation.

---

# Detection Logic (Authoritative)

## Activity signal
Use **one normalized activity date per account**:


Notes:
- Ignore failed sign-ins.
- Ignore non-interactive sign-ins.
- Accounts that never signed in fall back to `createdDateTime`.

## Inactivity calculation
daysInactive = floor( differenceInDays( nowUtc, effectiveLastActivityDate ) )

## Threshold matching (EXACT equality)
Only trigger when:
daysInactive == 20
OR daysInactive == 25
OR daysInactive == 29
No ranges.
No >= or <=.
No repeats.

---

# Current Phase: Detection-Only Validation

## Required behavior
- NO emails sent.
- NO tickets created.
- NO access changes.
- Logic App runs daily in production.
- Results are logged for validation.

## Logging requirements
For each matched account, log:
- userPrincipalName
- objectId
- effectiveLastActivityDate
- daysInactive
- thresholdMatched (20 | 25 | 29)
- otherMails
- evaluationTimestamp

Also log per-run summary:
- totalAccountsEvaluated
- totalMatches
- matchCountByThreshold

---

# Time Simulation (Critical for Testing)

The Logic App includes:
- `Mode = DetectOnly`
- Optional `TestNowOverride` parameter

Behavior:
- If `TestNowOverride` is empty → use `utcNow()`
- If populated → treat it as the current time

This allows simulation of day 20 → 25 → 29 without waiting real time.

---

# Validation Expectations

Known test accounts should behave as follows:

| Days Inactive | Expected Outcome |
|-------------|-----------------|
| 0–19 | No record |
| 20 | Logged once |
| 21–24 | No record |
| 25 | Logged once |
| 26–28 | No record |
| 29 | Logged once |
| 30+ | No record (handled later) |

If records repeat across days, the logic is incorrect.

---

# Next Steps (After Detection Is Proven)

1. Introduce **Mode = Enforce**
2. Replace logging with:
   - Email to `otherMails` at 20 / 25 / 29
3. Add **state tracking** only for:
   - Preventing duplicate 30+ day tickets
4. At 30+ days:
   - Send ticket email to access management system
   - Include role inventory + disable instruction
   - Still no automated removal

---

# Key Constraint to Preserve

This solution intentionally **stops at notification + ticketing**.
Automated role removal or account disablement is **explicitly out of scope**.

---

# Guiding Principle

If the workflow cannot:
- Explain exactly *why* a user matched a threshold
- Be replayed deterministically
- Be audited after the fact

Then it is not production-ready.

Your task is to help implement, validate, and harden this Logic App design without expanding scope.
