using MessageServiceApi.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { 
        Title = "MessageService API", 
        Version = "v1",
        Description = "A modernized REST API that returns timestamped greeting messages"
    });
});

// Add CORS support for local development and Azure Functions
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "MessageService API v1");
    c.RoutePrefix = "swagger";
});

app.UseCors("AllowAll");

/// <summary>
/// GET endpoint that returns a "Hello World" message with the current date and time prepended.
/// </summary>
/// <returns>A MessageResponse object with timestamp</returns>
/// <response code="200">Returns the greeting message with timestamp</response>
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
.WithOpenApi()
.Produces<MessageResponse>(StatusCodes.Status200OK);

app.Run();
