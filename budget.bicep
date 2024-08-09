param budgetName string
param budgetAmount int
param timeGrain string
param actualNotificationsCount int
param forecastedNotificationsCount int
param actualNotifications array
param forecastedNotifications array

resource budget 'Microsoft.Consumption/budgets@2021-10-01' = {
  name: budgetName
  location: resourceGroup().location
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: timeGrain
    notifications: {}
  }
}

var actualNotificationSettings = [for i in range(0, actualNotificationsCount): {
  ('ActualThreshold' + actualNotifications[i].threshold): {
    enabled: true
    operator: actualNotifications[i].operator
    threshold: actualNotifications[i].threshold
    contactEmails: actualNotifications[i].contactEmails
    contactRoles: []
    thresholdType: 'Actual'
  }
}]

var forecastedNotificationSettings = [for i in range(0, forecastedNotificationsCount): {
  ('ForecastedThreshold' + forecastedNotifications[i].threshold): {
    enabled: true
    operator: forecastedNotifications[i].operator
    threshold: forecastedNotifications[i].threshold
    contactEmails: forecastedNotifications[i].contactEmails
    contactRoles: []
    thresholdType: 'Forecasted'
  }
}]

budget.properties.notifications = union(union({}, actualNotificationSettings...), forecastedNotificationSettings...)
