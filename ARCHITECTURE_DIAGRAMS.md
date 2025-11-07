# Architecture Diagrams - Azure Modernization

This document provides detailed architecture diagrams for each modernization option.

## Current Architecture (Before Migration)

```
┌─────────────────────────────────────────────────────────────┐
│              On-Premises / Windows Server                    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  Windows Task Scheduler                             │    │
│  │  ┌──────────────────────────────────────────────┐  │    │
│  │  │  GreetingsConsole.exe                        │  │    │
│  │  │  - .NET Framework 4.8.1                      │  │    │
│  │  │  - Runs every minute                         │  │    │
│  │  │  - Scheduled Task                            │  │    │
│  │  └──────────────────────────────────────────────┘  │    │
│  └────────────────┬───────────────────────────────────┘    │
│                   │ HTTP GET                                │
│                   │ http://localhost:5000/api/message       │
│                   ▼                                         │
│  ┌────────────────────────────────────────────────────┐    │
│  │  IIS Web Server                                     │    │
│  │  ┌──────────────────────────────────────────────┐  │    │
│  │  │  MessageService                               │  │    │
│  │  │  - ASP.NET Web API 2                          │  │    │
│  │  │  - .NET Framework 4.8.1                       │  │    │
│  │  │  - Port 5000                                  │  │    │
│  │  └──────────────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  Limitations:                                                │
│  ❌ Windows-only (Server licensing costs)                  │
│  ❌ Manual scaling                                         │
│  ❌ Manual patching and updates                            │
│  ❌ No cloud monitoring                                    │
│  ❌ Single point of failure                                │
│  ❌ High operational overhead                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Option 1: Azure Functions + App Service (RECOMMENDED) ⭐

### High-Level Architecture

```
                    ┌─────────────────────────────────────────┐
                    │         Internet / Users                │
                    └──────────────┬──────────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────────┐
                    │     Azure Front Door (Optional)         │
                    │     - SSL/TLS termination               │
                    │     - CDN caching                       │
                    │     - DDoS protection                   │
                    └──────────────┬──────────────────────────┘
                                   │
    ┌──────────────────────────────┴──────────────────────────────────────────┐
    │                            Azure Cloud                                   │
    │                                                                          │
    │  ┌───────────────────────────────────────────────────────────────┐     │
    │  │  Azure Functions (Consumption Plan)                            │     │
    │  │  ┌────────────────────────────────────────────────────────┐   │     │
    │  │  │  GreetingsFunction                                      │   │     │
    │  │  │  ┌──────────────────────────────────────────────────┐  │   │     │
    │  │  │  │  Timer Trigger                                    │  │   │     │
    │  │  │  │  Schedule: "0 */1 * * * *"                       │  │   │     │
    │  │  │  │  (Every minute)                                   │  │   │     │
    │  │  │  └──────────────────────────────────────────────────┘  │   │     │
    │  │  │                                                          │   │     │
    │  │  │  Function Logic:                                         │   │     │
    │  │  │  1. Triggered by timer every minute                     │   │     │
    │  │  │  2. HTTP GET to MessageService API                      │   │     │
    │  │  │  3. Parse JSON response                                 │   │     │
    │  │  │  4. Log message to Application Insights                 │   │     │
    │  │  │  5. Handle errors with retry logic                      │   │     │
    │  │  └──────────────────────────────────────────────────────┘   │     │
    │  └───────────────────┬───────────────────────────────────────────┘     │
    │                      │ HTTPS GET                                        │
    │                      │ /api/message                                     │
    │                      ▼                                                  │
    │  ┌───────────────────────────────────────────────────────────────┐     │
    │  │  Azure App Service (B1 or F1 tier)                             │     │
    │  │  ┌────────────────────────────────────────────────────────┐   │     │
    │  │  │  MessageService Web API                                 │   │     │
    │  │  │  ┌──────────────────────────────────────────────────┐  │   │     │
    │  │  │  │  .NET 8 Minimal API                               │  │   │     │
    │  │  │  │                                                    │  │   │     │
    │  │  │  │  Endpoints:                                        │  │   │     │
    │  │  │  │  • GET /api/message                               │  │   │     │
    │  │  │  │    Returns: {                                     │  │   │     │
    │  │  │  │      "message": "timestamp - Hello World",        │  │   │     │
    │  │  │  │      "timestamp": "2025-11-05T19:37:21.672Z"     │  │   │     │
    │  │  │  │    }                                              │  │   │     │
    │  │  │  │                                                    │  │   │     │
    │  │  │  │  • GET /swagger (API documentation)               │  │   │     │
    │  │  │  │  • GET /health (health check)                     │  │   │     │
    │  │  │  └──────────────────────────────────────────────────┘  │   │     │
    │  │  └────────────────────────────────────────────────────────┘   │     │
    │  │                                                                 │     │
    │  │  Features:                                                      │     │
    │  │  ✅ Auto-scaling (1-N instances)                               │     │
    │  │  ✅ Deployment slots (staging/production)                      │     │
    │  │  ✅ SSL/TLS certificates (free)                                │     │
    │  │  ✅ Custom domains                                             │     │
    │  │  ✅ Built-in authentication                                    │     │
    │  └───────────────────────────────────────────────────────────────┘     │
    │                                                                          │
    │  ┌───────────────────────────────────────────────────────────────┐     │
    │  │  Application Insights                                          │     │
    │  │  ┌────────────────────────────────────────────────────────┐   │     │
    │  │  │  Telemetry & Monitoring                                 │   │     │
    │  │  │  • Application logs                                     │   │     │
    │  │  │  • Performance metrics                                  │   │     │
    │  │  │  • Dependency tracking                                  │   │     │
    │  │  │  • Failed request analysis                              │   │     │
    │  │  │  • Live metrics stream                                  │   │     │
    │  │  │  • Custom dashboards                                    │   │     │
    │  │  │  • Alerting rules                                       │   │     │
    │  │  └────────────────────────────────────────────────────────┘   │     │
    │  └───────────────────────────────────────────────────────────────┘     │
    │                                                                          │
    │  ┌───────────────────────────────────────────────────────────────┐     │
    │  │  Azure Key Vault (Optional)                                    │     │
    │  │  • API keys and secrets                                        │     │
    │  │  • Connection strings                                          │     │
    │  │  • Certificates                                                │     │
    │  └───────────────────────────────────────────────────────────────┘     │
    │                                                                          │
    └──────────────────────────────────────────────────────────────────────────┘

