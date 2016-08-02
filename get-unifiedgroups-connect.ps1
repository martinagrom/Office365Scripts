<#
-----------------------------------------------------------------
get-unifiedgroups-connect.ps1
Script by atwork.at, Martina Grom, v1, 2016-08-02
This script opens a connection to Office 365, Exchange Online & SPO
prerequesits (restart required after install of SharePointOnlineManagementShell)
https://technet.microsoft.com/library/fp161372(v=office.15).aspx
-----------------------------------------------------------------
#>
# Specifies the User account for an Office 365 global admin in your organization
$AdminAccount = '<ADMINISTRATORACCOUNT>@<TENANTNAME>.onmicrosoft.com'
$AdminPass = '<YOURPASSWORD>'
# Specifies the URL for your organization's SPO admin service
$AdminURI = "https://<TENANTNAME>-admin.sharepoint.com"
#----------------------------------------------------------------

# with user interaction: # $cred = Get-Credential
$encryptedPassword = ConvertTo-SecureString $AdminPass -asplaintext -force
$encryptedPasswordString = ConvertFrom-SecureString -secureString $encryptedPassword
$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $AdminAccount, $encryptedPassword

# remote exchange-not here because of latency
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic –AllowRedirection
Import-PSSession $Session –AllowClobber
Write-Output "ready for Exchange Online!"

# use SPO management shell
Connect-SPOService -url $AdminURI -Credential $cred

Write-Host "done."
