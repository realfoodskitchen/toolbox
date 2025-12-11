<# 
.SYNOPSIS
    Unified PIM activation helper (Entra roles + PIM-for-Groups)

.DESCRIPTION
    - Uses device code auth for MFA on another device
    - Lists ONLY roles you are PIM-eligible for, filtered to a curated, high-value set
    - Lists all PIM-for-Groups eligible memberships
    - Unified, numbered menu
    - Single or multi-selection activation in one shot
    - Prompts for duration, justification, ticket system, ticket number

.REQUIREMENTS
    - PowerShell 7+
    - Microsoft.Graph and Microsoft.Graph.Identity.Governance modules installed
      Install-Module Microsoft.Graph -Scope CurrentUser
      Install-Module Microsoft.Graph.Identity.Governance -Scope CurrentUser
#>

[CmdletBinding()]
param()

#region Helper functions

function Connect-PimGraph {
    Write-Host "Connecting to Microsoft Graph (device code)..."

    $scopes = @(
        # Directory roles (read/write PIM)
        "RoleManagement.ReadWrite.Directory",
        "Directory.Read.All",

        # PIM for Groups (eligibility + assignment)  [oai_citation:0‡Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.governance/new-mgidentitygovernanceprivilegedaccessgroupassignmentschedulerequest?view=graph-powershell-1.0&utm_source=chatgpt.com)
        "PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup",
        "PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup",

        # Groups metadata
        "Group.Read.All"
    )

    Connect-MgGraph -Scopes $scopes -UseDeviceCode
    Import-Module Microsoft.Graph.Identity.Governance -ErrorAction Stop
    $ctx = Get-MgContext
    if (-not $ctx -or -not $ctx.Account) {
        throw "Failed to get Graph context after Connect-MgGraph."
    }

    # Resolve current user object (principalId) from UPN  [oai_citation:1‡ManageEngine](https://www.manageengine.com/products/ad-manager/powershell/get-mgrolemanagementdirectoryroleassignment.html?utm_source=chatgpt.com)
    $me = Get-MgUser -UserId $ctx.Account -ErrorAction Stop
    return $me.Id
}

