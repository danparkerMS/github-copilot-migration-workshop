# Architecture Documentation

## Overview

This document describes the architecture of the migrated application, which has been modernized from a legacy .NET Framework 4.8.1 application to a cloud-native solution using .NET 8, Azure App Service, and Azure Functions.

## Table of Contents
- [Migration Summary](#migration-summary)
- [Architecture Diagram](#architecture-diagram)
- [Components](#components)
- [Design Decisions](#design-decisions)
- [Data Flow](#data-flow)
- [Comparison with Original Application](#comparison-with-original-application)

## Migration Summary

### From (Legacy)
- **MessageService**: ASP.NET Web API 2 on .NET Framework 4.8.1
- **GreetingsConsole**: Console application scheduled via Windows Task Scheduler
- **Hosting**: IIS on Windows Server
- **Platform**: Windows-only

### To (Modern)
- **MessageService API**: ASP.NET Core Minimal API on .NET 8
- **GreetingsFunction**: Azure Function with Timer Trigger
- **Hosting**: Azure App Service (Linux) and Azure Functions
- **Platform**: Cross-platform (Linux, Windows, macOS)

## Architecture Diagram

### High-Level Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                         Azure Cloud                                 │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  Azure Functions App (Consumption/Premium Plan)           │     │
│  │  ┌─────────────────────────────────────────────────────┐ │     │
│  │  │  GreetingsTimerFunction                             │ │     │
│  │  │                                                      │ │     │
│  │  │  • Timer Trigger: "0 */1 * * * *" (every minute)    │ │     │
│  │  │  • Runtime: .NET 8 (isolated worker process)        │ │     │
│  │  │  • Calls MessageService API via HttpClient          │ │     │
│  │  │  • Logs to Application Insights                     │ │     │
│  │  └─────────────────────────────────────────────────────┘ │     │
│  └────────────────┬─────────────────────────────────────────┘     │
│                   │                                                │
│                   │ HTTPS GET Request                              │
│                   │ https://{api-url}/api/message                  │
│                   │                                                │
│                   ▼                                                │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  Azure App Service (Linux, B1 SKU)                       │     │
│  │  ┌─────────────────────────────────────────────────────┐ │     │
│  │  │  MessageServiceApi                                   │ │     │
│  │  │                                                      │ │     │
│  │  │  • Framework: .NET 8                                │ │     │
│  │  │  • Pattern: Minimal API                             │ │     │
│  │  │  • Endpoint: GET /api/message                       │ │     │
│  │  │  • Response: JSON (message + timestamp)             │ │     │
│  │  │  • Documentation: Swagger/OpenAPI at /swagger       │ │     │
│  │  │  • Logs to Application Insights                     │ │     │
│  │  └─────────────────────────────────────────────────────┘ │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  Application Insights                                     │     │
│  │  • Collects telemetry from both API and Function         │     │
│  │  • Provides distributed tracing                           │     │
│  │  • Monitors performance and errors                        │     │
│  │  • Stores data in Log Analytics Workspace                 │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  Azure Storage Account                                    │     │
│  │  • Stores Function App state and metadata                 │     │
│  │  • Required for Azure Functions runtime                   │     │
│  │  • Standard_LRS (locally redundant storage)               │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │  App Service Plan (Linux)                                 │     │
│  │  • SKU: B1 (Basic) - 1 Core, 1.75 GB RAM                 │     │
│  │  • Hosts both App Service and Function App                │     │
│  │  • Can scale up/out as needed                             │     │
│  └──────────────────────────────────────────────────────────┘     │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

### Request Flow Diagram

```
┌─────────────────┐
│  Timer Trigger  │
│   (Every 1 min) │
└────────┬────────┘
         │
         │ Triggers
         ▼
┌─────────────────────────────────┐
│  GreetingsTimerFunction         │
│  - Reads MESSAGE_SERVICE_URL    │
│  - Creates HttpClient request   │
└────────┬────────────────────────┘
         │
         │ HTTP GET /api/message
         │ Headers: Accept: application/json
         ▼
┌─────────────────────────────────┐
│  MessageServiceApi              │
│  - Receives request             │
│  - Generates timestamp          │
│  - Creates message              │
└────────┬────────────────────────┘
         │
         │ Returns JSON
         │ {
         │   "message": "2024-11-07 14:30:00 - Hello World",
         │   "timestamp": "2024-11-07T14:30:00.000Z"
         │ }
         ▼
┌─────────────────────────────────┐
│  GreetingsTimerFunction         │
│  - Deserializes response        │
│  - Logs message to App Insights │
│  - Completes execution          │
└─────────────────────────────────┘
         │
         │ Sends telemetry
         ▼
┌─────────────────────────────────┐
│  Application Insights           │
│  - Stores logs                  │
│  - Enables monitoring/alerting  │
└─────────────────────────────────┘
```

## Components

### 1. MessageServiceApi (Azure App Service)

**Technology Stack:**
- **.NET 8** - Latest LTS version
- **ASP.NET Core Minimal API** - Lightweight, high-performance
- **Swagger/OpenAPI** - API documentation and testing

**Endpoints:**

| Endpoint | Method | Description | Response |
|----------|--------|-------------|----------|
| `/api/message` | GET | Returns timestamped greeting | `MessageResponse` JSON |
| `/swagger` | GET | Interactive API documentation | Swagger UI |

**Key Features:**
- ✅ Cross-platform (runs on Linux)
- ✅ High performance with minimal overhead
- ✅ Built-in dependency injection
- ✅ Integrated logging and monitoring
- ✅ CORS enabled for Function App access
- ✅ Application Insights integration

**Configuration:**
- Port: Configured via Azure (not fixed to 5000)
- Logging: Structured logging to Application Insights
- Environment: Production/Development modes

### 2. GreetingsFunction (Azure Functions)

**Technology Stack:**
- **.NET 8** - Isolated worker process model
- **Azure Functions v4** - Latest runtime
- **Timer Trigger** - CRON-based scheduling

**Trigger Configuration:**
```csharp
[TimerTrigger("0 */1 * * * *")]
// Format: {second} {minute} {hour} {day} {month} {day-of-week}
// "0 */1 * * * *" = at second 0 of every minute
```

**Key Features:**
- ✅ Serverless execution (pay per execution)
- ✅ Automatic scaling
- ✅ Isolated worker process (better performance, isolation)
- ✅ Built-in retry policies
- ✅ Application Insights integration
- ✅ Managed identity support (for future enhancements)

**Dependencies:**
- `HttpClient` via `IHttpClientFactory` (best practice)
- Application Insights for logging
- Azure Storage for function state

### 3. Application Insights

**Purpose:** Centralized monitoring and logging for both components

**Collected Data:**
- Request/response logs
- Performance metrics
- Error tracking
- Custom events and traces
- Distributed tracing

**Features:**
- Live Metrics streaming
- Log Analytics queries
- Alerting and notifications
- Performance analysis
- Dependency tracking

### 4. Supporting Resources

**Azure Storage Account:**
- Required for Azure Functions runtime
- Stores function execution state
- Stores configuration and metadata

**Log Analytics Workspace:**
- Backend for Application Insights
- Stores telemetry data
- Enables advanced queries

**App Service Plan:**
- Hosts both App Service and Function App
- Linux-based for cost efficiency
- Scalable (manual or auto-scale)

## Design Decisions

### 1. Why Minimal API instead of Controller-based API?

**Chosen:** Minimal API

**Reasons:**
- ✅ Simpler codebase for small APIs
- ✅ Better performance (reduced overhead)
- ✅ Modern .NET pattern
- ✅ Less boilerplate code
- ✅ Easier to understand and maintain

### 2. Why Azure Functions instead of Container-based solution?

**Chosen:** Azure Functions with Timer Trigger

**Reasons:**
- ✅ Serverless = lower cost (pay per execution)
- ✅ Built-in scheduling (no external scheduler needed)
- ✅ Automatic scaling
- ✅ Managed infrastructure
- ✅ Perfect fit for scheduled tasks
- ✅ Simpler than managing containers

**Comparison:**

| Factor | Azure Functions | Container (ACI/AKS) |
|--------|----------------|---------------------|
| Cost | Lower (execution-based) | Higher (always running) |
| Complexity | Low | Medium to High |
| Scheduling | Built-in | External (CRON jobs) |
| Scaling | Automatic | Manual or complex |
| Best for | Event-driven tasks | Long-running processes |

### 3. Why Linux App Service Plan?

**Chosen:** Linux-based App Service Plan

**Reasons:**
- ✅ Lower cost than Windows
- ✅ .NET 8 runs natively on Linux
- ✅ Better performance for .NET Core/.NET 5+
- ✅ Aligns with modern cloud-native practices
- ✅ Smaller resource footprint

### 4. Why Shared App Service Plan?

**Chosen:** Single App Service Plan for both API and Function

**Reasons:**
- ✅ Cost optimization (one plan for both)
- ✅ Simpler resource management
- ✅ Adequate for the workload
- ✅ Can be split later if needed

**When to separate:**
- High traffic requiring independent scaling
- Different availability requirements
- Budget allows dedicated plans

### 5. Why Application Insights?

**Chosen:** Application Insights for monitoring

**Reasons:**
- ✅ Native Azure integration
- ✅ Distributed tracing across components
- ✅ Rich query language (Kusto/KQL)
- ✅ Alerts and notifications
- ✅ Low configuration overhead

## Data Flow

### Scheduled Execution Flow

1. **Timer Triggers** (every minute at :00 seconds)
   - Azure Functions runtime invokes GreetingsTimerFunction
   - Function receives `TimerInfo` with schedule metadata

2. **Function Reads Configuration**
   - Retrieves `MESSAGE_SERVICE_URL` from environment variables
   - Creates HttpClient instance via IHttpClientFactory

3. **Function Calls API**
   - Sends HTTP GET request to `/api/message`
   - Includes standard HTTP headers

4. **API Processes Request**
   - Generates current timestamp
   - Formats message string
   - Creates `MessageResponse` object
   - Serializes to JSON

5. **API Returns Response**
   - Returns 200 OK with JSON body
   - Includes timestamp in response

6. **Function Processes Response**
   - Deserializes JSON to `MessageResponse`
   - Logs message and timestamp
   - Sends telemetry to Application Insights

7. **Monitoring**
   - Application Insights collects telemetry
   - Logs available for querying
   - Metrics available for dashboards

### Error Handling Flow

```
Function Execution
       │
       ├─► Try to call API
       │   │
       │   ├─► Success → Log response → Complete
       │   │
       │   ├─► HttpRequestException
       │   │   └─► Log error → Complete (don't fail)
       │   │
       │   └─► General Exception
       │       └─► Log error → Complete (don't fail)
       │
       └─► Function completes
           Timer schedules next execution
```

## Comparison with Original Application

### Architecture Comparison

| Aspect | Original | Migrated |
|--------|----------|----------|
| **MessageService** | ASP.NET Web API 2 | ASP.NET Core Minimal API |
| **Framework** | .NET Framework 4.8.1 | .NET 8 |
| **Platform** | Windows Only | Cross-platform |
| **Hosting** | IIS | Azure App Service |
| **GreetingsConsole** | Console App | Azure Function (Timer) |
| **Scheduling** | Windows Task Scheduler | Built-in Timer Trigger |
| **Monitoring** | Limited | Application Insights |
| **Scalability** | Manual | Automatic |
| **Cost Model** | Fixed (VMs) | Consumption-based |

### Code Changes

#### MessageService API

**Original (Controller-based):**
```csharp
public class MessageController : ApiController
{
    [HttpGet]
    [Route("api/message")]
    public IHttpActionResult GetMessage()
    {
        var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        var message = $"{timestamp} - Hello World";
        var response = new MessageResponse
        {
            Message = message,
            Timestamp = DateTime.Now
        };
        return Ok(response);
    }
}
```

**Migrated (Minimal API):**
```csharp
app.MapGet("/api/message", () =>
{
    var timestamp = DateTime.Now;
    var message = $"{timestamp:yyyy-MM-dd HH:mm:ss} - Hello World";
    var response = new MessageResponse
    {
        Message = message,
        Timestamp = timestamp
    };
    return Results.Ok(response);
})
.WithName("GetMessage")
.WithOpenApi();
```

**Key Differences:**
- ✅ Less boilerplate code
- ✅ Inline endpoint definition
- ✅ Better performance
- ✅ Built-in OpenAPI support

#### Scheduled Task

**Original (Console App):**
```csharp
static void Main(string[] args)
{
    // Runs once per execution
    // Scheduled by Windows Task Scheduler
    var response = await httpClient.GetAsync("/api/message");
    // Process response
}
```

**Migrated (Azure Function):**
```csharp
[Function("GreetingsTimerFunction")]
public async Task Run([TimerTrigger("0 */1 * * * *")] TimerInfo myTimer)
{
    // Runs automatically every minute
    // Scheduled by Azure Functions runtime
    var response = await _httpClient.GetAsync($"{apiUrl}/api/message");
    // Process response
}
```

**Key Differences:**
- ✅ Built-in scheduling (no external scheduler)
- ✅ Automatic retry on failure
- ✅ Dependency injection support
- ✅ Better logging and monitoring
- ✅ Serverless execution model

### Benefits of Migration

#### Technical Benefits
- ✅ Cross-platform support
- ✅ Modern, maintainable codebase
- ✅ Better performance
- ✅ Cloud-native features
- ✅ Automatic scaling
- ✅ Built-in monitoring

#### Operational Benefits
- ✅ Reduced infrastructure management
- ✅ Lower operational costs
- ✅ Easier deployment
- ✅ Better observability
- ✅ Automated scheduling
- ✅ High availability

#### Development Benefits
- ✅ Simpler code structure
- ✅ Better development experience
- ✅ Local testing support
- ✅ Modern tooling
- ✅ Active framework support

## Security Considerations

### Current Implementation

1. **HTTPS Only** - All Azure services use HTTPS
2. **Managed Identities** - Ready for implementation
3. **Key Vault** - Can be integrated for secrets
4. **Application Insights** - No PII in logs

### Future Enhancements

- Implement Managed Identity for Function → API communication
- Add API authentication (API keys, Azure AD)
- Enable Azure Key Vault for secrets
- Implement rate limiting
- Add request validation

## Scalability

### Current Capacity

- **API**: Can handle moderate load on B1 tier
- **Function**: Scales automatically based on timer schedule

### Scaling Options

1. **Vertical Scaling**
   - Upgrade App Service Plan SKU (B1 → S1 → P1v2)
   
2. **Horizontal Scaling**
   - Enable auto-scale based on metrics
   - Add more instances to handle load

3. **Function Scaling**
   - Automatically handled by Azure
   - Consumption plan scales to zero when idle

## Cost Estimation

### Monthly Cost (B1 Tier)

| Resource | Cost (USD/month) |
|----------|------------------|
| App Service Plan (B1) | ~$13 |
| Storage Account | ~$1 |
| Application Insights | ~$2-5 |
| Function Execution | <$1 (low volume) |
| **Total** | **~$17-20/month** |

### Cost Optimization

- Use F1 (Free) tier for development/testing
- Scale down during non-business hours
- Monitor and optimize Application Insights data retention
- Use Consumption plan for Functions if appropriate

## Next Steps

- Implement authentication and authorization
- Add health check endpoints
- Set up CI/CD pipelines
- Configure custom domains and SSL
- Implement caching strategies
- Add comprehensive error handling
- Set up alerts and monitoring dashboards
