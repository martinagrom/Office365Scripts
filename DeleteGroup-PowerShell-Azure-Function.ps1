# DeleteGroup.ps1
# deletes an existing Office 365 group, by atwork.at, Toni Pohl, Martina Grom
# POST with body:
# { 
# "GroupName" : "My Test 20"
# }

$requestBody = Get-Content $req -Raw | ConvertFrom-Json
$GroupName = $requestBody.GroupName

Write-Output "TenantID: $env:TenantID AppID: $env:AppID AppSecret: $env:AppSecret"
Write-Output "GroupName to delete: $GroupName"

function Initialize-Authorization {
    param
    (
      [string]
      $ResourceURL = 'https://graph.microsoft.com',
  
      [string]
      [parameter(Mandatory)]
      $TenantID,
      
      [string]
      [Parameter(Mandatory)]
      $ClientKey,
  
      [string]
      [Parameter(Mandatory)]
      $AppID
    )

    $Authority = "https://login.windows.net/$TenantID/oauth2/token"

    [Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
    $EncodedKey = [System.Web.HttpUtility]::UrlEncode($ClientKey)

    $body = "grant_type=client_credentials&client_id=$AppID&client_secret=$EncodedKey&resource=$ResourceUrl"

    # Request a Token from the graph api
    $result = Invoke-RestMethod -Method Post `
                        -Uri $Authority `
                        -ContentType 'application/x-www-form-urlencoded' `
                        -Body $body

    $script:APIHeader = @{'Authorization' = "Bearer $($result.access_token)" }
}


# Initialize Authorization
Initialize-Authorization -TenantID $env:TenantID -ClientKey $env:AppSecret -AppID $env:AppID
Write-Output "Initialize-Authorization..."

# Delete the Office 365 group
$uri = @"
https://graph.microsoft.com/v1.0/groups?`$select=id&`$filter=startswith(displayname,'$($GroupName)')
"@

try {
    $result = Invoke-RestMethod -Method GET `
                            -Uri $uri `
                            -ContentType 'application/json' `
                            -Headers $script:APIHeader `
                            -ErrorAction Stop

    # and get the Group ID
    $GroupID = $result.value.id
    Write-Output "GroupID: $GroupID"
} catch {
    Write-Output "ERROR! $_"
}

if ($GroupID) {
    $theresult = "DELETED: $GroupName, $GroupID found and deleted"    
    try {
    $result = Invoke-RestMethod -Method DELETE `
                                -Uri "https://graph.microsoft.com/v1.0/groups/$GroupID" `
                                -ContentType 'application/json' `
                                -Headers $script:APIHeader `
                                -ErrorAction Stop
        # last operation
        Write-Output "GroupID: $result"
    } catch {
        Write-Output "ERROR! $_"
    }
}
else
{
    $theresult = "NOTFOUND: $GroupName not found"
}

Out-File -Encoding Ascii -FilePath $res -inputObject $theresult
Write-Output $theresult 
