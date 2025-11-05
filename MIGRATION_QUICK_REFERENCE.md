# Azure Migration Quick Reference Guide

**Quick decision guide for modernizing .NET Framework 4.8.1 application to Azure**

---

## 🎯 TL;DR - Recommended Solution

**Choose: Azure Functions + App Service (Option 1)** ⭐

- **Cost**: $15-20/month (85% savings)
- **Timeline**: 2-3 weeks
- **Effort**: Moderate code changes
- **Result**: Modern, scalable, cloud-native application

---

## 📊 Quick Comparison

| What | Current | After Migration (Option 1) |
|------|---------|---------------------------|
| **Platform** | Windows Server/IIS | Azure PaaS (Serverless) |
| **Framework** | .NET Framework 4.8.1 | .NET 8 |
| **API Hosting** | IIS | Azure App Service |
| **Scheduled Task** | Task Scheduler | Azure Functions |
| **Cost/Month** | ~$100-150 | ~$15-20 |
| **Scaling** | Manual | Automatic |
| **Patching** | Manual | Automatic |
| **Monitoring** | Manual setup | Built-in (App Insights) |
| **Deployment** | Manual/RDP | CI/CD Pipeline |

---

## 🚀 Migration Phases

### Phase 1: MessageService API (Week 1)
- [ ] Upgrade to .NET 8
- [ ] Convert to minimal API
- [ ] Deploy to Azure App Service
- [ ] Test and validate

### Phase 2: GreetingsConsole (Week 2)
- [ ] Create Azure Function project
- [ ] Add timer trigger (every minute)
- [ ] Migrate HTTP client logic
- [ ] Deploy and test

### Phase 3: Cutover (Week 3)
- [ ] Parallel run with old system
- [ ] Monitor for issues
- [ ] Complete migration
- [ ] Decommission old system

---

## 💰 Cost Breakdown (Recommended Solution)

| Service | Tier | Cost | Purpose |
|---------|------|------|---------|
| App Service | B1 Basic | $13/mo | Host API |
| Azure Functions | Consumption | $0.20/mo | Scheduled task |
| Application Insights | Pay-as-go | $2-5/mo | Monitoring |
| **Total Production** | | **$15-20/mo** | |
| **Total Dev/Test** | F1 Free | **$2-5/mo** | Use free tier |

### 💵 Savings
- **Before**: ~$100-150/month (Windows VM + operations)
- **After**: ~$15-20/month
- **Savings**: **~85%** ($85-135/month)

---

## ⚡ Key Azure Services

### Azure App Service (for API)
```
What: Managed web hosting platform
Why: No server management, auto-scaling, easy deployment
Cost: $0-13/month (F1 free tier or B1 basic)
SLA: 99.95%
```

### Azure Functions (for scheduled task)
```
What: Serverless compute service
Why: Pay-per-execution, perfect for scheduled tasks
Cost: $0.20/month (43,200 executions)
SLA: 99.95%
Trigger: Timer (CRON: "0 */1 * * * *")
```

### Application Insights (monitoring)
```
What: Application performance monitoring
Why: Centralized logging, metrics, alerts
Cost: $2-5/month (based on telemetry volume)
Features: Live metrics, distributed tracing, alerts
```

---

## 🔧 Technology Changes

### Before
```csharp
// .NET Framework 4.8.1, ASP.NET Web API 2
public class MessageController : ApiController
{
    [HttpGet]
    [Route("api/message")]
    public IHttpActionResult GetMessage()
    {
        var response = new MessageResponse { ... };
        return Ok(response);
    }
}
```

### After
```csharp
// .NET 8, Minimal API
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/api/message", () =>
{
    var response = new MessageResponse { ... };
    return Results.Ok(response);
});

app.Run();
```

---

## 📅 Timeline Estimate

### Fast Track (2 weeks)
- Experienced team
- Simple application
- Aggressive timeline
- Minimal testing

### Standard (3 weeks) ⭐ RECOMMENDED
- Normal pace
- Proper testing
- Documentation
- Team learning

