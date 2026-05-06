# M365 License Assignment Report
# Shows:
# - SKUs assigned to groups
# - SKUs directly assigned to users
# - Does NOT enumerate group members
# - Does NOT query every user, only licensed users

# Requires:
# Install-Module Microsoft.Graph -Scope CurrentUser

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Identity.DirectoryManagement

$ReportPath = ".\M365-License-Assignment-Report.html"

# Delegated auth.
# If Directory.Read.All has already been consented in the tenant, this should not trigger new admin consent.
Connect-MgGraph -Scopes "Directory.Read.All" -NoWelcome

Write-Host "Collecting subscribed SKUs..."
$SubscribedSkus = Get-MgSubscribedSku -All

$SkuLookup = @{}
foreach ($sku in $SubscribedSkus) {
    $SkuLookup[$sku.SkuId.Guid] = $sku
}

Write-Host "Collecting license-enabled groups..."
$LicensedGroups = Get-MgGroup `
    -Filter "assignedLicenses/`$count ne 0" `
    -ConsistencyLevel eventual `
    -CountVariable licensedGroupCount `
    -All `
    -Property "id,displayName,description,mail,groupTypes,securityEnabled,assignedLicenses"

$GroupRows = foreach ($group in $LicensedGroups) {
    foreach ($license in $group.AssignedLicenses) {
        $sku = $SkuLookup[$license.SkuId.Guid]

        [PSCustomObject]@{
            AssignmentType = "Group-Based"
            SkuPartNumber = $sku.SkuPartNumber
            ConsumedUnits = $sku.ConsumedUnits
            PrepaidUnits  = $sku.PrepaidUnits.Enabled
            AssignedTo    = $group.DisplayName
            ObjectType    = if ($group.GroupTypes -contains "Unified") { "Microsoft 365 Group" } elseif ($group.SecurityEnabled) { "Security Group" } else { "Group" }
            Mail          = $group.Mail
            ObjectId      = $group.Id
            DisabledPlans = if ($license.DisabledPlans.Count -gt 0) {
                ($license.DisabledPlans | ForEach-Object {
                    $planId = $_
                    $plan = $sku.ServicePlans | Where-Object { $_.ServicePlanId -eq $planId }
                    if ($plan) { $plan.ServicePlanName } else { $planId }
                }) -join ", "
            } else {
                "None"
            }
            Description   = $group.Description
        }
    }
}

Write-Host "Collecting licensed users with minimal properties..."
$LicensedUsers = Get-MgUser `
    -Filter "assignedLicenses/`$count ne 0" `
    -ConsistencyLevel eventual `
    -CountVariable licensedUserCount `
    -All `
    -Property "id,displayName,userPrincipalName,licenseAssignmentStates"

$DirectRows = foreach ($user in $LicensedUsers) {
    $directAssignments = $user.LicenseAssignmentStates | Where-Object {
        [string]::IsNullOrWhiteSpace($_.AssignedByGroup)
    }

    foreach ($assignment in $directAssignments) {
        $sku = $SkuLookup[$assignment.SkuId.Guid]

        [PSCustomObject]@{
            AssignmentType = "Direct User"
            SkuPartNumber = $sku.SkuPartNumber
            ConsumedUnits = $sku.ConsumedUnits
            PrepaidUnits  = $sku.PrepaidUnits.Enabled
            AssignedTo    = $user.DisplayName
            ObjectType    = "User"
            Mail          = $user.UserPrincipalName
            ObjectId      = $user.Id
            DisabledPlans = "N/A"
            Description   = ""
        }
    }
}

$AllRows = @($GroupRows + $DirectRows)

$SummaryRows = $AllRows |
    Group-Object SkuPartNumber, AssignmentType |
    ForEach-Object {
        $parts = $_.Name -split ", "
        [PSCustomObject]@{
            SkuPartNumber  = $parts[0]
            AssignmentType = $parts[1]
            Count          = $_.Count
        }
    } |
    Sort-Object SkuPartNumber, AssignmentType

$Css = @"
<style>
body {
    font-family: Segoe UI, Arial, sans-serif;
    margin: 24px;
    color: #222;
}
h1, h2 {
    color: #1f1f1f;
}
.summary {
    background: #eef3f8;
    border-left: 5px solid #2b579a;
    padding: 12px;
    margin-bottom: 24px;
}
table {
    border-collapse: collapse;
    width: 100%;
    font-size: 13px;
    margin-bottom: 28px;
}
th {
    background: #333;
    color: white;
    text-align: left;
    padding: 8px;
}
td {
    border: 1px solid #ddd;
    padding: 8px;
    vertical-align: top;
}
tr:nth-child(even) {
    background: #f7f7f7;
}
.badge-direct {
    background: #ffe4e1;
    padding: 3px 6px;
    border-radius: 4px;
}
.badge-group {
    background: #e1f0ff;
    padding: 3px 6px;
    border-radius: 4px;
}
</style>
"@

$SummaryHtml = $SummaryRows |
    ConvertTo-Html -Fragment `
    -Property SkuPartNumber, AssignmentType, Count

$GroupHtml = $GroupRows |
    Sort-Object SkuPartNumber, AssignedTo |
    ConvertTo-Html -Fragment `
    -Property SkuPartNumber, AssignedTo, ObjectType, Mail, DisabledPlans, ObjectId, Description

$DirectHtml = $DirectRows |
    Sort-Object SkuPartNumber, AssignedTo |
    ConvertTo-Html -Fragment `
    -Property SkuPartNumber, AssignedTo, Mail, ObjectId

$AllHtml = $AllRows |
    Sort-Object SkuPartNumber, AssignmentType, AssignedTo |
    ConvertTo-Html -Fragment `
    -Property AssignmentType, SkuPartNumber, AssignedTo, ObjectType, Mail, DisabledPlans, ObjectId

$Html = @"
<html>
<head>
<title>Microsoft 365 License Assignment Report</title>
$Css
</head>
<body>

<h1>Microsoft 365 License Assignment Report</h1>

<div class="summary">
<b>Generated:</b> $(Get-Date)<br>
<b>Licensed groups found:</b> $($LicensedGroups.Count)<br>
<b>Licensed users scanned:</b> $($LicensedUsers.Count)<br>
<b>Group-based license assignments:</b> $($GroupRows.Count)<br>
<b>Direct user license assignments:</b> $($DirectRows.Count)<br>
</div>

<h2>Summary by SKU and Assignment Type</h2>
$SummaryHtml

<h2>Group-Based License Assignments</h2>
$GroupHtml

<h2>Direct User License Assignments</h2>
$DirectHtml

<h2>All License Assignments</h2>
$AllHtml

</body>
</html>
"@

$Html | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host "Report written to $ReportPath"