<#
----------------------------------------------------
get-unifiedgroups.ps1
Script by atwork.at, Martina Grom, v1, 2016-08-02
This scripts reads all groups of an Office 365 tenant
and outputs the details inclusive used storage into a CSV file for further use (with Excel).
For details about unified groups and limits see:
https://blogs.msdn.microsoft.com/tomvan/2015/08/12/office-365-groups-introduction-frequently-asked-questions/

!! First, run get-unifiedgroups-connect.ps1 !!
----------------------------------------------------
#>
# Specifies the location where the result files shall be saved
$ResultFile = '.\get-unifiedgroups.csv'
#----------------------------------------------------

# Get all Office 365 groups of the tenant: $groups = Get-UnifiedGroup
# But we need only specific properties including the lookup of the manager done by the Cmdlet itself.
$groups = Get-UnifiedGroup -ResultSize Unlimited | Select-Object Name,Alias,PrimarySmtpAddress,AccessType,SharePointSiteUrl,SharePointDocumentsUrl,@{n='Manager';e={$(get-recipient -Identity $($_.managedby[0])).primarysmtpaddress} }

# use my own structure for combining the result
Class line
{
    [String]$Number
    [String]$Name
    [String]$PrimarySmtpAddress
    [String]$AccessType
    [String]$Manager
    [String]$SharePointSiteUrl
    [String]$SharePointDocumentsUrl
    [String]$StorageQuota
    [String]$StorageUsageCurrent
    [String]$WebsCount
    [String]$LastContentModifiedDate
}

# add each group to the result
Write-Output "Running..."
$all=@()
$i=0
Foreach ($group in $groups) { 
    $i ++
    Write-Output "$($i). $($group.Alias)"

    # properties we always have...
    $c = New-Object line
    $c.Number = $i
    $c.Name = $group.Alias
    $c.PrimarySmtpAddress = $group.PrimarySmtpAddress
    $c.AccessType= $group.AccessType
    $c.Manager = $group.Manager
    $c.SharePointSiteUrl = 'not provisioned'

    # add and overwrite following data only, if a SharePoint Site is provisioned for this group.
    if ($group.SharePointSiteUrl -ne $null) {

        $SPOSite = (Get-SPOSite -Identity $group.SharePointSiteUrl)

        $c.SharePointSiteUrl = $group.SharePointSiteUrl
        $c.SharePointDocumentsUrl = $group.SharePointDocumentsUrl
        $c.StorageQuota = $SPOSite.StorageQuota
        $c.StorageUsageCurrent = $SPOSite.StorageUsageCurrent
        $c.LastContentModifiedDate = $SPOSite.LastContentModifiedDate
        $c.WebsCount = $SPOSite.WebsCount
    }

    $all += $c
}

# Delete the $ResultFile if existing and output
if (Test-Path $ResultFile) {
    Remove-Item -Path $ResultFile -Force
}
Write-Output $all | Export-Csv -Path $ResultFile -NoClobber -NoTypeInformation -Encoding UTF8 -Force -Delimiter ','

Write-Output "Done. $($groups.Count) groups. Details saved to $($ResultFile)"
# end of script.
