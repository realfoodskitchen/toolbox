# Install the required module
Install-Module -Name Microsoft.Graph -AllowClobber -Force

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Group.Read.All", "DeviceManagementConfiguration.Read.All", "Application.Read.All" -UseDeviceAuthentication

# Define the group name
$groupName = "YourGroupName"

# Get the group ID
$Group = Get-MgGroup -Filter "displayName eq '$groupName'" | Select-Object -ExpandProperty Id

# Get all assigned device configuration profiles
$DeviceConfigurations = Get-MgDeviceManagementDeviceConfigurations -Filter "assignments/any(a:a/target/groupId eq '$Group')" -Select Id, DisplayName

# Get all assigned applications
$AssignedApps = Get-MgDeviceAppManagementMobileApps -Filter "assignments/any(a:a/groupId eq '$Group')" -Select Id, DisplayName

# Output the results
Write-Host "Device Configuration Profiles for group '$groupName':"
$DeviceConfigurations | ForEach-Object {
    Write-Host $_.DisplayName
}

Write-Host "Assigned Applications for group '$groupName':"
$AssignedApps | ForEach-Object {
    Write-Host $_.DisplayName
}