Benefits:
✅ Lowest cost: $15-20/month
✅ Fully managed (PaaS)
✅ Auto-scaling
✅ 99.95% SLA
✅ Built-in monitoring
✅ Easy deployment
✅ Modern .NET 8
```

### Data Flow - Option 1

```
1. Timer Trigger Execution:
   ┌─────────────────────┐
   │  Timer (Every Min)  │
   └──────────┬──────────┘
              │
              ▼
   ┌─────────────────────┐
   │  Azure Function     │
   │  Activates          │
   └──────────┬──────────┘
              │
              
2. API Call:
              │
              ▼
   ┌─────────────────────┐
   │  HTTP GET Request   │──────► https://app-messageservice.azurewebsites.net/api/message
   └──────────┬──────────┘
              │
              
3. API Processing:
              │
              ▼
   ┌─────────────────────┐
   │  App Service        │
   │  Processes Request  │
   │  - Generate msg     │
   │  - Add timestamp    │
   └──────────┬──────────┘
              │
              
4. Response:
              │
              ▼
   ┌─────────────────────┐
   │  JSON Response      │
   │  {                  │
   │    message: "...",  │
   │    timestamp: ...   │
   │  }                  │
   └──────────┬──────────┘
              │
              
5. Logging:
              │
              ▼
   ┌─────────────────────┐
   │  Function Logs      │──────► Application Insights
   │  to App Insights    │
   └──────────┬──────────┘
              │
              
