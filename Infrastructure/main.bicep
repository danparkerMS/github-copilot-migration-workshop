// Main Bicep template for deploying the migrated application to Azure
// This creates all necessary Azure resources for the MessageService API and GreetingsFunction

@description('The name prefix for all resources')
param resourcePrefix string = 'msgapp'

@description('The Azure region for all resources')
param location string = resourceGroup().location

@description('The environment name (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('The SKU for the App Service Plan')
@allowed([
  'F1'  // Free tier
  'B1'  // Basic tier
  'S1'  // Standard tier
])
param appServicePlanSku string = 'B1'

// Variables
var appServicePlanName = '${resourcePrefix}-plan-${environment}'
var appServiceName = '${resourcePrefix}-api-${environment}'
var functionAppName = '${resourcePrefix}-func-${environment}'
var storageAccountName = '${resourcePrefix}${environment}${uniqueString(resourceGroup().id)}'
var applicationInsightsName = '${resourcePrefix}-insights-${environment}'
var logAnalyticsWorkspaceName = '${resourcePrefix}-logs-${environment}'

// Log Analytics Workspace for Application Insights
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Application Insights for monitoring both API and Function
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    RetentionInDays: 90
  }
}

// Storage Account for Azure Functions
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

// App Service Plan for both API and Function
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServicePlanSku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// App Service for MessageService API
resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: appServiceName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: appServicePlanSku != 'F1' // Always On not available in Free tier
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environment == 'prod' ? 'Production' : 'Development'
        }
      ]
    }
  }
}

// Function App for scheduled task
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNET-ISOLATED|8.0'
      alwaysOn: appServicePlanSku != 'F1' // Always On not available in Free tier
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'MESSAGE_SERVICE_URL'
          value: 'https://${appService.properties.defaultHostName}'
        }
      ]
    }
  }
}

// Outputs
output apiUrl string = 'https://${appService.properties.defaultHostName}'
output functionAppName string = functionApp.name
output appServiceName string = appService.name
output applicationInsightsName string = applicationInsights.name
output storageAccountName string = storageAccount.name
