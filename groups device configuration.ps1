# Connect to Microsoft Graph with the correct schema
Connect-MgGraph -Scopes "DeviceManagementConfiguration.Read.All"
Update-MgEnvironment -SchemaVersion beta

# Get all Intune groups in AAD with specific names
$Groups = Get-MgGroup -Filter "startswith(displayName, 'NL-') or contains(displayName, 'Intune')" -All

# Loop through each group and gather details
foreach ($Group in $Groups) {
    Write-Host "AAD Group Name: $($Group.DisplayName)" -ForegroundColor Green
    
    # Get group members
    $AllAssignedUsers = Get-MgGroupMember -GroupId $Group.Id -All | Select-Object -Property DisplayName
    Write-Host "Number of Users found: $($AllAssignedUsers.Count)" -ForegroundColor Cyan
    foreach ($User in $AllAssignedUsers) {
        Write-Host " " $User.DisplayName -ForegroundColor Gray
    }

    # Get assigned Intune Mobile Apps
    $AllAssignedApps = Get-MgDeviceAppManagementMobileApps -Filter "isAssigned eq true" -All | Where-Object {$_.Assignments -match $Group.Id}
    Write-Host "Number of Apps found: $($AllAssignedApps.Count)" -ForegroundColor Cyan
    foreach ($App in $AllAssignedApps) {
        Write-Host " " $App.DisplayName -ForegroundColor Yellow
    }

    # Get Device Compliance policies
    $AllDeviceCompliance = Get-MgDeviceManagementDeviceCompliancePolicy -All | Where-Object {$_.Assignments -match $Group.Id}
    Write-Host "Number of Device Compliance policies found: $($AllDeviceCompliance.Count)" -ForegroundColor Cyan
    foreach ($Policy in $AllDeviceCompliance) {
        Write-Host " " $Policy.DisplayName -ForegroundColor Yellow
    }

    # Get Device Configurations
    $AllDeviceConfig = Get-MgDeviceManagementDeviceConfigurations -All | Where-Object {$_.Assignments -match $Group.Id}
    Write-Host "Number of Device Configurations found: $($AllDeviceConfig.Count)" -ForegroundColor Cyan
    foreach ($Config in $AllDeviceConfig) {
        Write-Host " " $Config.DisplayName -ForegroundColor Yellow
    }

    # Device Configuration PowerShell Scripts
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts?$expand=groupAssignments"
    $DMS = Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $((Get-MgContext).AccessToken)"}
    $AllDeviceConfigScripts = $DMS.value | Where-Object { $_.groupAssignments -match $Group.Id }
    Write-Host "Number of Device Configurations PowerShell Scripts found: $($AllDeviceConfigScripts.Count)" -ForegroundColor Cyan
    foreach ($Script in $AllDeviceConfigScripts) {
        Write-Host " " $Script.DisplayName -ForegroundColor Yellow
    }

    # Settings Catalogs
    $uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?$expand=Assignments"
    $SC = Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $((Get-MgContext).AccessToken)"}
    $AllSC = $SC.value | Where-Object { $_.Assignments -match $Group.Id }
    Write-Host "Number of Device Settings Catalogs found: $($AllSC.Count)" -ForegroundColor Cyan
    foreach ($Catalog in $AllSC) {
        Write-Host " " $Catalog.Name -ForegroundColor Yellow
    }

    # Administrative Templates
    $uri = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations?$expand=Assignments"
    $ADMT = Invoke-RestMethod -Method Get -Uri $uri -Headers @{Authorization = "Bearer $((Get-MgContext).AccessToken)"}
    $AllADMT = $ADMT.value | Where-Object { $_.Assignments -match $Group.Id }
    Write-Host "Number of Device Administrative Templates found: $($AllADMT.Count)" -ForegroundColor Cyan
    foreach ($Template in $AllADMT) {
        Write-Host " " $Template.DisplayName -ForegroundColor Yellow
    }
}