6. Completion:
              │
              ▼
   ┌─────────────────────┐
   │  Function Completes │
   │  Waits for next min │
   └─────────────────────┘
```

---

## Option 2: Azure Container Apps

```
    ┌──────────────────────────────────────────────────────────────────┐
    │                         Azure Cloud                              │
    │                                                                  │
    │  ┌────────────────────────────────────────────────────────┐    │
    │  │  Azure Container Apps Environment                       │    │
    │  │                                                          │    │
    │  │  ┌────────────────────────────────────────────────┐    │    │
    │  │  │  Scheduled Job (CRON)                          │    │    │
    │  │  │  ┌──────────────────────────────────────────┐  │    │    │
    │  │  │  │  GreetingsConsole Container              │  │    │    │
    │  │  │  │  - Base Image: mcr.microsoft.com/       │  │    │    │
    │  │  │  │    dotnet/runtime:8.0                    │  │    │    │
    │  │  │  │  - Schedule: "*/1 * * * *"              │  │    │    │
    │  │  │  │  - Resource: 0.25 vCPU, 0.5 GB          │  │    │    │
    │  │  │  └──────────────────────────────────────────┘  │    │    │
    │  │  └────────────────┬───────────────────────────────┘    │    │
    │  │                   │ HTTPS GET                           │    │
    │  │                   │ /api/message                        │    │
    │  │                   ▼                                     │    │
    │  │  ┌────────────────────────────────────────────────┐    │    │
    │  │  │  MessageService Container App                   │    │    │
    │  │  │  ┌──────────────────────────────────────────┐  │    │    │
    │  │  │  │  .NET 8 API Container                    │  │    │    │
    │  │  │  │  - Base: mcr.microsoft.com/dotnet/       │  │    │    │
    │  │  │  │    aspnet:8.0                            │  │    │    │
    │  │  │  │  - Resource: 0.5 vCPU, 1 GB              │  │    │    │
    │  │  │  │  - Replicas: 1-10 (auto-scale)           │  │    │    │
    │  │  │  │  - Scale to zero: Yes                    │  │    │    │
    │  │  │  └──────────────────────────────────────────┘  │    │    │
    │  │  └────────────────────────────────────────────────┘    │    │
    │  └────────────────────────────────────────────────────────┘    │
    │                                                                  │
    │  ┌────────────────────────────────────────────────────────┐    │
    │  │  Azure Container Registry                               │    │
    │  │  - Stores container images                              │    │
    │  │  - Private registry                                     │    │
    │  │  - Geo-replication available                            │    │
    │  └────────────────────────────────────────────────────────┘    │
    │                                                                  │
    │  ┌────────────────────────────────────────────────────────┐    │
    │  │  Azure Log Analytics                                    │    │
    │  │  - Container logs                                       │    │
    │  │  - Metrics and monitoring                               │    │
    │  └────────────────────────────────────────────────────────┘    │
    │                                                                  │
    └──────────────────────────────────────────────────────────────────┘

