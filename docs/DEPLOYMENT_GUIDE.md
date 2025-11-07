# Azure Deployment Guide

This guide provides step-by-step instructions for deploying the migrated application to Azure.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Quick Deployment](#quick-deployment)
- [Manual Deployment Steps](#manual-deployment-steps)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before deploying to Azure, ensure you have:

1. **Azure Account**
   - An active Azure subscription
   - Sufficient permissions to create resources

2. **Azure CLI**
   - Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
   - Login: `az login`

3. **Deployed Code**
   - MessageServiceApi built and published
   - GreetingsFunction built and published

## Architecture Overview

The migrated application uses the following Azure resources:

```
┌─────────────────────────────────────────────────────────────┐
│                         Azure Cloud                          │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Azure Functions (Timer Trigger)                    │    │
│  │  - Runs every minute                                │    │
│  │  - Calls MessageService API                         │    │
│  │  - Logs to Application Insights                     │    │
│  └────────────────┬───────────────────────────────────┘    │
│                   │ HTTPS GET /api/message                  │
│                   ▼                                         │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Azure App Service (Linux, .NET 8)                 │    │
│  │  - MessageService API                               │    │
│  │  - GET /api/message endpoint                        │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Application Insights                               │    │
│  │  - Centralized logging and monitoring               │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Storage Account                                    │    │
│  │  - Azure Functions storage                          │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Resources Created

1. **App Service Plan** - Hosts both the API and Function App
2. **App Service** - Runs the MessageService API (.NET 8)
3. **Function App** - Runs the timer-triggered GreetingsFunction
4. **Storage Account** - Required for Azure Functions
5. **Application Insights** - Monitoring and logging
6. **Log Analytics Workspace** - Data storage for Application Insights

## Quick Deployment

### Using the Deployment Script

1. **Navigate to the Infrastructure folder:**
   ```bash
   cd Infrastructure
   ```

2. **Run the deployment script:**
   ```bash
   ./deploy.sh [RESOURCE_GROUP_NAME] [LOCATION]
   ```
   
   Example:
   ```bash
   ./deploy.sh rg-msgapp-dev eastus
   ```

3. **Follow the prompts** and wait for deployment to complete

4. **Deploy the applications** (see [Deploy Application Code](#deploy-application-code) below)

## Manual Deployment Steps

### Step 1: Create Resource Group

```bash
# Set variables
RESOURCE_GROUP="rg-msgapp-dev"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Step 2: Deploy Infrastructure

```bash
# Deploy using Bicep template
az deployment group create \
  --name msgapp-deployment \
  --resource-group $RESOURCE_GROUP \
  --template-file Infrastructure/main.bicep \
  --parameters Infrastructure/main.parameters.json \
  --parameters location=$LOCATION
```

### Step 3: Deploy Application Code

#### Deploy MessageService API

```bash
# Navigate to API project
cd MessageServiceApi

# Publish the application
dotnet publish -c Release -o ./publish

# Create zip file
cd publish
zip -r ../publish.zip .
cd ..

# Get App Service name from deployment
APP_SERVICE_NAME=$(az deployment group show \
  --name msgapp-deployment \
  --resource-group $RESOURCE_GROUP \
  --query properties.outputs.appServiceName.value -o tsv)

# Deploy to App Service
az webapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE_NAME \
  --src publish.zip

echo "API deployed to: https://$APP_SERVICE_NAME.azurewebsites.net"
```

#### Deploy GreetingsFunction

```bash
# Navigate to Function project
cd GreetingsFunction

# Publish the application
dotnet publish -c Release -o ./publish

# Get Function App name from deployment
FUNCTION_APP_NAME=$(az deployment group show \
  --name msgapp-deployment \
  --resource-group $RESOURCE_GROUP \
  --query properties.outputs.functionAppName.value -o tsv)

# Deploy to Function App using Azure CLI
cd publish
zip -r ../publish.zip .
cd ..

az functionapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP_NAME \
  --src publish.zip

echo "Function deployed to Function App: $FUNCTION_APP_NAME"
```

## Configuration

### Environment Variables

The deployment automatically configures the following environment variables:

#### MessageService API
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Application Insights connection
- `ASPNETCORE_ENVIRONMENT` - Environment (Development/Production)

#### GreetingsFunction
- `AzureWebJobsStorage` - Storage account connection string
- `FUNCTIONS_WORKER_RUNTIME` - Set to `dotnet-isolated`
- `FUNCTIONS_EXTENSION_VERSION` - Set to `~4`
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - Application Insights connection
- `MESSAGE_SERVICE_URL` - URL of the deployed MessageService API

### Updating Configuration

To update configuration after deployment:

```bash
# Update App Service setting
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE_NAME \
  --settings KEY=VALUE

# Update Function App setting
az functionapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP_NAME \
  --settings KEY=VALUE
```

## Verification

### Verify MessageService API

1. **Get the API URL:**
   ```bash
   API_URL=$(az deployment group show \
     --name msgapp-deployment \
     --resource-group $RESOURCE_GROUP \
     --query properties.outputs.apiUrl.value -o tsv)
   
   echo "API URL: $API_URL"
   ```

2. **Test the API endpoint:**
   ```bash
   curl $API_URL/api/message
   ```

   Expected response:
   ```json
   {
     "message": "2024-11-07 19:30:00 - Hello World",
     "timestamp": "2024-11-07T19:30:00.000Z"
   }
   ```

3. **Check Swagger UI:**
   ```bash
   echo "Swagger UI: $API_URL/swagger"
   ```
   Open in browser to test interactively

### Verify GreetingsFunction

1. **Check Function App logs:**
   ```bash
   az webapp log tail \
     --resource-group $RESOURCE_GROUP \
     --name $FUNCTION_APP_NAME
   ```

2. **Verify in Application Insights:**
   - Navigate to the Azure Portal
   - Open Application Insights resource
   - Go to "Logs" or "Live Metrics"
   - Look for logs from GreetingsFunction
   - Should see entries every minute

3. **Manual trigger (for testing):**
   ```bash
   # Get the function URL
   FUNCTION_URL=$(az functionapp function show \
     --resource-group $RESOURCE_GROUP \
     --name $FUNCTION_APP_NAME \
     --function-name GreetingsTimerFunction \
     --query invokeUrlTemplate -o tsv)
   
   # Note: Timer triggers cannot be manually invoked via HTTP
   # Check the logs instead to verify execution
   ```

### Monitor Scheduled Execution

The GreetingsFunction runs every minute. To monitor:

1. **View Application Insights Live Metrics:**
   - Azure Portal → Application Insights → Live Metrics
   - Watch for incoming requests every minute

2. **Query logs:**
   ```bash
   az monitor app-insights query \
     --app $(az deployment group show \
       --name msgapp-deployment \
       --resource-group $RESOURCE_GROUP \
       --query properties.outputs.applicationInsightsName.value -o tsv) \
     --analytics-query "traces | where message contains 'GreetingsFunction' | top 10 by timestamp desc"
   ```

## Troubleshooting

### Common Issues

#### 1. Deployment Fails

**Error:** "Deployment template validation failed"
- **Solution:** Check that the Bicep template syntax is correct
- **Verify:** Run `az bicep build --file Infrastructure/main.bicep`

**Error:** "Resource group not found"
- **Solution:** Create the resource group first: `az group create --name <name> --location <location>`

#### 2. API Not Responding

**Check if App Service is running:**
```bash
az webapp show --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME --query state
```

**Check logs:**
```bash
az webapp log tail --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME
```

**Restart App Service:**
```bash
az webapp restart --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME
```

#### 3. Function Not Executing

**Check Function App status:**
```bash
az functionapp show --resource-group $RESOURCE_GROUP --name $FUNCTION_APP_NAME --query state
```

**View Function App logs:**
```bash
az webapp log tail --resource-group $RESOURCE_GROUP --name $FUNCTION_APP_NAME
```

**Check timer trigger configuration:**
- Verify the CRON expression: `0 */1 * * * *` (every minute)
- Ensure the Function App is not stopped

#### 4. Storage Account Issues

**Verify storage account exists:**
```bash
STORAGE_NAME=$(az deployment group show \
  --name msgapp-deployment \
  --resource-group $RESOURCE_GROUP \
  --query properties.outputs.storageAccountName.value -o tsv)

az storage account show --name $STORAGE_NAME --resource-group $RESOURCE_GROUP
```

#### 5. Application Insights Not Showing Data

**Check connection string:**
```bash
az webapp config appsettings list \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE_NAME \
  --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING'].value" -o tsv
```

**Note:** Application Insights can have a delay of 1-2 minutes before showing data

### Getting Help

- **Azure CLI Documentation:** https://docs.microsoft.com/en-us/cli/azure/
- **Azure Functions Documentation:** https://docs.microsoft.com/en-us/azure/azure-functions/
- **App Service Documentation:** https://docs.microsoft.com/en-us/azure/app-service/

### Cost Management

Monitor and control costs:

1. **View current costs:**
   ```bash
   az consumption usage list --resource-group $RESOURCE_GROUP
   ```

2. **Set up budget alerts:**
   - Azure Portal → Cost Management + Billing → Budgets

3. **Stop resources when not in use:**
   ```bash
   # Stop App Service
   az webapp stop --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME
   
   # Stop Function App
   az functionapp stop --resource-group $RESOURCE_GROUP --name $FUNCTION_APP_NAME
   ```

4. **Delete all resources:**
   ```bash
   az group delete --name $RESOURCE_GROUP --yes --no-wait
   ```

## Next Steps

- Review the [Local Testing Guide](./LOCAL_TESTING_GUIDE.md) for development and testing
- Set up CI/CD pipelines for automated deployments
- Configure custom domains and SSL certificates
- Implement additional security measures (Key Vault, Managed Identity)
- Scale resources based on usage patterns