function Get-EligibleDirectoryRoles {
    param(
        [Parameter(Mandatory)] [string] $PrincipalId
    )

    # List of "interesting" roles for the menu (ordered by privilege)
    $roleOrder = @(
        "Global Administrator",
        "Privileged Role Administrator",
        "Privileged Authentication Administrator",
        "Security Administrator",
        "Conditional Access Administrator",
        "Identity Governance Administrator",
        "Compliance Administrator",
        "Exchange Administrator",
        "SharePoint Administrator",
        "Teams Administrator",
        "Power Platform Administrator",
        "Intune Administrator",
        "Application Administrator",
        "Groups Administrator",
        "User Administrator",
        "AI Administrator",
        "Windows 365 Administrator",
        "License Administrator",
        "Message Center Privacy Reader",
        "Service Support Administrator",
        "Global Reader",
        "Security Reader"
    )

    $roleRank = @{}
    $i = 1
    foreach ($name in $roleOrder) {
        $roleRank[$name] = $i
        $i++
    }

    Write-Host "Retrieving PIM-eligible directory roles for current user..."
    $eligibility = Get-MgRoleManagementDirectoryRoleEligibilitySchedule `
        -Filter "principalId eq '$PrincipalId'" -All -ErrorAction SilentlyContinue

    if (-not $eligibility) {
        return @()
    }

    # Get distinct roleDefinitionIds and resolve to role definitions  [oai_citation:2‡Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.governance/get-mgrolemanagementdirectoryroledefinition?view=graph-powershell-1.0&utm_source=chatgpt.com)
    $roleDefIds = $eligibility | Select-Object -ExpandProperty RoleDefinitionId -Unique
    $roleDefinitions = @{}
    foreach ($id in $roleDefIds) {
        try {
            $def = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $id -ErrorAction Stop
            $roleDefinitions[$id] = $def
        } catch {
            Write-Verbose "Could not resolve role definition $id: $($_.Exception.Message)"
        }
    }

    $results = @()

    foreach ($item in $eligibility) {
        $def = $roleDefinitions[$item.RoleDefinitionId]
        if (-not $def) { continue }

        # Only keep roles in the curated list
        if ($roleRank.ContainsKey($def.DisplayName)) {
            $results += [pscustomobject]@{
                Type             = "Role"
                DisplayName      = $def.DisplayName
                RoleDefinitionId = $def.Id
                Rank             = $roleRank[$def.DisplayName]
            }
        }
    }

    # Sort by rank (privilege) then name
    $results | Sort-Object Rank, DisplayName
}

function Get-EligiblePimGroups {
    param(
        [Parameter(Mandatory)] [string] $PrincipalId
    )

    Write-Host "Retrieving PIM-for-Groups eligible memberships for current user..."

    $groupElig = Get-MgIdentityGovernancePrivilegedAccessGroupEligibilitySchedule `
        -Filter "principalId eq '$PrincipalId'" -All -ErrorAction SilentlyContinue  [oai_citation:3‡Stack Overflow](https://stackoverflow.com/questions/77636299/ms-graph-ps-commands-to-elevate-join-users-to-privileged-security-group?utm_source=chatgpt.com)

    if (-not $groupElig) {
        return @()
    }

    $groupIds = $groupElig | Select-Object -ExpandProperty GroupId -Unique
    $groupMap = @{}

    foreach ($gid in $groupIds) {
        try {
            $g = Get-MgGroup -GroupId $gid -ErrorAction Stop
            $groupMap[$gid] = $g
        } catch {
            Write-Verbose "Could not resolve group $gid: $($_.Exception.Message)"
        }
    }

    $results = @()
    foreach ($gid in $groupMap.Keys) {
        $g = $groupMap[$gid]
        $results += [pscustomobject]@{
            Type        = "Group"
            DisplayName = $g.DisplayName
            GroupId     = $g.Id
            Rank        = 500  # after roles
        }
    }

    # Sort alphabetically among groups
    $results | Sort-Object DisplayName
}

function Show-Menu {
    param(
        [Parameter(Mandatory)] [array] $Items
    )

    Write-Host ""
    Write-Host "========= PIM-Eligible Items ========="
    Write-Host "Roles (Entra directory roles) are listed first (most → least privileged),"
    Write-Host "then PIM-for-Groups memberships." 
    Write-Host ""

    $index = 1
    foreach ($item in $Items) {
        $label = if ($item.Type -eq "Role") {
            "[Role ]"
        } else {
            "[Group]"
        }

        Write-Host ("{0,3}. {1} {2}" -f $index, $label, $item.DisplayName)
        $index++
    }

    Write-Host ""
}

function Get-Selection {
    param(
        [Parameter(Mandatory)] [int] $Max
    )

    $multi = Read-Host "Activate multiple items? (1 = No, 2 = Yes)"

    if ($multi -eq "2") {
        $raw = Read-Host "Enter one or more numbers (comma-separated) or 'all'"
        $raw = $raw.Trim()

        if ($raw -ieq "all") {
            return (1..$Max)
        }

        $parts = $raw -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        $indices = @()
        foreach ($p in $parts) {
            if ([int]::TryParse($p, [ref]$null)) {
                $n = [int]$p
                if ($n -ge 1 -and $n -le $Max) {
                    $indices += $n
                }
            }
        }

        $indices = $indices | Select-Object -Unique | Sort-Object
        if (-not $indices) {
            throw "No valid selection provided."
        }
        return $indices
    }
    else {
        $raw = Read-Host "Enter the number of the item to activate"
        if (-not [int]::TryParse($raw, [ref]$null)) {
            throw "Invalid selection."
        }
        $n = [int]$raw
        if ($n -lt 1 -or $n -gt $Max) {
            throw "Selection out of range."
        }
        return @($n)
    }
}

function Prompt-PimMetadata {
    # Shared for all activations in this run
    Write-Host ""
    Write-Host "========= Activation Details ========="

    $durationRaw = Read-Host "Activation duration in HOURS (e.g. 1, 2, 4, 8)"
    if (-not [int]::TryParse($durationRaw, [ref]$null)) {
        throw "Duration must be an integer number of hours."
    }
    $durationHours = [int]$durationRaw
    if ($durationHours -le 0) {
        throw "Duration must be greater than zero."
    }

    $justification = ""
    while ([string]::IsNullOrWhiteSpace($justification)) {
        $justification = Read-Host "Justification (required by PIM policies)"
    }

    $ticketSystem = Read-Host "Ticket system (e.g., ServiceNow, JIRA) - optional, press Enter to skip"
    $ticketNumber = Read-Host "Ticket number - optional, press Enter to skip"

    $ticketInfo = $null
    if ($ticketSystem -or $ticketNumber) {
        $ticketInfo = @{
            ticketSystem = $ticketSystem
            ticketNumber = $ticketNumber
        }
    }

    return [pscustomobject]@{
        DurationHours = $durationHours
        Justification = $justification
        TicketInfo    = $ticketInfo
    }
}

function Activate-DirectoryRole {
    param(
        [Parameter(Mandatory)] [string] $PrincipalId,
        [Parameter(Mandatory)] [string] $RoleDefinitionId,
        [Parameter(Mandatory)] [string] $DisplayName,
        [Parameter(Mandatory)] [int]    $DurationHours,
        [Parameter(Mandatory)] [string] $Justification,
        [Parameter()]          $TicketInfo
    )

    Write-Host ""
    Write-Host "Activating role: $DisplayName"

    $params = @{
        action         = "selfActivate"
        principalId    = $PrincipalId
        roleDefinitionId = $RoleDefinitionId
        directoryScopeId = "/"   # tenant-wide  [oai_citation:4‡ManageEngine](https://www.manageengine.com/products/ad-manager/powershell/get-mgrolemanagementdirectoryroleassignment.html?utm_source=chatgpt.com)
        justification  = $Justification
        scheduleInfo   = @{
            expiration = @{
                type     = "afterDuration"
                duration = ("PT{0}H" -f $DurationHours)
            }
        }
    }

    if ($TicketInfo) {
        $params.ticketInfo = $TicketInfo
    }

    try {
        $result = New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params -ErrorAction Stop  [oai_citation:5‡Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.governance/get-mgrolemanagementdirectoryroleeligibilityschedule?view=graph-powershell-1.0&utm_source=chatgpt.com)
        Write-Host " → Request submitted (ID: $($result.Id), status: $($result.Status))"
    }
    catch {
        Write-Warning " → Failed to activate role '$DisplayName': $($_.Exception.Message)"
    }
}

function Activate-PimGroupMembership {
    param(
        [Parameter(Mandatory)] [string] $PrincipalId,
        [Parameter(Mandatory)] [string] $GroupId,
        [Parameter(Mandatory)] [string] $DisplayName,
        [Parameter(Mandatory)] [int]    $DurationHours,
        [Parameter(Mandatory)] [string] $Justification,
        [Parameter()]          $TicketInfo
    )

    Write-Host ""
    Write-Host "Activating PIM group membership: $DisplayName"

    $params = @{
        accessId     = "member"     # membership, not owner  [oai_citation:6‡Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.governance/new-mgidentitygovernanceprivilegedaccessgroupassignmentschedulerequest?view=graph-powershell-1.0&utm_source=chatgpt.com)
        principalId  = $PrincipalId
        groupId      = $GroupId
        action       = "selfActivate"
        justification = $Justification
        scheduleInfo = @{
            startDateTime = (Get-Date).ToUniversalTime()
            expiration    = @{
                type     = "afterDuration"
                duration = ("PT{0}H" -f $DurationHours)
            }
        }
    }

    if ($TicketInfo) {
        $params.ticketInfo = $TicketInfo
    }

    try {
        $result = New-MgIdentityGovernancePrivilegedAccessGroupAssignmentScheduleRequest -BodyParameter $params -ErrorAction Stop  [oai_citation:7‡Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.identity.governance/new-mgidentitygovernanceprivilegedaccessgroupassignmentschedulerequest?view=graph-powershell-1.0&utm_source=chatgpt.com)
        Write-Host " → Request submitted (ID: $($result.Id), status: $($result.Status))"
    }
    catch {
        Write-Warning " → Failed to activate group '$DisplayName': $($_.Exception.Message)"
    }
}

#endregion Helper functions

#region Main

try {
    $principalId = Connect-PimGraph
}
catch {
    Write-Error "Could not connect to Graph or resolve current user: $($_.Exception.Message)"
    return
}

$roleItems  = Get-EligibleDirectoryRoles -PrincipalId $principalId
$groupItems = Get-EligiblePimGroups       -PrincipalId $principalId

$items = @()
$items += $roleItems
$items += $groupItems

if (-not $items -or $items.Count -eq 0) {
    Write-Warning "No PIM-eligible roles or PIM-for-Groups memberships found for the current user."
    return
}

Show-Menu -Items $items

$selection = $null
try {
    $selection = Get-Selection -Max $items.Count
}
catch {
    Write-Error $_.Exception.Message
    return
}

$meta = $null
try {
    $meta = Prompt-PimMetadata
}
catch {
    Write-Error $_.Exception.Message
    return
}

foreach ($idx in $selection) {
    $item = $items[$idx - 1]

    if ($item.Type -eq "Role") {
        Activate-DirectoryRole `
            -PrincipalId     $principalId `
            -RoleDefinitionId $item.RoleDefinitionId `
            -DisplayName     $item.DisplayName `
            -DurationHours   $meta.DurationHours `
            -Justification   $meta.Justification `
            -TicketInfo      $meta.TicketInfo
    }
    elseif ($item.Type -eq "Group") {
        Activate-PimGroupMembership `
            -PrincipalId   $principalId `
            -GroupId       $item.GroupId `
            -DisplayName   $item.DisplayName `
            -DurationHours $meta.DurationHours `
            -Justification $meta.Justification `
            -TicketInfo    $meta.TicketInfo
    }
}

Write-Host ""
Write-Host "Done. Check PIM in the Entra portal to confirm activation state and any approvals still pending."

#endregion Main