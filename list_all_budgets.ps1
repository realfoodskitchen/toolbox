##List all Azure Bdgets across different subscrioptions

# Install the necessary module if not already installed
Install-Module -Name Az -AllowClobber -Force

# Import the module
Import-Module Az

# Log in to Azure (If not already logged in)
Connect-AzAccount

# Get a list of all subscriptions
$subscriptions = Get-AzSubscription

# Initialize an array to store budget details
$allBudgets = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Set the current subscription context
    Set-AzContext -SubscriptionId $subscription.Id

    # Retrieve all budgets for the current subscription
    $budgets = Get-AzConsumptionBudget

    # Add the retrieved budgets to the array
    $allBudgets += $budgets
}

# Output the collected budget details
$allBudgets | Format-Table -Property SubscriptionId,Name,Amount,TimeGrain,Category

# Optionally, export the collected budgets to a CSV file
$allBudgets | Export-Csv -Path "AllAzureBudgets.csv" -NoTypeInformation