// ProvisionGroup-CSharp-Azure-Function
// Original Source:
// https://contos.io/working-with-identity-in-an-azure-function-1a981e10b900
// https://gist.github.com/ahelland/03c1ec02a2305373d4dee5ee3985ed80
// https://developer.microsoft.com/en-us/graph/docs/api-reference/v1.0/api/group_post_groups
// modified by Toni Pohl, Martina Grom
// include/reference external assemblies in a .csx file
#r "Newtonsoft.Json"
#r "System.Configuration"
#r "System.Collections"
#r "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
// The .dll we refer to needs to be included/uploaded to your Function’s disk. To do this you need to open the Kudu debug console (replace functions-xyz with your Functions App name):
// https://myfunction.scm.azurewebsites.net/DebugConsole/?shell=powershell
using System;
using System.Net;
using System.Text;
using System.Configuration;
using System.Collections.Generic;
using System.Security.Claims; 
using System.Net.Http.Headers;
using Newtonsoft.Json;
using Microsoft.IdentityModel.Clients.ActiveDirectory;


public static async Task<HttpResponseMessage> Run(HttpRequestMessage req, TraceWriter log)
{
    log.Info("C# HTTP trigger function processed a request.");

    // parse query parameter
    string name = req.GetQueryNameValuePairs()
        .FirstOrDefault(q => string.Compare(q.Key, "name", true) == 0)
        .Value;

    string upn = req.GetQueryNameValuePairs()
        .FirstOrDefault(q => string.Compare(q.Key, "upn", true) == 0)
        .Value;

    // Get request body
    dynamic data = await req.Content.ReadAsAsync<object>();

    // Set name to query string or body data
    name = name ?? data?.name;
    upn = upn ?? data?.upn;


    // The resourceId variable is the resource we want to access once we have a token
    // You can get a token issued even if you change the resource, but when you try to access said resource it will throw an error back at you.
    string resourceId = "https://graph.microsoft.com";
    string tenantId = "<your-tenant-id>";
    string clientId = "<your-client-id>";
    string clientSecret = "<your-secret-id>";
    string authString = "https://login.microsoftonline.com/"+tenantId;
	  string GroupId = "";
    string UserId = "";
   

    // 2. Acquiring a token that the server can use to do lookups. (We are using the client credentials flow for OAuth. Which should only be used in a back-end context; not in a mobile app.)
    log.Verbose("client credentials flow for OAuth: " + authString);
    // This follows the Client Credential flow for OAuth, and this is a silent flow for the user.
    var authenticationContext = new AuthenticationContext(authString, false);

    // Config for OAuth client credentials 
    log.Verbose("clientId: " + clientId);
    log.Verbose("clientSecret: " + clientSecret);
    
    ClientCredential clientCred = new ClientCredential(clientId, clientSecret);
    AuthenticationResult authenticationResult = await authenticationContext.AcquireTokenAsync(resourceId,clientCred);

    string token = authenticationResult.AccessToken;
    log.Verbose("token: " + token.ToString().Substring(0,10) + "...");

    var outputName = String.Empty;
    var responseString = String.Empty;
    var phone = String.Empty;
    var result = String.Empty;

    HttpResponseMessage response;
    OperationResult op = new OperationResult();
    OperationResult opUser = new OperationResult();
    OperationResult opOwner = new OperationResult();
    OperationResult opMember = new OperationResult();
    op.Message = "undefined.";
    opUser.Message = "undefined.";
    opOwner.Message = "undefined.";
    opMember.Message = "undefined.";

    // Call the Microsoft Graph to post data.
    // https://developer.microsoft.com/en-us/graph/docs/api-reference/v1.0/api/group_post_groups
    using (var client = new HttpClient())
    {        
        // v1.0/me/sendMail
        string requestUrl = $"https://graph.microsoft.com/v1.0/groups";
        log.Verbose("requestUrl: " + requestUrl);
        
        HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, requestUrl);
        //HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        string groupname = name; // + DateTime.Now.ToString("hhmmss");

        string json = $"{{ \"description\": \"{groupname}\", \"displayName\": \"{groupname}\", \"groupTypes\": [ \"Unified\" ], \"mailEnabled\": true, \"mailNickname\": \"{groupname}\", \"securityEnabled\": false }}";

        var content = new StringContent(json, Encoding.UTF8, "application/json");        
        request.Content = content;
        log.Verbose(request.ToString().Substring(0,100) + "...");

        response = client.SendAsync(request).Result;
        responseString = response.Content.ReadAsStringAsync().Result;

        if (response.StatusCode==HttpStatusCode.OK || response.StatusCode == HttpStatusCode.Created)
        {
            var groupResult = JsonConvert.DeserializeObject<GroupResult>(responseString);
            GroupId = groupResult.Id;
            op.Message = GroupId;
            op.Subject = $"{name} successfully created.";
        }
        else
        {
            op.Message = $"{name} could not be created. check the error: {responseString}";
            op.Subject = $"{name} could not be created.";
        }        

        op.Success = response.StatusCode == HttpStatusCode.OK || response.StatusCode == HttpStatusCode.Created;
    }

    // Lookup the user by his UPN - we need his ID
    using (var client = new HttpClient())
    {        
        // v1.0/me/sendMail
        string requestUrl = $"https://graph.microsoft.com/v1.0/users/" + upn;
        log.Verbose("requestUrlUser: " + requestUrl);
        
        HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Get, requestUrl);
  
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        response = client.SendAsync(request).Result;
        responseString = response.Content.ReadAsStringAsync().Result;

        if (response.StatusCode==HttpStatusCode.OK || response.StatusCode == HttpStatusCode.Created)
        {
            var userResult = JsonConvert.DeserializeObject<UserResult>(responseString);
            UserId = userResult.Id;
            opUser.Message = UserId;
            opUser.Subject = $"{upn} successfully find.";
        }
        else
        {
            opUser.Message = $"{upn} could not be find. check the error: {responseString}";
            opUser.Subject = $"{upn} could not be find.";
        }        

        opUser.Success = response.StatusCode == HttpStatusCode.OK || response.StatusCode == HttpStatusCode.Created;
    }  

    // add owner
    // https://developer.microsoft.com/en-us/graph/docs/api-reference/v1.0/api/group_post_owners
    using (var client = new HttpClient())
    {        
        // v1.0/me/sendMail
        string requestUrl = $"https://graph.microsoft.com/v1.0/groups/{GroupId}/owners/$ref";
        
        HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, requestUrl);
     
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var ownerUrl = "https://graph.microsoft.com/v1.0/users/" + UserId;

        string json = $"{{ \"@odata.id\": \"{ownerUrl}\" }}";

        var content = new StringContent(json, Encoding.UTF8, "application/json");        
        request.Content = content;
        response = client.SendAsync(request).Result;
        // HTTP Status Code 204: The server has successfully fulfilled the request and that there is no additional content to send in the response payload body.
        // responseString = response.Content.ReadAsStringAsync().Result;
        if ((int)response.StatusCode==204)
        {
            opOwner.Message = "OK";
        }
        else
        {
            opOwner.Message = "HTTP error 400 or 404 or 500";
        }
    }


    // add member
    // https://developer.microsoft.com/en-us/graph/docs/api-reference/v1.0/api/group_post_members
    using (var client = new HttpClient())
    {        
        string requestUrl = $"https://graph.microsoft.com/v1.0/groups/{GroupId}/members/$ref";
        
        HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, requestUrl);
     
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        var memberUrl = "https://graph.microsoft.com/v1.0/users/" + UserId;

        string json = $"{{ \"@odata.id\": \"{memberUrl}\" }}";

        var content = new StringContent(json, Encoding.UTF8, "application/json");        
        request.Content = content;
        response = client.SendAsync(request).Result;
        // HTTP Status Code 204: The server has successfully fulfilled the request and that there is no additional content to send in the response payload body.
        // responseString = response.Content.ReadAsStringAsync().Result;
        if ((int)response.StatusCode==204)
        {
            opMember.Message = "OK";
        }
        else
        {
            opMember.Message = "HTTP error 400 or 404 or 500";
        }
    }

    log.Verbose("msg group: " + op.Message);
    log.Verbose("msg user: " + opUser.Message);
    log.Verbose("msg owner: " + opOwner.Message);
    log.Verbose("msg member: " + opMember.Message);

    // we always deliver HTTP OK to continue
    return req.CreateResponse(HttpStatusCode.OK, op);
}

