# Migrated Application - Azure Functions + App Service

This directory contains the modernized version of the original .NET Framework 4.8.1 application, now running on .NET 8 with Azure App Service and Azure Functions.

## 🎯 Overview

The application has been successfully migrated from a legacy Windows-based architecture to a modern, cloud-native solution:

- **MessageService** → **MessageServiceApi** (Azure App Service)
- **GreetingsConsole** → **GreetingsFunction** (Azure Functions with Timer Trigger)

## 📁 Project Structure

```
.
├── MessageServiceApi/          # REST API (.NET 8 Minimal API)
│   ├── Models/                 # Data models
│   ├── Program.cs              # API configuration and endpoints
│   ├── appsettings.json        # Configuration
│   └── MessageServiceApi.csproj
│
├── GreetingsFunction/          # Azure Function (.NET 8)
│   ├── Models/                 # Data models
│   ├── GreetingsTimerFunction.cs  # Timer trigger function
│   ├── Program.cs              # Function app configuration
│   ├── host.json               # Function host configuration
│   ├── local.settings.json     # Local development settings
│   └── GreetingsFunction.csproj
│
├── Infrastructure/             # Infrastructure as Code (Bicep)
│   ├── main.bicep              # Azure resources template
│   ├── main.parameters.json    # Deployment parameters
│   └── deploy.sh               # Deployment script
│
└── docs/                       # Documentation
    ├── DEPLOYMENT_GUIDE.md     # How to deploy to Azure
    ├── LOCAL_TESTING_GUIDE.md  # How to test locally
    └── ARCHITECTURE.md         # Architecture documentation
```

## 🚀 Quick Start

### Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local) (for local function testing)

### Run Locally

#### 1. Start the API

```bash
cd MessageServiceApi
dotnet run
```

The API will be available at `http://localhost:5000`

#### 2. Start the Function (in a new terminal)

```bash
cd GreetingsFunction
func start
```

The function will execute every minute and call the API.

### Test the API

```bash
# Using curl
curl http://localhost:5000/api/message

# Using browser
open http://localhost:5000/swagger
```

## 📚 Documentation

- **[Local Testing Guide](docs/LOCAL_TESTING_GUIDE.md)** - Complete guide for running and testing locally
- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Step-by-step Azure deployment instructions
- **[Architecture Documentation](docs/ARCHITECTURE.md)** - Detailed architecture and design decisions

## 🏗️ Architecture

### High-Level Overview

```
┌─────────────────────────────────────────┐
│           Azure Cloud                    │
│                                         │
│  ┌──────────────────────────────┐      │
│  │  Azure Functions             │      │
│  │  (Timer: Every Minute)       │      │
│  │  GreetingsTimerFunction      │      │
│  └─────────────┬────────────────┘      │
│                │ HTTP GET               │
│                ▼                        │
│  ┌──────────────────────────────┐      │
│  │  Azure App Service           │      │
│  │  MessageServiceApi           │      │
│  │  GET /api/message            │      │
│  └──────────────────────────────┘      │
│                                         │
│  ┌──────────────────────────────┐      │
│  │  Application Insights        │      │
│  │  (Monitoring & Logging)      │      │
│  └──────────────────────────────┘      │
└─────────────────────────────────────────┘
```

### Components

| Component | Technology | Purpose |
|-----------|------------|---------|
| **MessageServiceApi** | .NET 8 Minimal API | REST API that returns timestamped messages |
| **GreetingsFunction** | Azure Functions v4 | Timer-triggered function (runs every minute) |
| **Timer Trigger** | CRON: `0 */1 * * * *` | Executes function every minute |
| **Application Insights** | Azure Monitor | Centralized logging and monitoring |
| **Storage Account** | Azure Storage | Required for Function App runtime |

## ✨ Key Features

### MessageServiceApi

- ✅ Modern .NET 8 Minimal API
- ✅ Cross-platform (runs on Linux)
- ✅ Swagger/OpenAPI documentation at `/swagger`
- ✅ CORS enabled for Azure Functions
- ✅ Application Insights integration
- ✅ High performance and low resource usage

### GreetingsFunction

- ✅ Serverless Azure Function
- ✅ Timer trigger (runs every minute)
- ✅ Automatic retry and error handling
- ✅ Application Insights logging
- ✅ Isolated worker process model
- ✅ Dependency injection support

## 🔧 Configuration

### MessageServiceApi

Configuration in `appsettings.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "Urls": "http://localhost:5000"
}
```

### GreetingsFunction

Configuration in `local.settings.json`:

```json
{
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "MESSAGE_SERVICE_URL": "http://localhost:5000"
  }
}
```

## 🧪 Testing

### Test the API Endpoint

