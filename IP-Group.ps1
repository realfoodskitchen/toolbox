# Import the Azure module if not already done
Import-Module Az

# Variables for your Azure environment
$resourceGroupName = "YourResourceGroupName"
$ipGroupName = "YourIPGroupName"            # Name of the new IP Group
$location = "EastUS"                        # Location where you want to create the IP Group

# Read the text file containing the list of unique IP addresses
$ipList = Get-Content "C:\path\to\ip_addresses.txt"

# Remove duplicates by selecting only unique IP addresses
$uniqueIpList = $ipList | Sort-Object -Unique

# Create a new IP Group with the list of IP addresses
$ipGroup = New-AzIpGroup -ResourceGroupName $resourceGroupName `
                         -Name $ipGroupName `
                         -Location $location `
                         -IpAddress $uniqueIpList

# Output the created IP Group details
$ipGroup