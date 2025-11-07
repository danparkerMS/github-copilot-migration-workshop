namespace GreetingsFunction.Models;

/// <summary>
/// Response model matching the MessageService API response
/// </summary>
public class MessageResponse
{
    /// <summary>
    /// The formatted message string with timestamp
    /// </summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// The timestamp when the message was generated
    /// </summary>
    public DateTime Timestamp { get; set; }
}
