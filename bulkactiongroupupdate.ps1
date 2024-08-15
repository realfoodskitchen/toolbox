actionGroupId=$(az monitor action-group show --name <action-group-name> --resource-group <resource-group-name> --query id --output tsv)

metricAlertRules=$(az monitor metrics alert list --resource-group <resource-group-name> --query "[?contains(name, '<search-string>')].name" --output tsv)

activityLogAlertRules=$(az monitor activity-log alert list --resource-group <resource-group-name> --query "[?contains(name, '<search-string>')].name" --output tsv)

for alertRule in $metricAlertRules; do
    echo "Updating metric alert rule: $alertRule"
    az monitor metrics alert update \
        --name $alertRule \
        --resource-group <resource-group-name> \
        --add actions actionGroupId=$actionGroupId
done

for alertRule in $activityLogAlertRules; do
    echo "Updating activity log alert rule: $alertRule"
    az monitor activity-log alert action-group add \
        --name $alertRule \
        --resource-group <resource-group-name> \
        --action-group $actionGroupId
done


