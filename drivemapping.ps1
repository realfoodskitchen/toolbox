I prefer to keep it simple.

1.	⁠You maintain access to the folders based on the users Security Groups
2.	⁠The script contains all of the File Shares, but does not map file shares it cannot connect to
3.	⁠The script runs at logon, and every time you connect the VPN


The script below does the following:

1.	⁠Creates a FileShare.ps1 script in the C:\NetworkDrive\CompanyName directory
2.	⁠Creates a .vbs script which allows the script to be ran completely silently, without a small powershell window opening
3.	⁠Creates a Scheduled task, which subscribes to certain events
4.	⁠Attempts to connect to each Network Path, and if it fails it will skip to the next one, ensuring that it doesnt attempt to map drives the user does not have access to leaving a network drive with a red X
5.	⁠Edits the Registry, so that the Network Drive is correctly named F:\ Finance, and not F:\ \\Server.domain\Finance$

This method being used below is similiar to how IntuneDriveMapping is doing it, however this has been a lot more stable for us, especially in relation to maintaining File Share names. Sometimes during a Windows Update, File Shares deployed with the Intune Drive Mapping generator would lose their naming convention.

$ScriptContent = @'
# Variables
$Drives = @(
    @{
        DriveLetter = "F"
        NetworkPath = "\\Server.domain\Finance$"
        DriveName   = "Finance"
    },
    @{
        DriveLetter = "P"
        NetworkPath = "\\server.domain\pers$\$ENV:USERNAME"
        DriveName   = "Personal"
    }
 
    # Add more drives as needed
)
# Iterate through the drives and map them
foreach ($Drive in $Drives) {
    $DriveLetter = $Drive.DriveLetter
    $NetworkPath = $Drive.NetworkPath
    $DriveName = $Drive.DriveName

    # Check if the user has access to the drive
    if (!(Test-Path $NetworkPath)) {
        Write-Host "User does not have access to the $($DriveName) drive ($($DriveLetter):). Skipping."
        continue
    }

    # Check if the drive is already mapped with the correct settings
    $existingDrive = Get-WmiObject -Class Win32_MappedLogicalDisk | Where-Object {$_.DeviceID -eq "$($DriveLetter):"} | Select-Object -First 1
    if ($existingDrive -ne $null -and $existingDrive.ProviderName -eq $NetworkPath) {
        Write-Host "Drive $($DriveLetter): is already mapped with the correct settings. Skipping."
    } else {
        # Unmap the drive if it already exists
        net use "$($DriveLetter):" /delete /y

        # Map the drive with the 'net use' command
        net use "$($DriveLetter):" $NetworkPath /persistent:yes

        # Create or update the registry key to set the drive label
        $RegistryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\$($NetworkPath.Replace('\', '#'))"
        if (-not (Test-Path $RegistryPath)) {
            try {
                New-Item -Path $RegistryPath -Force -ErrorAction Stop | Out-Null
            } catch {
                Write-Error "Error creating registry key: $($_.Exception.Message)"
            }
        }
        if ((Get-ItemProperty -Path $RegistryPath -Name "_LabelFromReg" -ErrorAction SilentlyContinue) -eq $null) {
            try {
                New-ItemProperty -Path $RegistryPath -Name "_LabelFromReg" -Value $DriveName -PropertyType String -Force -ErrorAction Stop | Out-Null
            } catch {
                Write-Error "Error creating registry value: $($_.Exception.Message)"
            }
        } else {
            try {
                Set-ItemProperty -Path $RegistryPath -Name "_LabelFromReg" -Value $DriveName -ErrorAction Stop
            } catch {
                Write-Error "Error updating registry value: $($_.Exception.Message)"
            }
        }
    }
}

'@


##Create Script to be ran in Scheduled Task
$DestinationFolder = "C:\NetworkDrive\CompanyName"
$DestinationPath = "$DestinationFolder\FileShares.ps1"

if (!(Test-Path $DestinationFolder)) {
    New-Item -ItemType Directory -Path $DestinationFolder -Force
}

Set-Content -Path $DestinationPath -Value $ScriptContent

# Create the VBS file to run the PowerShell script silently
$VbsFilePath = "C:\NetworkDrive\CompanyName\NetworkDrive.vbs"
$VbsScript = "Set objShell = CreateObject(""WScript.Shell"")`n" +
             "objShell.Run(""powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\NetworkDrive\CompanyName\FileShares.ps1""), 0, True`n"
Set-Content -Path $VbsFilePath -Value $VbsScript



## Create the Scheduled Task
$TaskName = "CompanyName Drive Mapping"
$TaskDescription = "Connects to Drive Shares"
$Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "$VbsFilePath"
$trigger = New-ScheduledTaskTrigger -AtLogOn
$class = cimclass MSFT_TaskEventTrigger root/Microsoft/Windows/TaskScheduler
$trigger2 = $class | New-CimInstance -ClientOnly
$trigger2.Enabled = $True
$trigger2.Subscription = '<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[Provider[@Name=''Microsoft-Windows-NetworkProfile''] and EventID=10002]]</Select></Query></QueryList>'
$trigger3 = $class | New-CimInstance -ClientOnly
$trigger3.Enabled = $True
$trigger3.Subscription = '<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[Provider[@Name=''Microsoft-Windows-NetworkProfile''] and EventID=4004]]</Select></Query></QueryList>'
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$explorerProcess = Get-WmiObject -Query "Select * from Win32_Process WHERE Name='explorer.exe'" -ErrorAction Stop
$explorerProcess.GetOwner().User | ForEach-Object {
    $loggedInUser = $_
}
$principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -Id "Author"
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $trigger,$trigger2,$trigger3 -Settings $Settings -Description $TaskDescription -Principal $Principal
Start-ScheduledTask -TaskName $Taskname