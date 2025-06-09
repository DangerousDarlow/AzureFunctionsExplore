using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.WebJobs.Extensions.OpenApi.Core.Attributes;
using Microsoft.Extensions.Logging;

namespace AzureFunctionsExplore;

public class Math(ILogger<Math> logger)
{
    [Function("Double")]
    [OpenApiOperation("Double")]
    [OpenApiRequestBody("application/json", typeof(Body), Required = true)]
    [OpenApiResponseWithBody(HttpStatusCode.OK, "'application/json'", typeof(Body))]
    public async Task<IActionResult> Double([HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequest request)
    {
        var requestBodyString = await new StreamReader(request.Body).ReadToEndAsync();
        var requestBody = JsonSerializer.Deserialize<Body>(requestBodyString);
        logger.LogInformation("Doubling number: {number}", requestBody?.Double);
        return new OkObjectResult(new Body (requestBody?.Double * 2 ?? 0 ));
    }

    public record Body(int Double);
}