Benefits:
✅ True cloud-native
✅ Microservices-ready
✅ Scale to zero
✅ Container portability
⚠️  Higher cost: $40-50/month
⚠️  More complex setup
```

---

## Option 3: Azure Virtual Machines (Lift-and-Shift)

```
    ┌──────────────────────────────────────────────────────────────────┐
    │                         Azure Cloud                              │
    │                                                                  │
    │  ┌────────────────────────────────────────────────────────┐    │
    │  │  Windows Server 2022 VM (B2s)                          │    │
    │  │  2 vCPU, 4 GB RAM                                      │    │
    │  │                                                          │    │
    │  │  ┌────────────────────────────────────────────────┐    │    │
    │  │  │  Windows Task Scheduler                        │    │    │
    │  │  │  ┌──────────────────────────────────────────┐  │    │    │
    │  │  │  │  GreetingsConsole.exe                    │  │    │    │
    │  │  │  │  - .NET Framework 4.8.1                  │  │    │    │
    │  │  │  │  - Scheduled Task (every minute)         │  │    │    │
    │  │  │  │  - No code changes                       │  │    │    │
    │  │  │  └──────────────────────────────────────────┘  │    │    │
    │  │  └────────────────┬───────────────────────────────┘    │    │
    │  │                   │ HTTP (localhost or internal)        │    │
    │  │                   ▼                                     │    │
    │  │  ┌────────────────────────────────────────────────┐    │    │
    │  │  │  IIS 10                                        │    │    │
    │  │  │  ┌──────────────────────────────────────────┐  │    │    │
    │  │  │  │  MessageService                          │  │    │    │
    │  │  │  │  - ASP.NET Web API 2                     │  │    │    │
    │  │  │  │  - .NET Framework 4.8.1                  │  │    │    │
    │  │  │  │  - No code changes                       │  │    │    │
    │  │  │  └──────────────────────────────────────────┘  │    │    │
    │  │  └────────────────────────────────────────────────┘    │    │
    │  │                                                          │    │
    │  │  Manual Setup Required:                                 │    │
    │  │  • Windows updates                                      │    │
    │  │  • IIS configuration                                    │    │
    │  │  • Task Scheduler setup                                 │    │
    │  │  • Security hardening                                   │    │
    │  │  • Backup configuration                                 │    │
    │  └────────────────────────────────────────────────────────┘    │
    │                                                                  │
    │  ┌────────────────────────────────────────────────────────┐    │
    │  │  Azure Load Balancer (Optional for HA)                 │    │
    │  │  - Distribute traffic across multiple VMs              │    │
    │  └────────────────────────────────────────────────────────┘    │
    │                                                                  │
    │  ┌────────────────────────────────────────────────────────┐    │
    │  │  Managed Disks                                          │    │
    │  │  - OS Disk (128 GB SSD)                                │    │
    │  │  - Backup snapshots                                    │    │
    │  └────────────────────────────────────────────────────────┘    │
    │                                                                  │
    └──────────────────────────────────────────────────────────────────┘

Drawbacks:
❌ Highest cost: $83-180/month
❌ High operational overhead
❌ Manual scaling
❌ No modernization
❌ Windows licensing costs
```

---

## Option 4: App Service + Logic Apps

```
    ┌──────────────────────────────────────────────────────────────────┐
    │                         Azure Cloud                              │
    │                                                                  │
    │  ┌────────────────────────────────────────────────────────┐    │
    │  │  Azure Logic Apps                                       │    │
    │  │  ┌────────────────────────────────────────────────┐    │    │
    │  │  │  Workflow: GreetingsWorkflow                   │    │    │
    │  │  │                                                 │    │    │
    │  │  │  ┌──────────────────────────────────────┐      │    │    │
    │  │  │  │  1. Recurrence Trigger               │      │    │    │
    │  │  │  │     Frequency: Minute                │      │    │    │
    │  │  │  │     Interval: 1                      │      │    │    │
    │  │  │  └───────────────┬──────────────────────┘      │    │    │
    │  │  │                  │                              │    │    │
    │  │  │  ┌───────────────▼──────────────────────┐      │    │    │
    │  │  │  │  2. HTTP Action                      │      │    │    │
    │  │  │  │     Method: GET                      │      │    │    │
    │  │  │  │     URI: MessageService/api/message  │      │    │    │
    │  │  │  └───────────────┬──────────────────────┘      │    │    │
    │  │  │                  │                              │    │    │
    │  │  │  ┌───────────────▼──────────────────────┐      │    │    │
    │  │  │  │  3. Parse JSON                       │      │    │    │
    │  │  │  │     Extract message and timestamp    │      │    │    │
    │  │  │  └───────────────┬──────────────────────┘      │    │    │
    │  │  │                  │                              │    │    │
    │  │  │  ┌───────────────▼──────────────────────┐      │    │    │
    │  │  │  │  4. Compose/Log                      │      │    │    │
    │  │  │  │     Send to Log Analytics            │      │    │    │
    │  │  │  └──────────────────────────────────────┘      │    │    │
    │  │  └────────────────────────────────────────────────┘    │    │
    │  └────────────────┬───────────────────────────────────────┘    │
    │                   │ HTTPS GET                                   │
    │                   │ /api/message                                │
    │                   ▼                                             │
    │  ┌────────────────────────────────────────────────────────┐    │
    │  │  Azure App Service (B1)                                 │    │
    │  │  ┌──────────────────────────────────────────────────┐  │    │
    │  │  │  MessageService API (.NET 8)                     │  │    │
    │  │  └──────────────────────────────────────────────────┘  │    │
    │  └────────────────────────────────────────────────────────┘    │
    │                                                                  │
    └──────────────────────────────────────────────────────────────────┘

