# Migration Complete! 🎉

[![Deploy to Azure](https://github.com/danparkerMS/github-copilot-migration-workshop/actions/workflows/deploy.yml/badge.svg)](https://github.com/danparkerMS/github-copilot-migration-workshop/actions/workflows/deploy.yml)

This application has been successfully migrated from .NET Framework 4.8.1 to modern .NET 8, using Azure App Service and Azure Functions.

## What Changed?

### Before (Legacy)
- **MessageService**: ASP.NET Web API 2 on .NET Framework 4.8.1 (Windows only, IIS)
- **GreetingsConsole**: Console app scheduled via Windows Task Scheduler
- **Hosting**: Windows Server with IIS

### After (Modern)
- **MessageServiceApi**: ASP.NET Core Minimal API on .NET 8 (cross-platform)
- **GreetingsFunction**: Azure Function with Timer Trigger (runs every minute)
- **Hosting**: Azure App Service (Linux) + Azure Functions (serverless)

## 📁 Project Structure

```
.
├── MessageService/          # ⚠️ Original .NET Framework application
├── GreetingsConsole/        # ⚠️ Original console application
│
├── MessageServiceApi/       # ✅ NEW: Migrated API (.NET 8)
├── GreetingsFunction/       # ✅ NEW: Migrated Function (.NET 8)
│
├── Infrastructure/          # ✅ NEW: Bicep templates for Azure
└── docs/                    # ✅ NEW: Complete documentation
```

## 🚀 Quick Start

### Run the Migrated Application Locally

**Terminal 1 - Start the API:**
```bash
cd MessageServiceApi
dotnet run
```

**Terminal 2 - Start the Function:**
```bash
cd GreetingsFunction
func start
```

The API will be available at `http://localhost:5000` and the function will execute every minute.

### Test the Application

```bash
# Test the API
curl http://localhost:5000/api/message

# Expected response:
# {
#   "message": "2024-11-07 14:30:00 - Hello World",
#   "timestamp": "2024-11-07T14:30:00.000Z"
# }

# View Swagger UI
open http://localhost:5000/swagger
```

## 📚 Documentation

All documentation is in the `docs/` folder:

- **[docs/README.md](docs/README.md)** - Overview of the migrated application
- **[docs/LOCAL_TESTING_GUIDE.md](docs/LOCAL_TESTING_GUIDE.md)** - How to run and test locally
- **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - How to deploy to Azure manually
- **[docs/CICD_SETUP.md](docs/CICD_SETUP.md)** - CI/CD pipeline setup and usage
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Architecture and design decisions

## 🌐 Deploy to Azure

### Automated Deployment (Recommended)

The application includes a complete CI/CD pipeline using GitHub Actions:

- **Automatic**: Pushes to `main` branch trigger deployment
- **Manual**: Run workflow from GitHub Actions tab
- **Environments**: Support for dev, test, and prod

See **[docs/CICD_SETUP.md](docs/CICD_SETUP.md)** for complete setup instructions.

### Manual Deployment

```bash
cd Infrastructure
./deploy.sh rg-msgapp-dev eastus
```

This will:
1. Create all necessary Azure resources
2. Configure Application Insights for monitoring
3. Provide deployment instructions for the applications

See [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) for detailed steps.

## ✨ Key Improvements

| Aspect | Before | After |
|--------|--------|-------|
| **Framework** | .NET Framework 4.8.1 | .NET 8 |
| **Platform** | Windows only | Cross-platform |
| **API Type** | ASP.NET Web API 2 | Minimal API |
| **Scheduling** | Windows Task Scheduler | Azure Functions Timer |
| **Hosting** | IIS on Windows | Azure App Service (Linux) |
| **Monitoring** | Limited | Application Insights |
| **Cost** | High (24/7 VMs) | Low (serverless + basic tier) |
| **Scalability** | Manual | Automatic |
| **Deployment** | Manual | Automated CI/CD |

## ✅ Migration Checklist

- [x] MessageService migrated to .NET 8 Minimal API
- [x] GreetingsConsole migrated to Azure Functions with Timer Trigger
- [x] Timer configured to run every minute
- [x] Application Insights integrated for monitoring
- [x] Infrastructure as Code created (Bicep)
- [x] Deployment scripts provided
- [x] Comprehensive documentation written
- [x] Local testing validated
- [x] CORS configured for Function → API communication
- [x] Swagger/OpenAPI documentation added
- [x] CI/CD pipeline configured with GitHub Actions
- [x] Automated deployment to Azure on push to main
- [x] Multi-environment support (dev/test/prod)

## 🎯 Success Criteria Met

✅ API returns the same timestamped greeting messages  
✅ Scheduled task runs every minute and calls the API  
✅ Application can be tested locally (and in Codespaces)  
✅ Clear deployment instructions provided  
✅ All code follows modern best practices  
✅ Cost-optimized implementation  
✅ Cloud-native architecture

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       Azure Cloud                            │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Azure Functions (Timer Trigger)                    │    │
│  │  • Runs every minute: "0 */1 * * * *"              │    │
│  │  • Calls MessageService API                         │    │
│  │  • Logs to Application Insights                     │    │
│  └────────────────┬───────────────────────────────────┘    │
│                   │ HTTPS GET /api/message                  │
│                   ▼                                         │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Azure App Service (Linux, .NET 8)                 │    │
│  │  • MessageServiceApi                                │    │
│  │  • GET /api/message endpoint                        │    │
│  │  • Swagger UI at /swagger                           │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Application Insights                               │    │
│  │  • Centralized logging and monitoring               │    │
│  │  • Performance tracking                             │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## 💰 Cost Estimate

**Monthly cost in Azure (B1 tier):** ~$17-20/month

- App Service Plan (B1): ~$13
- Storage Account: ~$1
- Application Insights: ~$2-5
- Function execution: <$1

For development, use F1 (Free) tier to reduce costs to near zero.

## 🔧 Technology Stack

### MessageServiceApi
- .NET 8
- ASP.NET Core Minimal API
- Swashbuckle (Swagger/OpenAPI)
- Application Insights

### GreetingsFunction
- .NET 8 (isolated worker process)
- Azure Functions v4
- Timer Trigger
- HttpClient via IHttpClientFactory
- Application Insights

### Infrastructure
- Azure App Service (Linux)
- Azure Functions (Consumption or Premium plan)
- Azure Storage Account
- Application Insights
- Log Analytics Workspace

## 🧪 Testing in GitHub Codespaces

This repository is Codespaces-ready! 

1. Click "Code" → "Codespaces" → "Create codespace"
2. Wait for the environment to be ready
3. Run the application as described in the Quick Start section

All dependencies (.NET 8 SDK, Azure Functions Core Tools) are pre-configured.

## 📖 Learning Resources

- [Migration Guide](Migration/README.md) - Workshop steps
- [.NET 8 Documentation](https://docs.microsoft.com/en-us/dotnet/core/whats-new/dotnet-8)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)

## 🆘 Troubleshooting

See the [Local Testing Guide](docs/LOCAL_TESTING_GUIDE.md#troubleshooting) for common issues and solutions.

Common issues:
- **Port in use**: Use `dotnet run --urls "http://localhost:5001"`
- **Function tools not found**: Install via `npm install -g azure-functions-core-tools@4`
- **Storage emulator issues**: Use Azurite or Azure Storage Account

## 🎓 Workshop Information

This migration was completed as part of the **GitHub Copilot Migration Workshop**.

The workshop demonstrates:
- ✅ Using GitHub Copilot for modernization assessments
- ✅ Migrating legacy applications to cloud-native architectures
- ✅ Implementing Infrastructure as Code
- ✅ Following Azure best practices
- ✅ Creating comprehensive documentation
- ✅ Setting up automated CI/CD pipelines

## 📝 Next Steps

1. **Local Testing**: Follow [docs/LOCAL_TESTING_GUIDE.md](docs/LOCAL_TESTING_GUIDE.md)
2. **Set up CI/CD**: Follow [docs/CICD_SETUP.md](docs/CICD_SETUP.md) to enable automated deployments
3. **Deploy to Azure**: Use the CI/CD pipeline or follow [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)
4. **Review Architecture**: Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
5. **Enhance Security**: Add authentication, Key Vault, Managed Identity

## 🤝 Credits

This migration demonstrates modernizing a .NET Framework application using:
- Azure App Service for hosting REST APIs
- Azure Functions for scheduled tasks
- Application Insights for monitoring
- Infrastructure as Code with Bicep
- Modern .NET 8 development practices

---

**Status:** ✅ Migration Complete  
**Framework:** .NET 8  
**Target:** Azure (App Service + Functions)  
**Approach:** Recommended Option 1 from assessment
