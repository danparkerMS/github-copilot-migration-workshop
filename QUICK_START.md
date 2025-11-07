# Quick Start Guide - Migrated Application

This is a quick reference for getting started with the migrated application.

## 🚀 Run Locally (Quick Start)

### Prerequisites
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)

### Start the Application

**Terminal 1 - Start API:**
```bash
cd MessageServiceApi
dotnet run
```

**Terminal 2 - Start Function:**
```bash
cd GreetingsFunction
func start
```

### Test the Application

```bash
# Test API
curl http://localhost:5000/api/message

# View Swagger
open http://localhost:5000/swagger
```

## 📂 Project Structure

```
MessageServiceApi/          ← .NET 8 Minimal API
GreetingsFunction/         ← Azure Function (Timer)
Infrastructure/            ← Bicep templates
docs/                      ← Documentation
```

## 📚 Documentation

| Guide | Purpose | Link |
|-------|---------|------|
| **Overview** | What was migrated and why | [docs/README.md](docs/README.md) |
| **Local Testing** | Run and test locally | [docs/LOCAL_TESTING_GUIDE.md](docs/LOCAL_TESTING_GUIDE.md) |
| **Deployment** | Deploy to Azure | [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) |
| **Architecture** | Design decisions | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) |
| **Summary** | Migration details | [MIGRATION_SUMMARY.md](MIGRATION_SUMMARY.md) |

## 🌐 Deploy to Azure

```bash
cd Infrastructure
./deploy.sh rg-msgapp-dev eastus
```

Then follow the output instructions to deploy the applications.

## 🔍 Key Files

### MessageServiceApi
- `Program.cs` - API configuration and endpoints
- `Models/MessageResponse.cs` - Response model
- `appsettings.json` - Configuration

### GreetingsFunction
- `GreetingsTimerFunction.cs` - Main function code
- `Program.cs` - Function app configuration
- `local.settings.json.example` - Configuration template

### Infrastructure
- `main.bicep` - Azure resources template
- `deploy.sh` - Deployment automation

## ✅ API Endpoint

**GET /api/message**
```json
{
  "message": "2024-11-07 14:30:00 - Hello World",
  "timestamp": "2024-11-07T14:30:00.000Z"
}
```

## ⏱️ Function Schedule

- **Trigger:** Timer
- **Schedule:** `0 */1 * * * *` (every minute)
- **Action:** Calls `/api/message` endpoint

## 💰 Cost Estimate

**Azure (B1 tier):** ~$17-20/month
- App Service Plan: ~$13
- Function App: ~$1
- Storage: ~$1
- App Insights: ~$2-5

**Free tier (F1):** ~$0-5/month

## 🆘 Common Commands

```bash
# Build projects
cd MessageServiceApi && dotnet build
cd GreetingsFunction && dotnet build

# Run with different port
dotnet run --urls "http://localhost:5001"

# View Function logs
func start --verbose

# Clean build
dotnet clean && dotnet build
```

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| Port in use | `dotnet run --urls "http://localhost:5001"` |
| Function tools missing | `npm install -g azure-functions-core-tools@4` |
| Build errors | `dotnet clean && dotnet build` |

## 📊 Architecture

```
Azure Functions (Timer) ──► Azure App Service (API)
        │                           │
        └───────────────────────────┴──► Application Insights
```

## ✨ Key Features

- ✅ .NET 8 (cross-platform)
- ✅ Serverless scheduled task (every minute)
- ✅ Swagger/OpenAPI documentation
- ✅ Application Insights monitoring
- ✅ Infrastructure as Code (Bicep)
- ✅ Production-ready

## 📖 Next Steps

1. Run locally: Follow Quick Start above
2. Review architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
3. Deploy to Azure: [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)

---

**Migration Status:** ✅ Complete  
**Framework:** .NET 8  
**Platform:** Azure (App Service + Functions)
