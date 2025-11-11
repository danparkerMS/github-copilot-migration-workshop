# CI/CD Quick Reference

Quick reference for using the GitHub Actions CI/CD pipeline.

## 🚀 Quick Start

### First-Time Setup (5 minutes)

1. **Create Azure Service Principal**
   ```bash
   az ad sp create-for-rbac \
     --name "github-actions-msgapp" \
     --role contributor \
     --scopes /subscriptions/YOUR_SUBSCRIPTION_ID \
     --sdk-auth
   ```

2. **Add GitHub Secret**
   - Go to: Repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `AZURE_CREDENTIALS`
   - Value: Paste the JSON output from step 1

3. **Create Resource Group**
   ```bash
   az group create --name rg-msgapp-dev --location eastus
   ```

4. **Push to main** or **Run workflow manually**

## 📋 Common Tasks

### Deploy to Dev Environment
```bash
git push origin main
```
The workflow will automatically deploy to the dev environment.

### Deploy to Prod Environment
1. Go to: Actions → Deploy to Azure
2. Click "Run workflow"
3. Select: `prod`
4. Click "Run workflow"

### Check Deployment Status
1. Go to: Actions tab
2. Click on the latest "Deploy to Azure" run
3. View job status and logs

### View Deployed Application
After deployment, find URLs in workflow output:
- API: `https://msgapp-api-dev-XXXXX.azurewebsites.net`
- Swagger: Add `/swagger` to API URL

## 🔍 Quick Troubleshooting

### Build Failed
```bash
# Test locally first
cd MessageServiceApi && dotnet build
cd ../GreetingsFunction && dotnet build
```

### Azure Login Failed
Check `AZURE_CREDENTIALS` secret is set correctly:
1. Settings → Secrets and variables → Actions
2. Verify `AZURE_CREDENTIALS` exists
3. If not, recreate Service Principal

### Deployment Failed
Check resource group exists:
```bash
az group show --name rg-msgapp-dev
# If not found:
az group create --name rg-msgapp-dev --location eastus
```

## 📊 Workflow Overview

```
┌─────────────┐
│   Push to   │
│    Main     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ Build (2-3 min)                         │
│ • Restore dependencies                  │
│ • Build API & Function                  │
│ • Create artifacts                      │
└──────┬──────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ Deploy Infrastructure (3-5 min)         │
│ • Create/update Azure resources         │
│ • App Service, Function App, etc.       │
└──────┬──────────────────────────────────┘
       │
       ├─────────────────┬─────────────────┐
       ▼                 ▼                 ▼
┌─────────────┐   ┌─────────────┐
│ Deploy API  │   │   Deploy    │
│  (1-2 min)  │   │  Function   │
│             │   │  (1-2 min)  │
└─────────────┘   └─────────────┘
```

## 🔐 Required Secrets

| Secret Name | Description | Where to Get |
|-------------|-------------|--------------|
| AZURE_CREDENTIALS | Azure Service Principal JSON | `az ad sp create-for-rbac` |

## 🌍 Environments

| Environment | Resource Group | Usage |
|-------------|----------------|-------|
| dev | rg-msgapp-dev | Automatic on push to main |
| test | rg-msgapp-test | Manual deployment |
| prod | rg-msgapp-prod | Manual deployment with approval |

## 📖 Detailed Documentation

For more information, see:
- [Complete CI/CD Setup Guide](CICD_SETUP.md)
- [Deployment Guide](DEPLOYMENT_GUIDE.md)
- [Troubleshooting Guide](CICD_SETUP.md#troubleshooting)

## 💡 Tips

1. **Test locally first**: Always build and test locally before pushing
2. **Small changes**: Deploy small, incremental changes
3. **Monitor costs**: Set up Azure cost alerts
4. **Use environments**: Configure GitHub Environments for prod with required approvals
5. **Check logs**: Use Application Insights for runtime issues

## 🆘 Getting Help

1. Check workflow logs in Actions tab
2. Review [Troubleshooting Guide](CICD_SETUP.md#troubleshooting)
3. Check Application Insights in Azure Portal
4. View Azure Resource Health