### Conservative (4-6 weeks)
- Learning curve
- Extensive testing
- Multiple environments
- Proof of concept first

---

## ✅ Prerequisites Checklist

### Azure Setup
- [ ] Azure subscription (Free tier works)
- [ ] Resource group created
- [ ] Appropriate permissions (Contributor or Owner)

### Development Tools
- [ ] Visual Studio 2022 or VS Code
- [ ] .NET 8 SDK installed
- [ ] Azure Functions Core Tools
- [ ] Azure CLI (optional)

### Skills Needed
- [ ] C# development
- [ ] Basic Azure knowledge
- [ ] REST API concepts
- [ ] Git version control

---

## 🎓 Learning Resources

### Essential (Start Here)
1. [.NET Upgrade Assistant](https://dotnet.microsoft.com/platform/upgrade-assistant) - 30 min
2. [Azure Functions Quickstart](https://docs.microsoft.com/azure/azure-functions/) - 1 hour
3. [Azure App Service Tutorial](https://docs.microsoft.com/azure/app-service/) - 1 hour

### Recommended
4. [Application Insights Docs](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview) - 30 min
5. [Azure Cost Management](https://docs.microsoft.com/azure/cost-management-billing/) - 30 min

### Advanced
6. [CI/CD with GitHub Actions](https://docs.github.com/actions) - 2 hours
7. [Azure Architecture Best Practices](https://docs.microsoft.com/azure/architecture/) - 4 hours

---

## 🛠️ Essential CLI Commands

### Create Resources
```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-greetings-prod --location eastus

# Create App Service Plan
az appservice plan create --name plan-greetings \
  --resource-group rg-greetings-prod --sku B1

# Create Web App
az webapp create --name app-messageservice-prod \
  --resource-group rg-greetings-prod \
  --plan plan-greetings --runtime "DOTNET:8.0"

# Create Function App
az functionapp create --name func-greetings-prod \
  --resource-group rg-greetings-prod \
  --consumption-plan-location eastus \
  --runtime dotnet --runtime-version 8 \
  --functions-version 4
```

### Deploy
```bash
# Deploy Web App
dotnet publish -c Release
az webapp deployment source config-zip \
  --resource-group rg-greetings-prod \
  --name app-messageservice-prod \
  --src ./publish.zip

# Deploy Function App
func azure functionapp publish func-greetings-prod
```

### Monitor
```bash
# View logs
az webapp log tail --name app-messageservice-prod \
  --resource-group rg-greetings-prod

# View Function logs
func azure functionapp logstream func-greetings-prod
```

---

## 🐛 Common Issues & Solutions

### Issue: Cold Start Delays
**Problem**: First request after idle takes 2-5 seconds  
**Solution**: 
- Use Basic tier (always on) for API
- Consider Premium Plan for Functions if critical

### Issue: Configuration Not Working
**Problem**: App can't find settings  
**Solution**:
```bash
# Set app settings
az webapp config appsettings set \
  --name app-messageservice-prod \
  --resource-group rg-greetings-prod \
  --settings "Setting1=Value1"
```

### Issue: Function Not Triggering
**Problem**: Timer trigger not executing  
**Solution**:
- Check CRON expression syntax
- Verify Function App is running
- Check Application Insights for errors
- Restart Function App

### Issue: Can't Connect to API
**Problem**: Function can't reach App Service  
**Solution**:
- Use full URL with HTTPS
- Check CORS settings if needed
- Verify App Service is running
- Check firewall rules

---

## 📋 Pre-Migration Checklist

### Planning
- [ ] Stakeholder approval obtained
- [ ] Budget approved ($15-20/month)
- [ ] Timeline agreed (2-3 weeks)
- [ ] Team members assigned

### Technical
- [ ] Current application documented
- [ ] Dependencies identified
- [ ] Test plan created
- [ ] Rollback plan documented

### Azure Setup
- [ ] Azure subscription ready
- [ ] Resource naming convention defined
- [ ] Dev/staging/prod environments planned
- [ ] Access permissions configured

---

## 🎯 Success Criteria

### Functional
- ✅ API returns correct responses
- ✅ Timer function executes every minute
- ✅ No data loss or errors
- ✅ All features work as before

### Performance
- ✅ API response time < 200ms (p95)
- ✅ Function execution time < 1 second
- ✅ 99.9% uptime achieved

### Cost
- ✅ Monthly cost < $25
- ✅ 70-85% cost reduction achieved

### Operational
- ✅ No manual patching required
- ✅ Automatic scaling working
- ✅ Monitoring and alerts configured
- ✅ CI/CD pipeline operational

---

## 🚨 Red Flags (When NOT to Migrate)

### Don't Migrate If...
❌ Application uses Windows-specific APIs that can't be replaced  
❌ Third-party dependencies not compatible with .NET 8  
❌ No budget for migration effort (2-3 weeks dev time)  
❌ Team has zero Azure or .NET Core experience  
❌ Application will be decommissioned within 6 months  

### Consider Lift-and-Shift (Option 3) If...
⚠️ Need to migrate in < 1 week (emergency)  
⚠️ Can't modify code due to constraints  
⚠️ Have unsupported dependencies  

*Note: Lift-and-shift provides no cost savings or modernization benefits*

---

## 📞 Getting Help

### Azure Support
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Azure Support Plans](https://azure.microsoft.com/support/plans/)
- [Azure Community](https://techcommunity.microsoft.com/t5/azure/ct-p/Azure)

### .NET Migration
- [.NET Upgrade Assistant](https://dotnet.microsoft.com/platform/upgrade-assistant)
- [.NET Migration Guide](https://docs.microsoft.com/dotnet/core/porting/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/azure)

### Cost Management
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure Cost Management](https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/overview)
- [Cost optimization tips](https://docs.microsoft.com/azure/cost-management-billing/costs/)

---

## 📝 Next Steps

1. **Read Full Assessment**: [AZURE_MODERNIZATION_ASSESSMENT.md](./AZURE_MODERNIZATION_ASSESSMENT.md)
2. **Review Architecture**: [ARCHITECTURE_DIAGRAMS.md](./ARCHITECTURE_DIAGRAMS.md)
3. **Get Approval**: Present to stakeholders
4. **Start Migration**: Follow Phase 1 in the assessment
5. **Monitor Progress**: Use Application Insights

---

## 🎉 Post-Migration Benefits

### Immediate Benefits
- ✅ 85% cost reduction
- ✅ No Windows updates/patching
- ✅ Automatic scaling
- ✅ Built-in monitoring

### Long-term Benefits
- ✅ Modern .NET 8 platform
- ✅ Cloud-native architecture
- ✅ Easy to add new features
- ✅ Better DevOps integration
- ✅ Improved team productivity

### Strategic Benefits
- ✅ Platform for future growth
- ✅ Skills development (Azure, .NET 8)
- ✅ Competitive advantage
- ✅ Innovation enablement

---

## 🔗 Related Documents

- **[AZURE_MODERNIZATION_ASSESSMENT.md](./AZURE_MODERNIZATION_ASSESSMENT.md)** - Full detailed analysis
- **[ARCHITECTURE_DIAGRAMS.md](./ARCHITECTURE_DIAGRAMS.md)** - Visual architecture diagrams
- **[Migration README](./Migration/README.md)** - Workshop guide

---

**Quick Reference Version**: 1.0  
**Last Updated**: November 5, 2025  
**Maintained By**: GitHub Copilot

---

## 📊 Decision Matrix

Use this to make a quick decision:

| Your Situation | Recommended Option |
|----------------|-------------------|
| Budget conscious, simple app | **Option 1: Functions + App Service** ⭐ |
| Planning microservices, have Docker skills | Option 2: Container Apps |
| Emergency (<1 week), can't change code | Option 3: VMs (Lift-and-shift) |
| Need workflow integration | Option 4: Logic Apps |
| Default recommendation | **Option 1: Functions + App Service** ⭐ |

**95% of scenarios should choose Option 1**
