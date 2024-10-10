# Import the Active Directory module (requires RSAT tools installed)
Import-Module ActiveDirectory

# Get the currently logged-in user's username
$CurrentUser = $env:USERNAME

# Query AD for the user's department
$User = Get-ADUser -Identity $CurrentUser -Properties Department

# Check if department was retrieved
if ($User -ne $null) {
    $Department = $User.Department
    Write-Host "User department is: $Department"

    # Map the J Drive based on the department
    if ($Department -eq "HR") {
        New-PSDrive -Name "J" -PSProvider FileSystem -Root "\\server\HR_Share" -Persist
    }
    elseif ($Department -eq "Finance") {
        New-PSDrive -Name "J" -PSProvider FileSystem -Root "\\server\Finance_Share" -Persist
    }
    elseif ($Department -eq "IT") {
        New-PSDrive -Name "J" -PSProvider FileSystem -Root "\\server\IT_Share" -Persist
    }
    else {
        Write-Host "No specific drive mapping for department: $Department"
    }

    # Map the F Drive (Personal Share) using the username
    New-PSDrive -Name "F" -PSProvider FileSystem -Root "\\server\PersonalShare\$CurrentUser" -Persist
} else {
    Write-Host "Unable to retrieve the department from Active Directory."
}

# Confirm drive mappings
Get-PSDrive -PSProvider FileSystem