Benefits:
✅ No code for scheduler
✅ Visual workflow designer
✅ Easy to modify schedule
⚠️  Limited processing capability
⚠️  Overkill for simple task
```

---

## Comparison Matrix

| Feature | Option 1 | Option 2 | Option 3 | Option 4 |
|---------|----------|----------|----------|----------|
| **Scheduled Task** | Azure Functions Timer | Container App Job | Task Scheduler | Logic Apps |
| **API Hosting** | App Service | Container App | IIS on VM | App Service |
| **Technology** | .NET 8 | .NET 8 + Docker | .NET Framework | .NET 8 + Low-Code |
| **Cost/Month** | $15-20 | $40-50 | $83-180 | $16-20 |
| **Complexity** | ⭐⭐ Medium | ⭐⭐⭐ High | ⭐ Low | ⭐⭐ Medium |
| **Scalability** | Auto | Auto + Scale-to-Zero | Manual | Auto (API only) |
| **Modernization** | ✅ High | ✅ High | ❌ None | ⚠️ Medium |
| **Operational** | ✅ Low | ⚠️ Medium | ❌ High | ✅ Low |

---

## Deployment Topology - Recommended (Option 1)

### Development Environment
```
┌────────────────────────────────────────┐
│  Resource Group: rg-greetings-dev      │
│                                        │
│  • App Service Plan: plan-dev (F1)    │
│  • App Service: app-msg-dev            │
│  • Function App: func-greet-dev        │
│  • App Insights: ai-dev                │
│  • Storage Account: stdev              │
│                                        │
│  Cost: ~$0-5/month                     │
└────────────────────────────────────────┘
```

### Production Environment
```
┌────────────────────────────────────────┐
│  Resource Group: rg-greetings-prod     │
│                                        │
│  • App Service Plan: plan-prod (B1)   │
│  • App Service: app-msg-prod           │
│    - Deployment Slots: prod, staging  │
│  • Function App: func-greet-prod       │
│  • App Insights: ai-prod               │
│  • Storage Account: stprod             │
│  • Key Vault: kv-prod (optional)       │
│                                        │
│  Cost: ~$15-20/month                   │
└────────────────────────────────────────┘
```

### High Availability (Optional)
```
┌────────────────────────────────────────────────────────────┐
│  Multi-Region Deployment                                   │
│                                                            │
│  Primary Region (East US)                                 │
│  • All resources as above                                 │
│                                                            │
│  Secondary Region (West US)                               │
│  • Standby replica (for DR)                              │
│                                                            │
│  Azure Front Door                                         │
│  • Global load balancing                                  │
│  • Automatic failover                                     │
│                                                            │
│  Cost: ~$80-100/month                                     │
└────────────────────────────────────────────────────────────┘
```

---

## Monitoring Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    Monitoring & Observability                     │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Application Insights                                   │     │
│  │                                                          │     │
│  │  Data Sources:                                          │     │
│  │  ├─ Function App telemetry                             │     │
│  │  ├─ App Service telemetry                              │     │
│  │  ├─ Custom events and metrics                          │     │
│  │  └─ Dependency tracking                                │     │
│  │                                                          │     │
│  │  Features:                                              │     │
│  │  • Live Metrics Stream                                  │     │
│  │  • Application Map                                      │     │
│  │  • Transaction Search                                   │     │
│  │  • Failures Analysis                                    │     │
│  │  • Performance Profiling                                │     │
│  └────────────────────────────────────────────────────────┘     │
│                             │                                     │
│                             ▼                                     │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Azure Monitor                                          │     │
│  │                                                          │     │
│  │  Alert Rules:                                           │     │
│  │  ├─ Function execution failures > 3                    │     │
│  │  ├─ API response time > 5 seconds                      │     │
│  │  ├─ HTTP 5xx errors > 10                               │     │
│  │  └─ Daily cost exceeds $5                              │     │
│  │                                                          │     │
│  │  Dashboards:                                            │     │
│  │  ├─ Function execution metrics                         │     │
│  │  ├─ API performance                                    │     │
│  │  └─ Cost tracking                                      │     │
│  └────────────────────────────────────────────────────────┘     │
│                             │                                     │
│                             ▼                                     │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Notifications                                          │     │
│  │  ├─ Email alerts                                       │     │
│  │  ├─ SMS (critical only)                                │     │
│  │  └─ Azure DevOps integration                           │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## CI/CD Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                      GitHub / Azure DevOps                        │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Source Code Repository                                 │     │
│  │  ├─ MessageService/                                    │     │
│  │  ├─ GreetingsFunction/                                 │     │
│  │  ├─ .github/workflows/                                 │     │
│  │  └─ azure/                                             │     │
│  └────────────────┬───────────────────────────────────────┘     │
│                   │ Push to main branch                          │
│                   ▼                                              │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  CI Pipeline (GitHub Actions / Azure Pipelines)        │     │
│  │                                                          │     │
│  │  Steps:                                                 │     │
│  │  1. Checkout code                                      │     │
│  │  2. Restore NuGet packages                             │     │
│  │  3. Build .NET projects                                │     │
│  │  4. Run unit tests                                     │     │
│  │  5. Run code analysis                                  │     │
│  │  6. Publish artifacts                                  │     │
│  └────────────────┬───────────────────────────────────────┘     │
│                   │ Build succeeded                              │
│                   ▼                                              │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  CD Pipeline                                            │     │
│  │                                                          │     │
│  │  Stages:                                                │     │
│  │  1. Deploy to Staging                                  │     │
│  │     ├─ Deploy App Service                              │     │
│  │     ├─ Deploy Function App                             │     │
│  │     └─ Run integration tests                           │     │
│  │                                                          │     │
│  │  2. Manual Approval Gate                               │     │
│  │                                                          │     │
│  │  3. Deploy to Production                               │     │
│  │     ├─ Deploy to staging slot                          │     │
│  │     ├─ Warm up slot                                    │     │
│  │     ├─ Swap slots                                      │     │
│  │     └─ Verify health checks                            │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Security Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                      Security Layers                              │
│                                                                   │
│  Layer 1: Network Security                                       │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  • Azure Front Door (DDoS protection)                  │     │
│  │  • Private endpoints (optional)                        │     │
│  │  • VNet integration (optional)                         │     │
│  │  • NSG rules                                           │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                   │
│  Layer 2: Identity & Access                                      │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  • Managed Identity for Function App                   │     │
│  │  • Azure AD authentication (optional)                  │     │
│  │  • RBAC for resource access                            │     │
│  │  • API keys rotation                                   │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                   │
│  Layer 3: Data Protection                                        │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  • TLS 1.2+ for all communications                     │     │
│  │  • Secrets in Key Vault                                │     │
│  │  • Encryption at rest                                  │     │
│  │  • Encryption in transit                               │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                   │
│  Layer 4: Monitoring & Compliance                                │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  • Azure Security Center                               │     │
│  │  • Audit logs                                          │     │
│  │  • Security alerts                                     │     │
│  │  • Compliance policies                                 │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

**Document Version**: 1.0  
**Last Updated**: November 5, 2025  
**Related**: See AZURE_MODERNIZATION_ASSESSMENT.md for detailed analysis
