$policies = Get-MgConditionalAccessPolicy
foreach ($policy in $policies) {
    $policyName = $policy.DisplayName
    $sessionControls = $policy.SessionControls
    Write-Output "Policy: $policyName"
    Write-Output "Session Controls: $(($sessionControls | ConvertTo-Json -Depth 10))"
}

$policies = Get-MgConditionalAccessPolicy
foreach ($policy in $policies) {
    if ($policy.SessionControls.ContinuousAccessEvaluation) {
        Write-Output "Policy: $($policy.DisplayName) has CAE configured."
    }
}

Get-MgConditionalAccessPolicy | ForEach-Object {
    [PSCustomObject]@{
        PolicyName = $_.DisplayName
        SessionControls = ($_.SessionControls | ConvertTo-Json -Depth 10)
    }
} | Export-Csv -Path "CAE_Policy_Report.csv" -NoTypeInformation