```bash
# Test the message endpoint
curl http://localhost:5000/api/message

# Expected response:
# {
#   "message": "2024-11-07 14:30:00 - Hello World",
#   "timestamp": "2024-11-07T14:30:00.000Z"
# }
```

### Verify Function Execution

Watch the function logs to see it execute every minute:

```bash
cd GreetingsFunction
func start --verbose
```

Expected output:
```
[2024-11-07T14:30:00.001Z] === GreetingsFunction Timer Trigger Started ===
[2024-11-07T14:30:00.002Z] Calling MessageService API at: http://localhost:5000/api/message
[2024-11-07T14:30:00.150Z] === Response Received ===
[2024-11-07T14:30:00.151Z] Message: 2024-11-07 14:30:00 - Hello World
[2024-11-07T14:30:00.153Z] === GreetingsFunction Timer Trigger Completed ===
```

## 🌐 Deploying to Azure

### Quick Deployment

```bash
# Deploy infrastructure and applications
cd Infrastructure
./deploy.sh [RESOURCE_GROUP] [LOCATION]
```

For detailed deployment instructions, see the [Deployment Guide](docs/DEPLOYMENT_GUIDE.md).

### Prerequisites for Deployment

- Azure CLI installed and configured
- Azure subscription with appropriate permissions
- Resource group in Azure

## 📊 Monitoring

### Application Insights

Both the API and Function send telemetry to Application Insights:

- Request/response logs
- Performance metrics
- Error tracking
- Custom events
- Distributed tracing

### Viewing Logs

#### During Local Development

```bash
# API logs
cd MessageServiceApi
dotnet run

# Function logs
cd GreetingsFunction
func start --verbose
```

#### In Azure

```bash
# Stream API logs
az webapp log tail --name <app-service-name> --resource-group <rg-name>

# Stream Function logs
az webapp log tail --name <function-app-name> --resource-group <rg-name>
```

## 🔍 Troubleshooting

### Common Issues

**Port Already in Use**
```bash
# Use a different port
dotnet run --urls "http://localhost:5001"
```

**Function Not Calling API**
- Ensure MessageServiceApi is running
- Check `local.settings.json` has correct `MESSAGE_SERVICE_URL`
- Verify CORS is enabled in the API

**Azure Functions Core Tools Not Found**
```bash
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

For more troubleshooting tips, see the [Local Testing Guide](docs/LOCAL_TESTING_GUIDE.md).

## 📈 Performance

### API Performance

- **Startup Time**: < 2 seconds
- **Response Time**: < 50ms (typical)
- **Memory Usage**: ~50-100 MB
- **Platform**: Cross-platform (Linux, Windows, macOS)

### Function Performance

- **Cold Start**: < 5 seconds
- **Execution Time**: < 1 second (typical)
- **Frequency**: Every 60 seconds
- **Scale**: Automatic (consumption plan)

## 💰 Cost Estimation

### Azure Resources (Monthly)

| Resource | Tier | Estimated Cost |
|----------|------|----------------|
| App Service Plan | B1 (Basic) | ~$13 |
| Function App | Consumption | ~$1 |
| Storage Account | Standard LRS | ~$1 |
| Application Insights | Pay-as-you-go | ~$2-5 |
| **Total** | | **~$17-20** |

For development/testing, you can use the Free (F1) tier, reducing cost to near zero.

## 🎓 Learning Resources

- [.NET 8 Documentation](https://docs.microsoft.com/en-us/dotnet/core/whats-new/dotnet-8)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [ASP.NET Core Minimal APIs](https://docs.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)

## 🤝 Contributing

This is a sample migration project for educational purposes. Feel free to use it as a reference for your own migrations.

## 📝 License

This project is provided as-is for educational purposes.

## 🆘 Support

For issues and questions:
- Review the [Troubleshooting](docs/LOCAL_TESTING_GUIDE.md#troubleshooting) section
- Check the [Architecture Documentation](docs/ARCHITECTURE.md)
- Refer to the [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)

## ✅ Migration Checklist

- [x] MessageService migrated to .NET 8 Minimal API
- [x] GreetingsConsole migrated to Azure Functions
- [x] Timer trigger configured (every minute)
- [x] Application Insights integrated
- [x] Infrastructure as Code (Bicep) templates created
- [x] Deployment scripts provided
- [x] Local testing validated
- [x] Documentation complete
- [x] CORS configured
- [x] Swagger/OpenAPI documentation added

## 🎉 Success Criteria Met

✅ API returns the same timestamped greeting messages  
✅ Scheduled task runs every minute and calls the API  
✅ Application can be tested locally (in Codespaces)  
✅ Clear deployment instructions provided  
✅ All code follows modern best practices  
✅ Cost-optimized implementation  
✅ Cloud-native architecture
