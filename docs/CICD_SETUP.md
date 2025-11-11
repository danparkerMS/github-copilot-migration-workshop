# CI/CD Setup Guide

This guide explains how to set up and use the GitHub Actions CI/CD pipeline for deploying the application to Azure.

> **🚀 Quick Start?** If you just need to get started quickly, see the [CI/CD Quick Reference](CICD_QUICK_REFERENCE.md).

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Azure Setup](#azure-setup)
4. [GitHub Secrets Configuration](#github-secrets-configuration)
5. [Triggering Deployments](#triggering-deployments)
6. [Verifying Deployments](#verifying-deployments)
7. [Rollback Procedures](#rollback-procedures)
8. [Troubleshooting](#troubleshooting)

## Overview

The CI/CD pipeline automatically builds and deploys the application to Azure when changes are pushed to the `main` branch. It consists of four main jobs:

1. **Build**: Compiles the .NET projects and creates deployment artifacts
2. **Deploy Infrastructure**: Creates/updates Azure resources using Bicep
3. **Deploy API**: Deploys the MessageServiceApi to Azure App Service
4. **Deploy Function**: Deploys the GreetingsFunction to Azure Functions

### Workflow Features

- ✅ Automated deployment on push to `main` branch
- ✅ Manual deployment trigger with environment selection
- ✅ Build validation for both API and Function projects
- ✅ Infrastructure as Code deployment using Bicep
- ✅ Secure secret management via GitHub Secrets
- ✅ Post-deployment verification
- ✅ Support for multiple environments (dev, test, prod)

## Prerequisites

Before setting up the CI/CD pipeline, ensure you have:

- **Azure Subscription**: An active Azure subscription
- **Azure CLI**: Installed locally ([Install guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- **GitHub Repository**: Admin access to the repository
- **Permissions**: Ability to create Azure Service Principals or configure OIDC

## Azure Setup

### Step 1: Login to Azure

```bash
az login
```

Select your subscription:

```bash
# List subscriptions
az account list --output table

# Set the subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Step 2: Create a Service Principal

The pipeline uses a Service Principal to authenticate with Azure. Create one with the following command:

```bash
# Set variables
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SERVICE_PRINCIPAL_NAME="github-actions-msgapp"

# Create service principal
az ad sp create-for-rbac \
  --name "$SERVICE_PRINCIPAL_NAME" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth
```

This command will output a JSON object. **Save this entire JSON output** - you'll need it for GitHub Secrets.

Example output:
```json
{
  "clientId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "clientSecret": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
  "subscriptionId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "tenantId": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### Step 3: Create Azure Resource Group

The pipeline expects a resource group to exist. Create one for each environment:

```bash
# For dev environment
az group create --name rg-msgapp-dev --location eastus

# For test environment (optional)
az group create --name rg-msgapp-test --location eastus

# For prod environment (optional)
az group create --name rg-msgapp-prod --location eastus
```

## GitHub Secrets Configuration

### Required Secrets

Navigate to your GitHub repository → Settings → Secrets and variables → Actions, and add the following secret:

#### 1. AZURE_CREDENTIALS

- **Name**: `AZURE_CREDENTIALS`
- **Value**: The entire JSON output from the Service Principal creation step
- **Description**: Azure authentication credentials for the Service Principal

### Optional: Environment-Specific Secrets

For production deployments, you may want to use GitHub Environments to add protection rules and environment-specific secrets.

To configure environments:

1. Go to repository Settings → Environments
2. Create environments: `dev`, `test`, `prod`
3. Add protection rules (e.g., required reviewers for `prod`)
4. Add environment-specific secrets if needed

## Triggering Deployments

### Automatic Deployment

The pipeline automatically triggers when:

- Code is pushed to the `main` branch
- Changes are made to these paths:
  - `MessageServiceApi/**`
  - `GreetingsFunction/**`
  - `Infrastructure/**`
  - `.github/workflows/deploy.yml`

### Manual Deployment

You can manually trigger a deployment from the GitHub Actions tab:

1. Go to **Actions** tab in your repository
2. Select **Deploy to Azure** workflow
3. Click **Run workflow**
4. Select the environment (dev/test/prod)
5. Click **Run workflow** button

### Workflow Steps

When triggered, the workflow performs these steps:

1. **Build Phase** (~2-3 minutes)
   - Checkout code
   - Setup .NET 8.0
   - Restore NuGet packages
   - Build MessageServiceApi
   - Build GreetingsFunction
   - Create deployment artifacts

2. **Infrastructure Deployment** (~3-5 minutes)
   - Deploy Bicep templates
   - Create/update Azure resources:
     - App Service Plan
     - App Service (for API)
     - Function App (for scheduled task)
     - Storage Account
     - Application Insights
     - Log Analytics Workspace

3. **API Deployment** (~1-2 minutes)
   - Deploy API to Azure App Service
   - Verify deployment with health check

4. **Function Deployment** (~1-2 minutes)
   - Deploy Function to Azure Functions
   - Display deployment summary

**Total Time**: Approximately 7-12 minutes

## Verifying Deployments

### Check Workflow Status

1. Go to **Actions** tab in your repository
2. Click on the latest workflow run
3. Review each job's status and logs

### Verify API Deployment

Once deployed, test the API:

```bash
# Replace with your actual API URL
API_URL="https://msgapp-api-dev-XXXXXX.azurewebsites.net"

# Test the message endpoint
curl $API_URL/api/message

# Expected response:
# {"message":"2024-11-11 21:30:00 - Hello World","timestamp":"2024-11-11T21:30:00.000Z"}

# View Swagger documentation
open $API_URL/swagger
```

### Verify Function Deployment

Check the Function App logs:

```bash
FUNCTION_APP_NAME="msgapp-func-dev-XXXXXX"

# Stream function logs
az functionapp log tail --name $FUNCTION_APP_NAME --resource-group rg-msgapp-dev
```

Or check in the Azure Portal:
1. Navigate to your Function App
2. Go to **Functions** → **GreetingsTimerFunction**
3. Click **Monitor** to see execution history
4. Verify the function runs every minute

### Verify in Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your Resource Group (e.g., `rg-msgapp-dev`)
3. Verify these resources exist:
   - App Service Plan
   - App Service (API)
   - Function App
   - Storage Account
   - Application Insights
4. Check Application Insights for telemetry data

## Rollback Procedures

### Option 1: Redeploy Previous Version

The safest rollback method is to redeploy a known good version:

1. Identify the commit SHA of the last working version
2. Go to **Actions** tab
3. Run workflow manually
4. Before clicking "Run workflow", change the branch to the specific commit or tag

### Option 2: Azure App Service Deployment Slots (Recommended for Production)

For zero-downtime deployments and easy rollback:

1. Modify the Bicep template to create a deployment slot
2. Deploy to the staging slot first
3. Test the deployment
4. Swap slots when ready
5. If issues occur, swap back

Example Bicep modification:
```bicep
resource appServiceSlot 'Microsoft.Web/sites/slots@2022-09-01' = {
  parent: appService
  name: 'staging'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
  }
}
```

### Option 3: Manual Rollback via Azure Portal

1. Go to Azure Portal → Your App Service
2. Select **Deployment Center** → **Deployment Logs**
3. Find the previous successful deployment
4. Click **Redeploy**

### Option 4: Revert Git Commit

If the deployment is broken:

1. Revert the problematic commit:
   ```bash
   git revert <commit-sha>
   git push origin main
   ```
2. The pipeline will automatically redeploy the reverted code

## Troubleshooting

### Common Issues and Solutions

#### Issue: Build Failures

**Symptom**: Build job fails with compilation errors

**Solutions**:
- Check the build logs in GitHub Actions
- Ensure code builds locally: `dotnet build`
- Verify .NET SDK version matches workflow (8.0.x)
- Check for missing NuGet packages

#### Issue: Azure Login Failed

**Symptom**: "Azure Login" step fails with authentication error

**Solutions**:
- Verify `AZURE_CREDENTIALS` secret is correctly set
- Check Service Principal hasn't expired
- Ensure Service Principal has Contributor role
- Recreate the Service Principal if needed:
  ```bash
  az ad sp delete --id <old-sp-object-id>
  # Then recreate as shown in Azure Setup
  ```

#### Issue: Resource Group Not Found

**Symptom**: Infrastructure deployment fails with "ResourceGroupNotFound"

**Solutions**:
- Create the resource group manually:
  ```bash
  az group create --name rg-msgapp-dev --location eastus
  ```
- Or modify the Bicep template to create it automatically

#### Issue: Deployment Timeout

**Symptom**: Deployment job times out after 6 hours (GitHub Actions limit)

**Solutions**:
- Check Azure Portal for deployment status
- Look for stuck resources in Azure
- Cancel the deployment in Azure:
  ```bash
  az deployment group cancel --name <deployment-name> --resource-group <rg-name>
  ```
- Retry the deployment

#### Issue: Function App Deployment Failed

**Symptom**: Function deployment step fails

**Solutions**:
- Verify the Function App exists in Azure
- Check Function App runtime is set to .NET 8 Isolated
- Ensure storage account is accessible
- Check the Function App logs:
  ```bash
  az functionapp log tail --name <function-app-name> --resource-group <rg-name>
  ```

#### Issue: API Returns 503 Service Unavailable

**Symptom**: API is deployed but returns 503 errors

**Solutions**:
- Check App Service logs in Azure Portal
- Verify Application Insights for errors
- Restart the App Service:
  ```bash
  az webapp restart --name <app-service-name> --resource-group <rg-name>
  ```
- Check if the App Service Plan has sufficient resources

#### Issue: Function Not Triggering

**Symptom**: Function is deployed but not executing on schedule

**Solutions**:
- Check the timer trigger configuration in `GreetingsTimerFunction.cs`
- Verify the Function App is running:
  ```bash
  az functionapp show --name <function-app-name> --resource-group <rg-name> --query state
  ```
- Check Application Settings in Azure Portal for `MESSAGE_SERVICE_URL`
- Enable and check Application Insights for execution logs

### Debug Mode

To enable detailed logging in the workflow:

1. Go to repository Settings → Secrets and variables → Actions
2. Add a new secret:
   - Name: `ACTIONS_STEP_DEBUG`
   - Value: `true`
3. Re-run the workflow

### Getting Help

If you encounter issues not covered here:

1. Check the [GitHub Actions documentation](https://docs.github.com/en/actions)
2. Review [Azure deployment documentation](https://docs.microsoft.com/en-us/azure/app-service/deploy-github-actions)
3. Check Application Insights for application-level errors
4. Review Azure Resource Health in the portal

### Viewing Deployment History

To view past deployments:

```bash
# List deployments in a resource group
az deployment group list \
  --resource-group rg-msgapp-dev \
  --query "[].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}" \
  --output table

# Get details of a specific deployment
az deployment group show \
  --name <deployment-name> \
  --resource-group rg-msgapp-dev
```

## Best Practices

1. **Use Environments**: Configure GitHub Environments for dev, test, and prod with appropriate protection rules
2. **Require Reviews**: Enable required reviewers for production deployments
3. **Monitor Costs**: Set up Azure Cost Alerts to monitor spending
4. **Use Tags**: Add tags to Azure resources for better organization
5. **Backup Secrets**: Store Service Principal credentials securely (e.g., password manager)
6. **Regular Updates**: Keep GitHub Actions and Azure services updated
7. **Test Locally**: Always test changes locally before pushing to main
8. **Small Changes**: Deploy small, incremental changes for easier rollback

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Application Insights Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
