# Requires Microsoft.Graph module
# Install-Module Microsoft.Graph -Scope CurrentUser

Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Groups
Import-Module Microsoft.Graph.Identity.DirectoryManagement

$ReportPath = ".\M365-Group-Based-License-Report.html"

Connect-MgGraph -Scopes "Directory.Read.All" -NoWelcome

# Get tenant SKUs
$Skus = Get-MgSubscribedSku -All

$SkuLookup = @{}
foreach ($sku in $Skus) {
    $SkuLookup[$sku.SkuId.Guid] = $sku
}

# Find groups with assigned licenses
$LicensedGroups = Get-MgGroup `
    -Filter "assignedLicenses/`$count ne 0" `
    -ConsistencyLevel eventual `
    -CountVariable licensedGroupCount `
    -All `
    -Property "id,displayName,description,assignedLicenses,groupTypes,securityEnabled,mailEnabled,mail"

$Rows = foreach ($group in $LicensedGroups) {
    foreach ($license in $group.AssignedLicenses) {
        $sku = $SkuLookup[$license.SkuId.Guid]

        $disabledPlans = foreach ($planId in $license.DisabledPlans) {
            $plan = $sku.ServicePlans | Where-Object { $_.ServicePlanId -eq $planId }
            if ($plan) { $plan.ServicePlanName } else { $planId }
        }

        [PSCustomObject]@{
            GroupName       = $group.DisplayName
            GroupMail       = $group.Mail
            GroupType       = if ($group.GroupTypes -contains "Unified") { "Microsoft 365 Group" } elseif ($group.SecurityEnabled) { "Security Group" } else { "Other" }
            SkuPartNumber   = $sku.SkuPartNumber
            SkuId           = $license.SkuId
            EnabledPlans    = ($sku.ServicePlans | Where-Object { $_.ServicePlanId -notin $license.DisabledPlans } | Select-Object -ExpandProperty ServicePlanName) -join ", "
            DisabledPlans   = if ($disabledPlans) { $disabledPlans -join ", " } else { "None" }
            GroupId         = $group.Id
            Description     = $group.Description
        }
    }
}

$Css = @"
<style>
body { font-family: Segoe UI, Arial, sans-serif; margin: 24px; }
h1 { color: #222; }
table { border-collapse: collapse; width: 100%; font-size: 13px; }
th { background: #333; color: white; text-align: left; padding: 8px; }
td { border: 1px solid #ddd; padding: 8px; vertical-align: top; }
tr:nth-child(even) { background: #f7f7f7; }
.summary { margin-bottom: 20px; padding: 12px; background: #eef3f8; border-left: 4px solid #2b579a; }
</style>
"@

$Summary = @"
<div class='summary'>
<b>Licensed groups found:</b> $($LicensedGroups.Count)<br>
<b>License assignments found:</b> $($Rows.Count)<br>
<b>Generated:</b> $(Get-Date)
</div>
"@

$HtmlTable = $Rows |
    Sort-Object SkuPartNumber, GroupName |
    ConvertTo-Html -Fragment `
        -Property GroupName,GroupMail,GroupType,SkuPartNumber,DisabledPlans,GroupId,Description

$Html = @"
<html>
<head>
<title>Microsoft 365 Group-Based License Report</title>
$Css
</head>
<body>
<h1>Microsoft 365 Group-Based License Report</h1>
$Summary
$HtmlTable
</body>
</html>
"@

$Html | Out-File -FilePath $ReportPath -Encoding UTF8

Write-Host "Report written to $ReportPath"