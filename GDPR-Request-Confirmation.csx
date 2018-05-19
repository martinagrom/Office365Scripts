// Trigger a logic app with an Azure Function and convert query parameter "mailcode" to a body value.
// atwork.at, May 11, 2018, Christoph Wilfing, Toni Pohl, Martina Grom
// Original code from (adapted)
// https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-scenario-function-sb-trigger

#r "Newtonsoft.Json"
using System;
using System.Net;
using System.Threading.Tasks;
using System.Net.Http;
using System.Text;
using Newtonsoft.Json.Linq;

// Endpoint of the Logic App
private static string logicAppUri = @"https://prod-29.westus2.logic.azure.com:443/workflows/someurl...";

public static async Task<HttpResponseMessage> Run(HttpRequestMessage req, TraceWriter log)
{
    log.Info($"Azure Function started: {req}");

    // parse query parameter
    string MailCode = req.GetQueryNameValuePairs()
        .FirstOrDefault(q => string.Compare(q.Key, "MailCode", true) == 0)
        .Value;

    // generate the body as valid JSON - Use this for schema generation in the Logic App as well
    HttpResponseMessage response = null;
    string theBody = "{\"MailCode\":\""+MailCode+"\"}";
    log.Info($"theBody: {theBody}");
    
    // Await the HTTP call
    JObject jsonResult;
    using (var client = new HttpClient())
    {
        response = await client.PostAsync(logicAppUri, new StringContent(theBody, Encoding.UTF8, "application/json"));
        jsonResult = JObject.Parse(await response.Content.ReadAsStringAsync());
    }

    // We're done here
    //return req.CreateResponse(HttpStatusCode.OK, "Azure Function ended: " + response);
    var resp = req.CreateResponse(HttpStatusCode.OK);
    resp.Content = new StringContent(jsonResult.Value<string>("html"), Encoding.UTF8, "text/html");
    return resp;

    /*var resp = req.CreateResponse(HttpStatusCode.Moved);
    resp.Headers.Location = new Uri("http://www.atwork-it.com");
    return resp;*/
}
