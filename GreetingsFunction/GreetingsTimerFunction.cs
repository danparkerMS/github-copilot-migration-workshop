using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using GreetingsFunction.Models;

namespace GreetingsFunction;

/// <summary>
/// Azure Function with Timer Trigger that calls the MessageService API every minute
/// </summary>
public class GreetingsTimerFunction
{
    private readonly ILogger<GreetingsTimerFunction> _logger;
    private readonly HttpClient _httpClient;

    /// <summary>
    /// Constructor with dependency injection
    /// </summary>
    public GreetingsTimerFunction(ILogger<GreetingsTimerFunction> logger, IHttpClientFactory httpClientFactory)
    {
        _logger = logger;
        _httpClient = httpClientFactory.CreateClient();
    }

    /// <summary>
    /// Timer trigger function that runs every minute (0 */1 * * * *)
    /// The schedule uses CRON expression: second minute hour day month weekday
    /// "0 */1 * * * *" means: at second 0 of every minute
    /// </summary>
    [Function("GreetingsTimerFunction")]
    public async Task Run([TimerTrigger("0 */1 * * * *")] TimerInfo myTimer)
    {
        _logger.LogInformation("=== GreetingsFunction Timer Trigger Started ===");
        _logger.LogInformation($"Execution Time: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC");
        
        if (myTimer.ScheduleStatus is not null)
        {
            _logger.LogInformation($"Next timer schedule at: {myTimer.ScheduleStatus.Next:yyyy-MM-dd HH:mm:ss} UTC");
        }

        try
        {
            // Get the MessageService API URL from environment variable or use default
            var messageServiceUrl = Environment.GetEnvironmentVariable("MESSAGE_SERVICE_URL") 
                                    ?? "http://localhost:5000";
            
            var apiEndpoint = $"{messageServiceUrl}/api/message";
            
            _logger.LogInformation($"Calling MessageService API at: {apiEndpoint}");

            // Call the MessageService API
            var response = await _httpClient.GetAsync(apiEndpoint);

            if (response.IsSuccessStatusCode)
            {
                var jsonContent = await response.Content.ReadAsStringAsync();
                var messageResponse = JsonSerializer.Deserialize<MessageResponse>(jsonContent, 
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                if (messageResponse != null)
                {
                    _logger.LogInformation("=== Response Received ===");
                    _logger.LogInformation($"Message: {messageResponse.Message}");
                    _logger.LogInformation($"Timestamp: {messageResponse.Timestamp:yyyy-MM-dd HH:mm:ss}");
                }
                else
                {
                    _logger.LogWarning("Received empty response from the MessageService API");
                }
            }
            else
            {
                _logger.LogError($"Error: Received status code {response.StatusCode} from MessageService API");
            }
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Unable to connect to MessageService API");
            _logger.LogError($"Error details: {ex.Message}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error occurred");
            _logger.LogError($"Error details: {ex.Message}");
        }

        _logger.LogInformation("=== GreetingsFunction Timer Trigger Completed ===");
    }
}
