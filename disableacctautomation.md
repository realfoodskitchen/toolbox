# Urgent Account Disablement Automation (IT-Controlled with Approval)

## 1. Overview

This document defines the design for a temporary automation solution to handle **urgent user account disablement** in a hybrid identity environment.

This solution is:
- Initiated by IT staff (not HR)
- Triggered manually after receiving a request (e.g., via email)
- Requires **peer approval** before execution
- Intended as a **short-term bridge** until Microsoft Entra Lifecycle Workflows / Identity Governance is implemented

---

## 2. Goals

- Enable rapid and controlled disablement of user accounts
- Introduce an approval checkpoint for safety
- Reduce manual administrative steps
- Ensure consistent and auditable execution
- Keep implementation lightweight and easy to replace

---

## 3. High-Level Architecture
[IT Operator]
|
v
[Power Automate Manual Flow]
|
v
[Approval (IT Peer)]
|
v
[Azure Automation Runbook]
|
v
[Hybrid Runbook Worker]
|
+–> Active Directory (Disable + GAL Hide)
+–> Microsoft Graph (Revoke Sessions)
+–> Entra Connect Server (Delta Sync)

---

## 4. Components

### 4.1 Power Automate (Manual Flow)

**Purpose:** Entry point and orchestration

**Responsibilities:**
- Allow IT operator to submit request manually
- Capture:
  - Target user
  - Reason
  - Optional notes
- Capture requester identity automatically
- Trigger approval workflow
- Start Azure Automation runbook after approval
- Send notifications

---

### 4.2 Approval Mechanism

**Type:** Power Automate Approval (Assigned to IT Security Group)

**Requirements:**
- Must be approved by **someone other than the requester**
- Approval includes:
  - Target user
  - Requester
  - Reason
- Approval decision must be logged

---

### 4.3 Azure Automation Account

**Purpose:** Execute backend automation

**Responsibilities:**
- Host PowerShell runbook
- Store variables and credentials
- Execute jobs on Hybrid Runbook Worker

---

### 4.4 Hybrid Runbook Worker

**Purpose:** Execute privileged operations with on-prem access

**Requirements:**
- Domain-joined
- ActiveDirectory module installed
- Network access to:
  - Domain Controllers
  - Entra Connect Server
  - Internet (for Graph)

---

### 4.5 Active Directory

**Operations:**
- Disable user account
- Set `msExchHideFromAddressLists = TRUE`

---

### 4.6 Microsoft Graph

**Operations:**
- Revoke user sign-in sessions

---

### 4.7 Entra Connect Server

**Operation:**
Start-ADSyncSyncCycle -PolicyType Delta

---

## 5. Functional Flow

### Step-by-Step

1. IT operator receives request (e.g., email)
2. IT operator runs Power Automate manual flow
3. Inputs:
   - UserPrincipalName
   - Reason
   - Notes (optional)
4. Flow sends approval request to IT group
5. Approval is reviewed by a different IT member
6. If approved:
   - Azure Automation runbook is triggered
7. Runbook executes:
   - Lookup user in AD
   - Disable account
   - Hide from GAL
   - Revoke Entra sessions
   - Trigger delta sync
8. Logs are written
9. Notification sent to requester

---

## 6. Inputs

| Field              | Required | Description                     |
|-------------------|----------|---------------------------------|
| UserPrincipalName | Yes      | Target user                     |
| Reason            | Yes      | Reason for disablement          |
| Notes             | No       | Additional context              |
| RequestedBy       | Auto     | Flow initiator                  |

---

## 7. Outputs

- Approval result (Approved / Rejected)
- Execution status (Success / Partial / Failure)
- Detailed logs
- Notification to requester

---

## 8. Approval Design

### Rules

- Approver must not be the requester
- Approval assigned to IT security group
- Single approval sufficient (can be extended to multiple)

---

### Approval Payload

- Target User
- Requester
- Reason
- Timestamp

---

### Rejection Handling

If rejected:
- Flow terminates
- Requester notified
- Action is logged

---

## 9. Runbook Design

### Parameters

```powershell
param(
    [string]$UserPrincipalName,
    [string]$RequestedBy,
    [string]$Reason
)
Core Functions
	•	Get-AdUserByUpn
	•	Disable-AdUser
	•	Hide-FromGAL
	•	Connect-ToGraph
	•	Revoke-EntraSessions
	•	Trigger-DeltaSync
	•	Write-Log

START
  -> Validate input
  -> Get AD user
  -> Disable AD account
  -> Set GAL hide
  -> Connect to Graph
  -> Revoke sessions
  -> Trigger delta sync
  -> Log results
END

Idempotency
	•	Already disabled → continue
	•	Already hidden → continue
	•	Not found in Entra → log warning

10. Power Automate Design

Trigger
	•	Manual trigger (button)

Flow Steps
	1.	Manual trigger
	2.	Input validation
	3.	Start Approval
	4.	Condition:
	•	If Approved → continue
	•	If Rejected → terminate
	5.	Call Azure Automation (Create Job)
	6.	Send notification

example payload
{
  "UserPrincipalName": "user@domain.com",
  "RequestedBy": "admin@domain.com",
  "Reason": "Urgent termination"
}

11. Security Design

Access Control
	•	Only IT security group can run the flow
	•	Only authorized identities can approve

Separation of Duties
	•	Requester ≠ Approver
	•	Enforced via flow logic

⸻

Permissions

Active Directory
	•	Disable accounts
	•	Modify GAL attribute

Microsoft Graph
	•	User.Read.All
	•	User.RevokeSessions.All

⸻

Secrets
	•	Stored in Azure Automation
	•	Use certificate or managed identity where possible

⸻

Protected Accounts

Block execution for:
	•	Break-glass accounts
	•	Admin accounts
	•	Service accounts

⸻

12. Logging

Required Fields
	•	Timestamp
	•	Requester
	•	Approver
	•	Target user
	•	Approval result
	•	Execution results
	•	Errors

⸻

Storage
	•	Azure Automation logs (minimum)
	•	Optional: Log Analytics

14. Non-Functional Requirements

Performance
	•	Execution starts within minutes
	•	Minimal delay after approval

Reliability
	•	Safe retries
	•	Clear error logging

Usability
	•	Simple IT-only interface
	•	< 1 minute submission

15. Deployment Plan

Phase 1
	•	Deploy Automation Account
	•	Configure Hybrid Worker

Phase 2
	•	Configure permissions (AD + Graph)

Phase 3
	•	Build runbook

Phase 4
	•	Build Power Automate flow with approval

Phase 5
	•	Testing

Phase 6
	•	Production rollout

⸻

16. Testing
	•	Valid request + approval
	•	Rejected request
	•	Same user (idempotency)
	•	Invalid user
	•	Approval edge case (same user)
	•	Sync trigger validation

19. Success Criteria
	•	IT submits request in < 1 minute
	•	Approval enforced
	•	AD account disabled
	•	GAL hidden
	•	Sessions revoked
	•	Delta sync triggered
	•	Logs captured
	•	Notifications sent

This solution provides a controlled, IT-driven, approval-based automation for urgent account disablement using:
	•	Power Automate (manual trigger + approval)
	•	Azure Automation (execution)
	•	Hybrid Runbook Worker (on-prem access)

It balances:
	•	speed
	•	security
	•	simplicity

while remaining easy to replace with Lifecycle Workflows in the future.


