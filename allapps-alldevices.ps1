# Load and connect to Graph
Import-Module Microsoft.Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All"

# Output file
$csvPath = ".\Intune_DeviceAppInventory.csv"
"DeviceName,DeviceId,UserPrincipalName,Platform,AppName,AppVersion,Publisher" | Out-File -FilePath $csvPath -Encoding UTF8

# Step 1: Get all detected apps
$detectedApps = @()
$uri = "https://graph.microsoft.com/beta/deviceManagement/detectedApps?`$top=100"

do {
    $result = Invoke-MgGraphRequest -Method GET -Uri $uri
    $detectedApps += $result.value
    $uri = $result.'@odata.nextLink'
} while ($uri)

# Step 2: For each app, get devices it's installed on
foreach ($app in $detectedApps) {
    $appId = $app.id
    $appName = $app.displayName
    $appVersion = $app.version
    $publisher = $app.publisher

    Write-Host "Processing app: $appName" -ForegroundColor Cyan

    $devicesUri = "https://graph.microsoft.com/beta/deviceManagement/detectedApps/$appId/managedDevices"

    try {
        $devices = Invoke-MgGraphRequest -Method GET -Uri $devicesUri
    } catch {
        Write-Warning "Failed to retrieve devices for app $appName"
        continue
    }

    foreach ($device in $devices.value) {
        # Safely get optional fields
        $deviceName = $device.deviceName
        $deviceId = $device.id
        $user = $device.userPrincipalName
        $platform = $device.operatingSystem

        "$deviceName,$deviceId,$user,$platform,$appName,$appVersion,$publisher" |
            Out-File -FilePath $csvPath -Append -Encoding UTF8
    }
}