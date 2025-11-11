# Local Testing Guide

This guide explains how to run and test the migrated application locally, both on your development machine and in GitHub Codespaces.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Running MessageService API](#running-messageservice-api)
- [Running GreetingsFunction](#running-greetingsfunction)
- [Testing in GitHub Codespaces](#testing-in-github-codespaces)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

1. **.NET 8 SDK**
   - Download: https://dotnet.microsoft.com/download/dotnet/8.0
   - Verify: `dotnet --version` (should show 8.0.x)

2. **Azure Functions Core Tools** (for running functions locally)
   - Install: https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local
   - Verify: `func --version`
   - Or install via npm: `npm install -g azure-functions-core-tools@4 --unsafe-perm true`

3. **Git**
   - Download: https://git-scm.com/downloads
   - Verify: `git --version`

### Optional but Recommended

- **Visual Studio Code** with extensions:
  - C# Dev Kit
  - Azure Functions
  - REST Client
- **Postman** or **curl** for testing the API

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/github-copilot-migration-workshop.git
cd github-copilot-migration-workshop
```

### 2. Run Both Applications

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

The API will be available at `http://localhost:5000` and the function will start executing every minute.

## Running MessageService API

### Build the API

```bash
cd MessageServiceApi
dotnet build
```

### Run the API

```bash
dotnet run
```

Or with specific URL:
```bash
dotnet run --urls "http://localhost:5000"
```

### Test the API

#### Using curl

```bash
# Test the message endpoint
curl http://localhost:5000/api/message

# Expected response:
# {
#   "message": "2024-11-07 14:30:00 - Hello World",
#   "timestamp": "2024-11-07T14:30:00.000Z"
# }
```

#### Using PowerShell

```powershell
Invoke-RestMethod -Uri http://localhost:5000/api/message
```

#### Using Browser

1. Navigate to `http://localhost:5000/swagger`
2. Click on `/api/message` endpoint
3. Click "Try it out"
4. Click "Execute"

### Available Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/message` | GET | Returns a timestamped greeting message |
| `/swagger` | GET | Interactive API documentation |

### Configuration

The API configuration is in `appsettings.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Urls": "http://localhost:5000"
}
```

To change the port, modify the `Urls` setting or use the `--urls` parameter.

## Running GreetingsFunction

### Install Dependencies

```bash
cd GreetingsFunction
dotnet restore
```

### Build the Function

```bash
dotnet build
```

### Configure Local Settings

The function uses `local.settings.json` for configuration:

```json
{
    "IsEncrypted": false,
    "Values": {
        "AzureWebJobsStorage": "UseDevelopmentStorage=true",
        "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
        "MESSAGE_SERVICE_URL": "http://localhost:5000"
    }
}
```

**Important Notes:**
- `AzureWebJobsStorage` is set to `UseDevelopmentStorage=true` which uses the Azure Storage Emulator
- For local development without the emulator, you can use: `"UseDevelopmentStorage=false"`
- `MESSAGE_SERVICE_URL` should point to your running MessageService API

### Run the Function

```bash
func start
```

Or with additional logging:
```bash
func start --verbose
```

### Expected Output

When the function starts, you should see:

```
Azure Functions Core Tools
Core Tools Version:       4.x.x
Function Runtime Version: 4.x.x

Functions:

        GreetingsTimerFunction: timerTrigger

For detailed output, run func with --verbose flag.
[2024-11-07T14:30:00.000Z] Executing 'GreetingsTimerFunction' (Reason='Timer fired at 2024-11-07T14:30:00.0000000+00:00', Id=...)
[2024-11-07T14:30:00.001Z] === GreetingsFunction Timer Trigger Started ===
[2024-11-07T14:30:00.002Z] Calling MessageService API at: http://localhost:5000/api/message
[2024-11-07T14:30:00.150Z] === Response Received ===
[2024-11-07T14:30:00.151Z] Message: 2024-11-07 14:30:00 - Hello World
[2024-11-07T14:30:00.152Z] Timestamp: 2024-11-07 14:30:00
[2024-11-07T14:30:00.153Z] === GreetingsFunction Timer Trigger Completed ===
```

### Timer Schedule

The function runs every minute based on the CRON expression: `0 */1 * * * *`

CRON format: `{second} {minute} {hour} {day} {month} {day-of-week}`
- `0` = at second 0
- `*/1` = every 1 minute
- `* * * *` = every hour, every day, every month, every day of week

### Manually Trigger the Function

While the function is configured as a timer trigger, you can test it immediately by:

1. **Stopping and restarting** the function (it will execute once on startup)
2. **Waiting for the next minute** (timer triggers automatically)

Note: Timer triggers cannot be invoked via HTTP in the local development environment.

## Testing in GitHub Codespaces

GitHub Codespaces provides a cloud-based development environment with all tools pre-installed.

### Open in Codespaces

1. Navigate to the repository on GitHub
2. Click the green "Code" button
3. Select "Codespaces" tab
4. Click "Create codespace on main"

### Running the Application

Once the Codespace is ready:

#### Terminal 1 - Start the API

```bash
cd MessageServiceApi
dotnet run --urls "http://localhost:5000"
```

#### Terminal 2 - Start the Function

```bash
cd GreetingsFunction
func start
```

### Port Forwarding

Codespaces automatically forwards ports. When the API starts:

1. A notification will appear showing the forwarded port
2. Click "Open in Browser" to access the API
3. Or use the "Ports" panel to manage forwarded ports

### Testing in Codespaces

```bash
# Test the API
curl http://localhost:5000/api/message

# View logs
# The function logs will appear in Terminal 2 every minute
```

### Advantages of Codespaces

- ✅ No local installation required
- ✅ Consistent development environment
- ✅ Access from any device with a browser
- ✅ Pre-configured with .NET 8 SDK
- ✅ Easy to share with team members

## Integration Testing

### Test Complete Workflow

1. **Start the API** (Terminal 1):
   ```bash
   cd MessageServiceApi
   dotnet run
   ```

2. **Test the API is responding** (Terminal 3):
   ```bash
   curl http://localhost:5000/api/message
   ```

3. **Start the Function** (Terminal 2):
   ```bash
   cd GreetingsFunction
   func start
   ```

4. **Monitor the logs** in Terminal 2
   - Every minute, you should see the function execute
   - It calls the API at `http://localhost:5000/api/message`
   - Logs show the received message and timestamp

### Expected Flow

```
[Minute 1]
Function: === GreetingsFunction Timer Trigger Started ===
Function: Calling MessageService API at: http://localhost:5000/api/message
API: GET /api/message - 200 OK
Function: === Response Received ===
Function: Message: 2024-11-07 14:31:00 - Hello World
Function: === GreetingsFunction Timer Trigger Completed ===

[Minute 2]
Function: === GreetingsFunction Timer Trigger Started ===
...
```

## Troubleshooting

### API Issues

#### Port Already in Use

**Error:** `Failed to bind to address http://localhost:5000: address already in use`

**Solution:**
```bash
# Option 1: Use a different port
dotnet run --urls "http://localhost:5001"

# Option 2: Find and kill the process using the port
# On Windows:
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# On Linux/Mac:
lsof -i :5000
kill -9 <PID>
```

#### Build Errors

**Error:** `The framework 'Microsoft.NETCore.App', version '8.0.0' was not found`

**Solution:** Install .NET 8 SDK from https://dotnet.microsoft.com/download/dotnet/8.0

### Function Issues

#### Azure Functions Core Tools Not Found

**Error:** `func: command not found`

**Solution:**
```bash
# Install via npm
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Or download installer from:
# https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local
```

#### Storage Emulator Issues

**Error:** `No connection could be made because the target machine actively refused it`

**Solutions:**

1. **Option 1: Use an Azure Storage Account**
   - Create a storage account in Azure
   - Update `local.settings.json`:
     ```json
     "AzureWebJobsStorage": "DefaultEndpointsProtocol=https;AccountName=<name>;AccountKey=<key>;EndpointSuffix=core.windows.net"
     ```

2. **Option 2: Use Azurite (Local Storage Emulator)**
   ```bash
   # Install Azurite
   npm install -g azurite
   
   # Start Azurite
   azurite --silent --location ./azurite --debug ./azurite/debug.log
   ```

3. **Option 3: Disable storage requirement** (for timer triggers):
   - Update `local.settings.json`:
     ```json
     "AzureWebJobsStorage": ""
     ```
   - Note: This may limit some functionality

#### Function Not Calling API

**Error:** Function runs but shows connection error to MessageService

**Check:**
1. Verify MessageService API is running: `curl http://localhost:5000/api/message`
2. Check `local.settings.json` has correct URL:
   ```json
   "MESSAGE_SERVICE_URL": "http://localhost:5000"
   ```
3. Restart the function after changing settings

### General Issues

#### Dependencies Not Restored

```bash
# Restore packages for both projects
cd MessageServiceApi && dotnet restore
cd ../GreetingsFunction && dotnet restore
```

#### Clean Build

If you encounter strange errors:

```bash
# Clean and rebuild
cd MessageServiceApi
dotnet clean
dotnet build

cd ../GreetingsFunction
dotnet clean
dotnet build
```

## Performance Testing

### Load Testing the API

```bash
# Using Apache Bench (if installed)
ab -n 1000 -c 10 http://localhost:5000/api/message

# Using curl in a loop
for i in {1..100}; do
  curl http://localhost:5000/api/message
done
```

### Monitor Function Execution

```bash
# Watch the function logs in real-time
cd GreetingsFunction
func start --verbose

# You'll see detailed execution logs every minute
```

## Next Steps

- Review [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for deploying to Azure
- Review [ARCHITECTURE.md](./ARCHITECTURE.md) for understanding the system design
- Set up automated tests for the API and Function
- Configure Application Insights for local development monitoring

## Additional Resources

- [.NET 8 Documentation](https://docs.microsoft.com/en-us/dotnet/core/whats-new/dotnet-8)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [ASP.NET Core Documentation](https://docs.microsoft.com/en-us/aspnet/core/)
