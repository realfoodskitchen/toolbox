<#
.SYNOPSIS
Checks for role assignments of a specific Entra ID group across all management groups and subscriptions.

.DESCRIPTION
This script searches for all role assignments for a specified Entra ID group across:
- All management groups in the tenant
- All subscriptions in the tenant

.PARAMETER GroupObjectId
The Object ID of the Entra ID group to check

.PARAMETER GroupName
The display name of the Entra ID group to check (alternative to ObjectId)

.EXAMPLE
.\Check-GroupRoleAssignments.ps1 -GroupObjectId “12345678-1234-1234-1234-123456789abc”

.EXAMPLE
.\Check-GroupRoleAssignments.ps1 -GroupName “Legacy App Group”
#>

[CmdletBinding(DefaultParameterSetName=‘ByObjectId’)]
param(
[Parameter(Mandatory=$true, ParameterSetName=‘ByObjectId’)]
[string]$GroupObjectId,

```
[Parameter(Mandatory=$true, ParameterSetName='ByName')]
[string]$GroupName
```

)

# Ensure required modules are installed

$requiredModules = @(‘Az.Accounts’, ‘Az.Resources’)
foreach ($module in $requiredModules) {
if (!(Get-Module -ListAvailable -Name $module)) {
Write-Warning “Module $module is not installed. Installing…”
Install-Module -Name $module -Scope CurrentUser -Force
}
}

# Import modules

Import-Module Az.Accounts
Import-Module Az.Resources

# Connect to Azure if not already connected

$context = Get-AzContext
if (!$context) {
Write-Host “Connecting to Azure…” -ForegroundColor Cyan
Connect-AzAccount
}

# If group name is provided, get the object ID

if ($PSCmdlet.ParameterSetName -eq ‘ByName’) {
Write-Host “Looking up group by name: $GroupName” -ForegroundColor Cyan
try {
$group = Get-AzADGroup -DisplayName $GroupName
if (!$group) {
Write-Error “Group with name ‘$GroupName’ not found.”
exit
}
if ($group.Count -gt 1) {
Write-Warning “Multiple groups found with name ‘$GroupName’. Using first match.”
$group = $group[0]
}
$GroupObjectId = $group.Id
Write-Host “Found group: $($group.DisplayName) (ID: $GroupObjectId)” -ForegroundColor Green
}
catch {
Write-Error “Error looking up group: $_”
exit
}
}
else {
# Verify the group exists
try {
$group = Get-AzADGroup -ObjectId $GroupObjectId
Write-Host “Found group: $($group.DisplayName) (ID: $GroupObjectId)” -ForegroundColor Green
}
catch {
Write-Error “Group with Object ID ‘$GroupObjectId’ not found.”
exit
}
}

$results = @()

# Check Management Groups

Write-Host “`nChecking Management Groups…” -ForegroundColor Cyan
try {
$managementGroups = Get-AzManagementGroup
$mgCount = 0

```
foreach ($mg in $managementGroups) {
    Write-Host "  Checking management group: $($mg.DisplayName)" -ForegroundColor Gray
    
    $roleAssignments = Get-AzRoleAssignment -Scope $mg.Id -ObjectId $GroupObjectId -ErrorAction SilentlyContinue
    
    if ($roleAssignments) {
        foreach ($assignment in $roleAssignments) {
            $mgCount++
            $results += [PSCustomObject]@{
                Scope = "Management Group"
                Name = $mg.DisplayName
                Id = $mg.Name
                RoleDefinitionName = $assignment.RoleDefinitionName
                RoleAssignmentId = $assignment.RoleAssignmentId
            }
        }
    }
}

Write-Host "  Found $mgCount role assignment(s) in management groups" -ForegroundColor $(if($mgCount -gt 0){"Yellow"}else{"Green"})
```

}
catch {
Write-Warning “Error checking management groups: $_”
}

# Check Subscriptions

Write-Host “`nChecking Subscriptions…” -ForegroundColor Cyan
try {
$subscriptions = Get-AzSubscription
$subCount = 0

```
foreach ($sub in $subscriptions) {
    Write-Host "  Checking subscription: $($sub.Name)" -ForegroundColor Gray
    
    # Set context to subscription
    Set-AzContext -SubscriptionId $sub.Id -WarningAction SilentlyContinue | Out-Null
    
    $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($sub.Id)" -ObjectId $GroupObjectId -ErrorAction SilentlyContinue
    
    if ($roleAssignments) {
        foreach ($assignment in $roleAssignments) {
            $subCount++
            $results += [PSCustomObject]@{
                Scope = "Subscription"
                Name = $sub.Name
                Id = $sub.Id
                RoleDefinitionName = $assignment.RoleDefinitionName
                RoleAssignmentId = $assignment.RoleAssignmentId
            }
        }
    }
}

Write-Host "  Found $subCount role assignment(s) in subscriptions" -ForegroundColor $(if($subCount -gt 0){"Yellow"}else{"Green"})
```

}
catch {
Write-Warning “Error checking subscriptions: $_”
}

# Display Results

Write-Host “`n=================================” -ForegroundColor Cyan
Write-Host “RESULTS” -ForegroundColor Cyan
Write-Host “=================================” -ForegroundColor Cyan
Write-Host “Group: $($group.DisplayName)” -ForegroundColor White
Write-Host “Object ID: $GroupObjectId” -ForegroundColor White
Write-Host “Total Role Assignments Found: $($results.Count)” -ForegroundColor $(if($results.Count -gt 0){“Yellow”}else{“Green”})

if ($results.Count -gt 0) {
Write-Host “`nDetailed Assignments:” -ForegroundColor Yellow
$results | Format-Table -AutoSize

```
# Export to CSV
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvPath = "GroupRoleAssignments_$timestamp.csv"
$results | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "Results exported to: $csvPath" -ForegroundColor Green
```

}
else {
Write-Host “`nNo role assignments found. This group appears to be unused for Azure RBAC.” -ForegroundColor Green
}