public class UserResult
    {
        [JsonProperty("givenName")]
        public string GivenName { get; set; }

        [JsonProperty("mobilePhone")]
        public string MobilePhone { get; set; }

        [JsonProperty("businessPhones")]
        public string[] BusinessPhones { get; set; }

        [JsonProperty("@odata.context")]
        public string OdataContext { get; set; }

        [JsonProperty("displayName")]
        public string DisplayName { get; set; }

        [JsonProperty("jobTitle")]
        public object JobTitle { get; set; }

        [JsonProperty("id")]
        public string Id { get; set; }

        [JsonProperty("mail")]
        public string Mail { get; set; }

        [JsonProperty("preferredLanguage")]
        public string PreferredLanguage { get; set; }

        [JsonProperty("officeLocation")]
        public object OfficeLocation { get; set; }

        [JsonProperty("surname")]
        public string Surname { get; set; }

        [JsonProperty("userPrincipalName")]
        public string UserPrincipalName { get; set; }
}

public class GroupResult
    {
        [JsonProperty("id")]
        public string Id { get; set; }

        [JsonProperty("deletedDateTime")]
        public object DeletedDateTime { get; set; }

        [JsonProperty("classification")]
        public object Classification { get; set; }

        [JsonProperty("@odata.context")]
        public string OdataContext { get; set; }

        [JsonProperty("createdDateTime")]
        public string CreatedDateTime { get; set; }

        [JsonProperty("displayName")]
        public string DisplayName { get; set; }

        [JsonProperty("description")]
        public string Description { get; set; }

        [JsonProperty("groupTypes")]
        public string[] GroupTypes { get; set; }

        [JsonProperty("onPremisesLastSyncDateTime")]
        public object OnPremisesLastSyncDateTime { get; set; }

        [JsonProperty("proxyAddresses")]
        public string[] ProxyAddresses { get; set; }

        [JsonProperty("mailEnabled")]
        public bool MailEnabled { get; set; }

        [JsonProperty("mail")]
        public string Mail { get; set; }

        [JsonProperty("mailNickname")]
        public string MailNickname { get; set; }

        [JsonProperty("onPremisesSecurityIdentifier")]
        public object OnPremisesSecurityIdentifier { get; set; }

        [JsonProperty("onPremisesProvisioningErrors")]
        public object[] OnPremisesProvisioningErrors { get; set; }

        [JsonProperty("onPremisesSyncEnabled")]
        public object OnPremisesSyncEnabled { get; set; }

        [JsonProperty("securityEnabled")]
        public bool SecurityEnabled { get; set; }

        [JsonProperty("renewedDateTime")]
        public string RenewedDateTime { get; set; }

        [JsonProperty("visibility")]
        public string Visibility { get; set; }
}

public class OperationResult
{
    public string Message { get; set; }
    public bool Success { get; set; }
    public string Subject { get; set; }
}
