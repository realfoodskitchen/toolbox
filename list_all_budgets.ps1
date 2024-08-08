# Install the necessary module if not already installed
Install-Module -Name Az -AllowClobber -Force

# Import the module
Import-Module Az

# Log in to Azure (If not already logged in)
Connect-AzAccount

# Get a list of all subscriptions
$subscriptions = Get-AzSubscription

# Initialize an array to store budget and alert details
$allBudgetsWithAlerts = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Set the current subscription context
    Set-AzContext -SubscriptionId $subscription.Id

    # Retrieve all budgets for the current subscription
    $budgets = Get-AzConsumptionBudget

    # Loop through each budget to include alert details
    foreach ($budget in $budgets) {
        # Create a custom object to store budget details with alerts
        $budgetWithAlerts = [PSCustomObject]@{
            SubscriptionId = $subscription.Id
            BudgetName     = $budget.Name
            Amount         = $budget.Amount
            TimeGrain      = $budget.TimeGrain
            Category       = $budget.Category
            Alerts         = $budget.Notifications
        }

        # Add the budget with alerts to the array
        $allBudgetsWithAlerts += $budgetWithAlerts
    }
}

# Output the collected budget and alert details
$allBudgetsWithAlerts | Format-Table -Property SubscriptionId, BudgetName, Amount, TimeGrain, Category, Alerts

# Optionally, export the collected budgets with alerts to a CSV file
$allBudgetsWithAlerts | Export-Csv -Path "AllAzureBudgetsWithAlerts.csv" -NoTypeInformation